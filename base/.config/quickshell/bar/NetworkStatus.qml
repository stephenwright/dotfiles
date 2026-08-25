import QtQuick
import Quickshell
import Quickshell.Networking
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDev: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNet: wifiDev ? (wifiDev.networks.values.find(n => n.connected) ?? null) : null

    readonly property real signal: {
        if (!wifiNet)
            return 0
        const s = wifiNet.signalStrength
        return s > 1 ? s / 100 : s
    }

    text: wifiNet ? (signal >= 0.75 ? "󰤨" : signal >= 0.5 ? "󰤥" : signal >= 0.25 ? "󰤢" : "󰤟")
        : wiredDev && wiredDev.connected ? "󰈀"
        : !Networking.wifiEnabled ? "󰤮"
        : "󰤭"
    fg: wifiNet ? Theme.green
        : wiredDev && wiredDev.connected ? Theme.sapphire
        : Theme.red

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            PanelManager.close()
            Quickshell.execDetached(["nm-connection-editor"])
        } else {
            panel.toggle()
        }
    }

    NetworkPanel {
        id: panel
        anchorItem: root
    }
}
