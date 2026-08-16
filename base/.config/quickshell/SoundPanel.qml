import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Services.Pipewire
import Quickshell.Wayland

PanelWindow {
    id: root

    property Item anchorItem
    property double lastCleared: 0

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property var sinks: Pipewire.nodes.values.filter(n => n.isSink && !n.isStream)
    readonly property var streams: Pipewire.nodes.values.filter(n => n.isSink && n.isStream)

    visible: false
    implicitWidth: 320
    implicitHeight: content.implicitHeight + 28
    color: "transparent"

    anchors {
        top: true
        left: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "sound"

    PwObjectTracker {
        objects: root.sinks.concat(root.streams)
    }

    function toggle() {
        if (visible) {
            visible = false
            return
        }
        // a click that dismissed the grab also reaches the widget on release;
        // don't let it immediately reopen the panel
        if (Date.now() - lastCleared < 300)
            return
        const win = anchorItem.QsWindow.window
        screen = win.screen
        const r = anchorItem.mapToItem(null, 0, 0)
        const x = r.x + anchorItem.width / 2 - implicitWidth / 2
        margins.left = Math.round(Math.max(8, Math.min(x, screen.width - implicitWidth - 8)))
        visible = true
    }

    function label(n) {
        return n.nickname || n.description || n.name
    }

    function appLabel(n) {
        return (n.properties && n.properties["application.name"]) || label(n)
    }

    HyprlandFocusGrab {
        // wait for the surface to be mapped, or the grab registers nothing
        active: root.visible && root.backingWindowVisible
        windows: [root]
        onCleared: {
            root.lastCleared = Date.now()
            root.visible = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        border.color: Theme.mauve
        border.width: 2

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 8

            // output
            Item {
                width: parent.width
                height: 16

                BarText {
                    text: "Output"
                    font.pixelSize: 11
                    color: Theme.overlay1
                }
                MouseArea {
                    id: mixerBtn
                    width: 20
                    height: parent.height
                    anchors.right: parent.right
                    hoverEnabled: true
                    onClicked: {
                        root.visible = false
                        Quickshell.execDetached(["pavucontrol"])
                    }
                    BarText {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 12
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
                font.pixelSize: 11
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

            // per-app streams
            BarText {
                visible: root.streams.length > 0
                text: "Apps"
                font.pixelSize: 11
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
                        font.pixelSize: 11
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
                            font.pixelSize: 11
                            color: appRow.modelData.audio?.muted ? Theme.red
                                 : appMute.containsMouse ? Theme.mauve : Theme.overlay1
                        }
                    }
                }
            }
        }
    }
}
