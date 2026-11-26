import QtQuick
import Quickshell.Bluetooth
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "bluetooth"
    initialFocusItem: powerRow

    // anchorItem is the BluetoothStatus bar widget; reuse its adapter lookup
    readonly property var adapter: anchorItem ? anchorItem.adapter : null

    // forgetting needs a second press: re-pairing takes a scan, or bluetoothctl
    // for devices that want a PIN
    property var armed: null
    // collapsed by default; stays as the user left it for the session
    property bool nearbyOpen: false
    property var pairingDevice: null
    property string pairError: ""

    onOpening: {
        armed = null
        pairError = ""
    }

    // Quickshell registers no BlueZ agent, so only devices that pair without a
    // PIN or passkey (audio, most mice) work here; the rest fail and say so
    function pair(device) {
        pairError = ""
        if (device.pairing || pairingDevice)
            return
        pairingDevice = device
        device.pair()
    }

    Connections {
        target: root.pairingDevice

        function onPairedChanged() {
            const d = root.pairingDevice
            if (!d.paired)
                return
            root.pairingDevice = null
            d.trusted = true
            d.connect()
        }

        function onPairingChanged() {
            const d = root.pairingDevice
            if (d.pairing || d.paired)
                return
            root.pairingDevice = null
            root.pairError = (d.name || d.deviceName) + ": pairing failed (needs a PIN? use bluetoothctl)"
        }
    }

    // scan only while the nearby list is showing
    Binding {
        target: root.adapter
        property: "discovering"
        value: true
        when: root.visible && root.nearbyOpen && root.powered
    }

    function forget(device) {
        if (armed === device) {
            armed = null
            device.forget()
        } else {
            armed = device
            disarm.restart()
        }
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = null
    }

    function recoverFocus() {
        focusRecovery.restart()
    }

    Timer {
        id: focusRecovery
        interval: 0
        onTriggered: if (root.visible) powerRow.forceActiveFocus(Qt.TabFocusReason)
    }

    readonly property bool powered: adapter?.enabled ?? false
    readonly property var paired: powered
        ? adapter.devices.values.filter(d => d.paired || d.bonded) : []
    // unnamed devices only advertise their address; nothing to pick them by
    readonly property var nearby: powered
        ? adapter.devices.values.filter(d => !d.paired && !d.bonded && d.deviceName
            && !/^([0-9A-F]{2}[-:]){5}[0-9A-F]{2}$/i.test(d.deviceName)) : []

    PanelHeader {
        icon: "󰂯"
        title: "Bluetooth"
        subtitle: !root.adapter ? "no adapter"
            : !root.powered ? "off"
            : root.paired.length + " paired"

        PanelSwitch {
            id: powerRow
            anchors.verticalCenter: parent.verticalCenter
            enabled: root.adapter !== null
            checked: root.powered
            accessibleName: "Bluetooth"
            onToggled: if (root.adapter) root.adapter.enabled = !root.adapter.enabled
        }
    }

    SectionLabel {
        text: "Devices"
        visible: root.paired.length > 0
    }

    // paired devices only; pairing itself stays in bluetoothctl
    Repeater {
        model: root.paired

        SelectRow {
            id: devRow
            required property var modelData

            readonly property bool isArmed: root.armed === modelData

            selected: modelData.connected
            trailingSpace: 24
            enabled: modelData.state !== BluetoothDeviceState.Connecting
                && modelData.state !== BluetoothDeviceState.Disconnecting
            label: modelData.name || modelData.deviceName
            labelColor: isArmed ? Theme.red : Theme.text
            detail: isArmed ? "again to forget"
                : modelData.state === BluetoothDeviceState.Connecting ? "connecting…"
                : modelData.state === BluetoothDeviceState.Disconnecting ? "disconnecting…"
                : modelData.connected && modelData.batteryAvailable
                    ? Math.round(modelData.battery * 100) + "%"
                : modelData.connected ? "connected"
                : ""
            accessibleName: (modelData.connected ? "Disconnect " : "Connect ") + label
            onClicked: modelData.connected ? modelData.disconnect() : modelData.connect()
            onKeyPressed: event => {
                if (event.key === Qt.Key_X || event.key === Qt.Key_Delete) {
                    root.forget(modelData)
                    event.accepted = true
                }
            }
            Component.onDestruction: {
                if (activeFocus || forgetBtn.activeFocus)
                    root.recoverFocus()
            }

            IconButton {
                id: forgetBtn
                anchors.right: parent.right
                anchors.rightMargin: 4
                anchors.verticalCenter: parent.verticalCenter
                // the row is the keyboard stop; x forgets from there
                activeFocusOnTab: false
                glyph: "󰆴"
                glyphSize: Theme.fontSizeSmall
                glyphColor: devRow.isArmed ? Theme.red : Theme.overlay0
                activeColor: Theme.red
                accessibleName: "Forget " + devRow.label
                onClicked: root.forget(devRow.modelData)
            }
        }
    }

    PanelButton {
        visible: root.powered
        width: parent.width
        height: 16
        accessibleName: (root.nearbyOpen ? "Hide" : "Show") + " nearby devices"
        onClicked: root.nearbyOpen = !root.nearbyOpen

        SectionLabel {
            anchors.fill: parent
            text: (root.nearbyOpen ? "▾ " : "▸ ") + "Nearby"
                + (root.nearbyOpen ? " (" + root.nearby.length + ")" : "")

            BarText {
                visible: root.nearbyOpen && (root.adapter?.discovering ?? false)
                anchors.verticalCenter: parent.verticalCenter
                text: "scanning…"
                font.pixelSize: Theme.fontSizeHint
                color: Theme.overlay0
            }
        }
    }

    Repeater {
        model: root.nearbyOpen ? root.nearby : []

        SelectRow {
            required property var modelData

            label: modelData.name || modelData.deviceName
            detail: modelData.pairing ? "pairing…" : ""
            accessibleName: "Pair " + label
            onClicked: root.pair(modelData)
            Component.onDestruction: {
                if (activeFocus)
                    root.recoverFocus()
            }
        }
    }

    BarText {
        visible: root.pairError !== ""
        width: parent.width
        wrapMode: Text.Wrap
        text: root.pairError
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.red
    }

    KeyHints {
        hints: [{ key: "enter", action: "connect / pair" }, { key: "x", action: "forget" },
                { key: "esc", action: "close" }]
    }
}
