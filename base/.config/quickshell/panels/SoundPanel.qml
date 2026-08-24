import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "sound"
    panelWidth: 320
    contentSpacing: 8

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var source: Pipewire.defaultAudioSource
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var sources: Pipewire.nodes.values.filter(n => n.type === PwNodeType.AudioSource)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream)

    PwObjectTracker {
        objects: root.sinks.concat(root.streams).concat(root.sources)
    }

    function label(n) {
        return n.nickname || n.description || n.name
    }

    function appLabel(n) {
        return (n.properties && n.properties["application.name"]) || label(n)
    }

    // output
    Item {
        width: parent.width
        height: 16

        BarText {
            text: "Output"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.overlay1
        }
        MouseArea {
            id: mixerBtn
            width: 20
            height: parent.height
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: {
                root.close()
                Quickshell.execDetached(["pavucontrol"])
            }
            BarText {
                anchors.centerIn: parent
                text: ""
                font.pixelSize: Theme.fontSize
                color: mixerBtn.containsMouse ? Theme.mauve : Theme.overlay1
            }
        }
    }

    Row {
        width: parent.width
        spacing: 10

        MouseArea {
            id: muteBtn
            width: 24
            height: 20
            hoverEnabled: true
            onClicked: {
                if (root.sink?.audio)
                    root.sink.audio.muted = !root.sink.audio.muted
            }
            BarText {
                anchors.centerIn: parent
                text: root.sink?.audio?.muted ? "󰝟" : "󰕾"
                color: root.sink?.audio?.muted ? Theme.red
                     : muteBtn.containsMouse ? Theme.mauve : Theme.text
            }
        }

        VolSlider {
            width: parent.width - 24 - 40 - 20
            value: root.sink?.audio?.volume ?? 0
            onMoved: v => {
                if (root.sink?.audio)
                    root.sink.audio.volume = v
            }
        }

        BarText {
            width: 40
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round((root.sink?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.subtext0
        }
    }

    // devices
    BarText {
        visible: root.sinks.length > 1
        text: "Devices"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    Repeater {
        model: root.sinks.length > 1 ? root.sinks : []

        MouseArea {
            id: devRow
            required property var modelData

            readonly property bool isDefault: modelData === root.sink

            width: parent.width
            height: 24
            hoverEnabled: true
            onClicked: Pipewire.preferredDefaultAudioSink = modelData

            Rectangle {
                anchors.fill: parent
                color: devRow.containsMouse ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
                width: parent.width - 8
                elide: Text.ElideRight
                text: (devRow.isDefault ? "● " : "○ ") + root.label(devRow.modelData)
                color: devRow.isDefault ? Theme.mauve : Theme.text
            }
        }
    }

    // input
    BarText {
        visible: root.sources.length > 0
        text: "Input"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    Row {
        visible: root.sources.length > 0
        width: parent.width
        spacing: 10

        MouseArea {
            id: micMuteBtn
            width: 24
            height: 20
            hoverEnabled: true
            onClicked: {
                if (root.source?.audio)
                    root.source.audio.muted = !root.source.audio.muted
            }
            BarText {
                anchors.centerIn: parent
                text: root.source?.audio?.muted ? "󰍭" : "󰍬"
                color: root.source?.audio?.muted ? Theme.red
                     : micMuteBtn.containsMouse ? Theme.mauve : Theme.text
            }
        }

        VolSlider {
            width: parent.width - 24 - 40 - 20
            value: root.source?.audio?.volume ?? 0
            onMoved: v => {
                if (root.source?.audio)
                    root.source.audio.volume = v
            }
        }

        BarText {
            width: 40
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            text: Math.round((root.source?.audio?.volume ?? 0) * 100) + "%"
            color: Theme.subtext0
        }
    }

    // live mic level; only monitors while the panel is open
    Item {
        visible: root.sources.length > 0
        width: parent.width
        height: 4

        PwNodePeakMonitor {
            id: micPeak
            node: root.source
            enabled: root.visible
        }

        Rectangle {
            x: 34
            width: parent.width - 34 - 50
            height: 3
            anchors.verticalCenter: parent.verticalCenter
            color: Theme.surface1

            Rectangle {
                readonly property real lvl: Math.max(0, Math.min(1, micPeak.peak))
                width: parent.width * lvl
                height: parent.height
                color: lvl > 0.85 ? Theme.red : lvl > 0.6 ? Theme.yellow : Theme.green

                Behavior on width {
                    NumberAnimation { duration: 50 }
                }
            }
        }
    }

    Repeater {
        model: root.sources.length > 1 ? root.sources : []

        MouseArea {
            id: srcRow
            required property var modelData

            readonly property bool isDefault: modelData === root.source

            width: parent.width
            height: 24
            hoverEnabled: true
            onClicked: Pipewire.preferredDefaultAudioSource = modelData

            Rectangle {
                anchors.fill: parent
                color: srcRow.containsMouse ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
                width: parent.width - 8
                elide: Text.ElideRight
                text: (srcRow.isDefault ? "● " : "○ ") + root.label(srcRow.modelData)
                color: srcRow.isDefault ? Theme.mauve : Theme.text
            }
        }
    }

    // per-app streams
    BarText {
        visible: root.streams.length > 0
        text: "Apps"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    Repeater {
        model: root.streams

        Row {
            id: appRow
            required property var modelData

            width: parent.width
            spacing: 10

            BarText {
                width: 110
                anchors.verticalCenter: parent.verticalCenter
                elide: Text.ElideRight
                text: root.appLabel(appRow.modelData)
                font.pixelSize: Theme.fontSizeSmall
                color: Theme.subtext0
            }

            VolSlider {
                width: parent.width - 110 - 24 - 20
                value: appRow.modelData.audio?.volume ?? 0
                onMoved: v => {
                    if (appRow.modelData.audio)
                        appRow.modelData.audio.volume = v
                }
            }

            MouseArea {
                id: appMute
                width: 24
                height: 20
                hoverEnabled: true
                onClicked: {
                    if (appRow.modelData.audio)
                        appRow.modelData.audio.muted = !appRow.modelData.audio.muted
                }
                BarText {
                    anchors.centerIn: parent
                    text: appRow.modelData.audio?.muted ? "󰝟" : "󰕾"
                    font.pixelSize: Theme.fontSizeSmall
                    color: appRow.modelData.audio?.muted ? Theme.red
                         : appMute.containsMouse ? Theme.mauve : Theme.overlay1
                }
            }
        }
    }
}
