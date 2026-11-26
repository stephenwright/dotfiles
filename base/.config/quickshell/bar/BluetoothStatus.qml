import QtQuick
import Quickshell.Bluetooth
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    readonly property var adapter: Bluetooth.defaultAdapter
    // reading d.connected inside the binding registers per-device dependencies
    readonly property int connectedCount: {
        let n = 0
        for (const d of adapter?.devices.values ?? [])
            if (d.connected)
                n++
        return n
    }

    visible: adapter !== null
    text: !adapter || !adapter.enabled ? "󰂲" : connectedCount > 0 ? "󰂱" : "󰂯"
    fg: !adapter || !adapter.enabled ? Theme.overlay0 : Theme.text

    active: panel.visible

    onClicked: panel.toggle()

    BluetoothPanel {
        id: panel
        anchorItem: root
    }
}
