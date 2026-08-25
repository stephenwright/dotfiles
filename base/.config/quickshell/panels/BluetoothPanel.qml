import QtQuick
import Quickshell.Bluetooth
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "bluetooth"
    panelWidth: 420
    initialFocusItem: powerRow

    // anchorItem is the BluetoothStatus bar widget; reuse its adapter lookup
    readonly property var adapter: anchorItem ? anchorItem.adapter : null

    function recoverFocus() {
        focusRecovery.restart()
    }

    Timer {
        id: focusRecovery
        interval: 0
        onTriggered: if (root.visible) powerRow.forceActiveFocus(Qt.TabFocusReason)
    }

    PanelToggle {
        id: powerRow
        width: parent.width
        height: 26
        enabled: root.adapter !== null
        checked: root.adapter?.enabled ?? false
        accessibleName: "Bluetooth"
        onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            text: "󰂯 Bluetooth"
            color: root.adapter && root.adapter.enabled ? Theme.blue : Theme.text
        }
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4
            text: root.adapter && root.adapter.enabled ? "on" : "off"
            color: root.adapter && root.adapter.enabled ? Theme.blue : Theme.overlay0
        }
    }

    BarText {
        text: "Devices"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
        visible: root.adapter !== null && root.adapter.enabled
    }

    Repeater {
        model: root.adapter && root.adapter.enabled ? root.adapter.devices : null

        PanelButton {
            id: dev
            required property var modelData

            // paired devices only; pairing itself stays in bluetoothctl
            visible: modelData.paired || modelData.bonded
            width: parent.width
            height: 26
            enabled: modelData.state !== BluetoothDeviceState.Connecting
                && modelData.state !== BluetoothDeviceState.Disconnecting
            accessibleName: (modelData.connected ? "Disconnect " : "Connect ")
                + (modelData.name || modelData.deviceName)
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            Component.onDestruction: {
                if (activeFocus)
                    root.recoverFocus()
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 4
                width: parent.width - status.implicitWidth - 16
                elide: Text.ElideRight
                text: dev.modelData.name || dev.modelData.deviceName
                color: dev.modelData.connected ? Theme.blue : Theme.text
            }
            BarText {
                id: status
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 4
                font.pixelSize: Theme.fontSizeHint
                text: dev.modelData.state === BluetoothDeviceState.Connecting ? "connecting…"
                    : dev.modelData.state === BluetoothDeviceState.Disconnecting ? "disconnecting…"
                    : dev.modelData.connected && dev.modelData.batteryAvailable
                        ? Math.round(dev.modelData.battery * 100) + "%"
                    : dev.modelData.connected ? "connected"
                    : ""
                color: dev.modelData.connected ? Theme.blue : Theme.overlay0
            }
        }
    }
}
