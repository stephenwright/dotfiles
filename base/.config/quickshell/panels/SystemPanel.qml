import QtQuick
import Quickshell
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "system"

    BarText {
        text: "System"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    MeterRow {
        label: "󰻠 CPU"
        detail: root.anchorItem.cpu + "%"
        frac: root.anchorItem.cpu / 100
        barColor: Theme.levelColor(frac, 0.7, 0.9)
    }

    MeterRow {
        label: "󰍛 Memory"
        detail: root.anchorItem.gb(root.anchorItem.memTot - root.anchorItem.memAvail)
            + " / " + root.anchorItem.gb(root.anchorItem.memTot)
            + "  (" + root.anchorItem.memPct + "%)"
        frac: root.anchorItem.memPct / 100
        barColor: Theme.levelColor(frac, 0.7, 0.8)
    }

    MeterRow {
        visible: root.anchorItem.swapTot > 0
        label: "󰾴 Swap"
        detail: root.anchorItem.gb(root.anchorItem.swapTot - root.anchorItem.swapFree)
            + " / " + root.anchorItem.gb(root.anchorItem.swapTot)
        frac: root.anchorItem.swapTot > 0
            ? (root.anchorItem.swapTot - root.anchorItem.swapFree) / root.anchorItem.swapTot
            : 0
        barColor: Theme.levelColor(frac, 0.5, 0.8)
    }

    MeterRow {
        label: "󰋊 Disk /"
        detail: root.anchorItem.gb(root.anchorItem.diskUsed)
            + " / " + root.anchorItem.gb(root.anchorItem.diskSize)
            + "  · " + root.anchorItem.gb(root.anchorItem.diskAvail) + " free"
        frac: root.anchorItem.diskPct / 100
        barColor: Theme.levelColor(frac, 0.7, 0.9)
    }

    MeterRow {
        label: (root.anchorItem.temp >= 80 ? "󱃂" : root.anchorItem.temp >= 60 ? "󰔏" : "󱃃") + " Temp"
        detail: root.anchorItem.temp + "°C"
        frac: root.anchorItem.temp / 100
        barColor: Theme.levelColor(frac, 0.7, 0.8)
    }

    MouseArea {
        id: monRow
        width: parent.width
        height: 26
        hoverEnabled: true
        onClicked: {
            root.close()
            Quickshell.execDetached(Settings.systemMonitor)
        }

        Rectangle {
            anchors.fill: parent
            color: monRow.containsMouse ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
        }
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            text: " Open btop"
            color: monRow.containsMouse ? Theme.mauve : Theme.text
        }
    }
}
