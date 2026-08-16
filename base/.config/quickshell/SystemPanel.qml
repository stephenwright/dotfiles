import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    property Item anchorItem
    property double lastCleared: 0

    visible: false
    implicitWidth: 300
    implicitHeight: content.implicitHeight + 28
    color: "transparent"

    anchors {
        top: true
        left: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "system"

    component MeterRow: Column {
        property string label
        property string detail
        property real frac
        property color barColor: Theme.mauve

        width: parent.width
        spacing: 3

        Item {
            width: parent.width
            height: 14

            BarText {
                anchors.left: parent.left
                text: label
                font.pixelSize: 11
                color: Theme.subtext0
            }
            BarText {
                anchors.right: parent.right
                text: detail
                font.pixelSize: 11
                color: Theme.text
            }
        }
        Rectangle {
            width: parent.width
            height: 4
            color: Theme.surface1

            Rectangle {
                width: parent.width * Math.max(0, Math.min(1, frac))
                height: parent.height
                color: barColor
            }
        }
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

    function levelColor(frac, warn, crit) {
        return frac >= crit ? Theme.red : frac >= warn ? Theme.yellow : Theme.mauve
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
            spacing: 10

            Item {
                width: parent.width
                height: 16

                BarText {
                    text: "System"
                    font.pixelSize: 11
                    color: Theme.overlay1
                }
                MouseArea {
                    id: monBtn
                    width: 20
                    height: parent.height
                    anchors.right: parent.right
                    hoverEnabled: true
                    onClicked: {
                        root.visible = false
                        Quickshell.execDetached(["gnome-system-monitor"])
                    }
                    BarText {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 12
                        color: monBtn.containsMouse ? Theme.mauve : Theme.overlay1
                    }
                }
            }

            MeterRow {
                label: "󰻠 CPU"
                detail: root.anchorItem.cpu + "%"
                frac: root.anchorItem.cpu / 100
                barColor: root.levelColor(frac, 0.7, 0.9)
            }

            MeterRow {
                label: "󰍛 Memory"
                detail: root.anchorItem.gb(root.anchorItem.memTot - root.anchorItem.memAvail)
                    + " / " + root.anchorItem.gb(root.anchorItem.memTot)
                    + "  (" + root.anchorItem.memPct + "%)"
                frac: root.anchorItem.memPct / 100
                barColor: root.levelColor(frac, 0.7, 0.8)
            }

            MeterRow {
                visible: root.anchorItem.swapTot > 0
                label: "󰾴 Swap"
                detail: root.anchorItem.gb(root.anchorItem.swapTot - root.anchorItem.swapFree)
                    + " / " + root.anchorItem.gb(root.anchorItem.swapTot)
                frac: root.anchorItem.swapTot > 0
                    ? (root.anchorItem.swapTot - root.anchorItem.swapFree) / root.anchorItem.swapTot
                    : 0
                barColor: root.levelColor(frac, 0.5, 0.8)
            }

            MeterRow {
                label: "󰋊 Disk /"
                detail: root.anchorItem.gb(root.anchorItem.diskUsed)
                    + " / " + root.anchorItem.gb(root.anchorItem.diskSize)
                    + "  · " + root.anchorItem.gb(root.anchorItem.diskAvail) + " free"
                frac: root.anchorItem.diskPct / 100
                barColor: root.levelColor(frac, 0.7, 0.9)
            }

            MeterRow {
                label: (root.anchorItem.temp >= 80 ? "󱃂" : root.anchorItem.temp >= 60 ? "󰔏" : "󱃃") + " Temp"
                detail: root.anchorItem.temp + "°C"
                frac: root.anchorItem.temp / 100
                barColor: root.levelColor(frac, 0.7, 0.8)
            }
        }
    }
}
