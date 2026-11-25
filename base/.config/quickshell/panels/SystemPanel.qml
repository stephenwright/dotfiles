import QtQuick
import Quickshell
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "system"
    initialFocusItem: monRow

    BarText {
        text: "System"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    MeterRow {
        label: "󰻠 CPU"
        detail: SysStats.cpu + "%"
        frac: SysStats.cpu / 100
        barColor: Theme.levelColor(frac, 0.7, 0.9)
    }

    MeterRow {
        label: "󰍛 Memory"
        detail: SysStats.gb(SysStats.memTot - SysStats.memAvail)
            + " / " + SysStats.gb(SysStats.memTot)
            + "  (" + SysStats.memPct + "%)"
        frac: SysStats.memPct / 100
        barColor: Theme.levelColor(frac, 0.7, 0.8)
    }

    MeterRow {
        visible: SysStats.swapTot > 0
        label: "󰾴 Swap"
        detail: SysStats.gb(SysStats.swapTot - SysStats.swapFree)
            + " / " + SysStats.gb(SysStats.swapTot)
        frac: SysStats.swapTot > 0
            ? (SysStats.swapTot - SysStats.swapFree) / SysStats.swapTot
            : 0
        barColor: Theme.levelColor(frac, 0.5, 0.8)
    }

    MeterRow {
        label: "󰋊 Disk /"
        detail: SysStats.gb(SysStats.diskUsed)
            + " / " + SysStats.gb(SysStats.diskSize)
            + "  · " + SysStats.gb(SysStats.diskAvail) + " free"
        frac: SysStats.diskPct / 100
        barColor: Theme.levelColor(frac, 0.7, 0.9)
    }

    MeterRow {
        label: (SysStats.temp >= 80 ? "󱃂" : SysStats.temp >= 60 ? "󰔏" : "󱃃") + " Temp"
        detail: SysStats.temp + "°C"
        frac: SysStats.temp / 100
        barColor: Theme.levelColor(frac, 0.7, 0.8)
    }

    PanelButton {
        id: monRow
        width: parent.width
        height: 26
        accessibleName: "Open btop"
        onClicked: {
            root.close()
            Quickshell.execDetached(Settings.systemMonitor)
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            text: " Open btop"
            color: monRow.hovered || monRow.showFocus ? Theme.mauve : Theme.text
        }
    }
}
