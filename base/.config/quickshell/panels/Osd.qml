import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import Quickshell.Services.Pipewire
import "../lib"
import "../services"

// Passive volume/brightness indicator, bottom-center of the focused monitor.
// Watches the values themselves, so keybinds, bar scrolling and other apps
// all trigger it.
PanelWindow {
    id: root

    property string icon: ""
    property real value: 0
    property bool muted: false
    property bool shown: false
    // the first values after startup/reload are not changes
    property bool armed: false

    readonly property var sink: Pipewire.defaultAudioSink

    screen: Quickshell.screens.find(s => s.name === Hyprland.focusedMonitor?.name) ?? null
    visible: card.opacity > 0
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-osd"
    anchors.bottom: true
    margins.bottom: 120
    implicitWidth: 280
    implicitHeight: 44
    mask: Region {}

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    Timer {
        interval: 1500
        running: true
        onTriggered: root.armed = true
    }

    Timer {
        id: hideTimer
        interval: 1500
        onTriggered: root.shown = false
    }

    function show(icon, value, muted) {
        // the sound/display panels already show these as sliders
        const open = PanelManager.current?.panelName
        if (!armed || open === "sound" || open === "display")
            return
        root.icon = icon
        root.value = value
        root.muted = muted
        shown = true
        hideTimer.restart()
    }

    function showVolume() {
        const a = sink?.audio
        if (!a)
            return
        const pct = Math.round(a.volume * 100)
        show(a.muted ? "󰝟" : pct >= 67 ? "󰕾" : pct >= 34 ? "󰖀" : "󰕿", a.volume, a.muted)
    }

    Connections {
        target: root.sink?.audio ?? null
        function onVolumeChanged() {
            root.showVolume()
        }
        function onMutedChanged() {
            root.showVolume()
        }
    }

    Connections {
        target: Brightness
        function onPercentChanged() {
            root.show("󰃟", Brightness.percent / 100, false)
        }
    }

    Rectangle {
        id: card
        anchors.fill: parent
        color: Theme.panelBg
        border.color: Theme.surface1
        border.width: 1
        opacity: root.shown ? 1 : 0

        Behavior on opacity {
            NumberAnimation {
                duration: 150
            }
        }

        Row {
            anchors.fill: parent
            anchors.leftMargin: 14
            anchors.rightMargin: 14
            spacing: 12

            BarText {
                width: 22
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignHCenter
                font.pixelSize: Theme.fontSizeLarge + 4
                color: root.muted ? Theme.overlay0 : Theme.text
                text: root.icon
            }

            Rectangle {
                width: parent.width - 22 - 40 - parent.spacing * 2
                height: 6
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surface0

                Rectangle {
                    width: parent.width * Math.max(0, Math.min(1, root.value))
                    height: parent.height
                    color: root.muted ? Theme.overlay0 : Theme.mauve
                }
            }

            BarText {
                width: 40
                anchors.verticalCenter: parent.verticalCenter
                horizontalAlignment: Text.AlignRight
                color: Theme.subtext0
                text: Math.round(root.value * 100) + "%"
            }
        }
    }
}
