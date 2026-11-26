import QtQuick
import Quickshell
import Quickshell.Wayland
import "../lib"
import "../services"

// Big output name in the middle of every screen for a few seconds.
Variants {
    model: Quickshell.screens

    PanelWindow {
        id: win

        required property var modelData
        readonly property var info: Monitors.find(modelData.name)
        property bool shown: false

        screen: modelData
        visible: shown
        color: "transparent"
        exclusiveZone: 0
        WlrLayershell.layer: WlrLayer.Overlay
        WlrLayershell.namespace: "qs-identify"
        implicitWidth: card.width
        implicitHeight: card.height
        mask: Region {}

        Connections {
            target: Monitors
            function onIdentifyRequested() {
                win.shown = true
                hide.restart()
            }
        }

        Timer {
            id: hide
            interval: 2500
            onTriggered: win.shown = false
        }

        Rectangle {
            id: card
            width: col.implicitWidth + 64
            height: col.implicitHeight + 40
            color: Theme.panelBg
            border.color: Theme.mauve
            border.width: Theme.panelBorder

            Column {
                id: col
                anchors.centerIn: parent
                spacing: 6

                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.modelData.name
                    font.pixelSize: 56
                    font.bold: true
                    color: Theme.mauve
                }
                BarText {
                    anchors.horizontalCenter: parent.horizontalCenter
                    text: win.info
                        ? (win.info.model || win.info.description) + "  ·  "
                            + win.info.width + "×" + win.info.height
                        : ""
                    color: Theme.subtext0
                }
            }
        }
    }
}
