import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Networking
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "network"
    contentSpacing: 8
    initialFocusItem: wifiSwitch

    property var pendingNet: null
    property var lastAttempt: null
    // true when lastAttempt was a fresh password entry; NM saves the profile
    // before authenticating, so a rejected password must be forgotten again
    property bool attemptWasNew: false
    property string errorMsg: ""
    // collapsed by default; stays as the user left it for the session
    property bool otherOpen: false

    readonly property var wifiDev: Networking.devices.values.find(d => d.type === DeviceType.Wifi) ?? null
    readonly property var wiredDev: Networking.devices.values.find(d => d.type === DeviceType.Wired) ?? null
    readonly property var wifiNet: wifiDev ? (wifiDev.networks.values.find(n => n.connected) ?? null) : null
    readonly property var curDev: wifiNet ? wifiDev
        : (wiredDev && wiredDev.connected ? wiredDev : null)
    property string ipAddr: ""

    readonly property var knownNets: {
        if (!wifiDev)
            return []
        const l = wifiDev.networks.values.filter(n => n.known)
        l.sort((a, b) => (b.connected - a.connected)
            || (norm(b.signalStrength) - norm(a.signalStrength)))
        return l
    }
    readonly property var otherNets: {
        if (!wifiDev)
            return []
        const l = wifiDev.networks.values.filter(n => !n.known)
        l.sort((a, b) => norm(b.signalStrength) - norm(a.signalStrength))
        return l.slice(0, 8)
    }

    onOpening: {
        pendingNet = null
        errorMsg = ""
        refreshIp()
    }

    onCurDevChanged: if (visible) refreshIp()

    function refreshIp() {
        if (!curDev) {
            ipAddr = ""
            return
        }
        ipProc.command = ["sh", "-c",
            "ip -4 -o addr show dev " + curDev.name + " | awk '{print $4}' | head -1"]
        ipProc.running = true
    }

    Process {
        id: ipProc
        stdout: StdioCollector {
            onStreamFinished: root.ipAddr = this.text.trim()
        }
    }

    // live scan results only while the panel is open
    onVisibleChanged: {
        if (wifiDev)
            wifiDev.scannerEnabled = visible
    }

    function norm(s) {
        return s > 1 ? s / 100 : s
    }

    function secured(n) {
        return n.security !== WifiSecurityType.Open && n.security !== WifiSecurityType.Owe
    }

    function sigIcon(n) {
        const s = norm(n.signalStrength)
        return s >= 0.75 ? "󰤨" : s >= 0.5 ? "󰤥" : s >= 0.25 ? "󰤢" : "󰤟"
    }

    function activate(n) {
        errorMsg = ""
        if (n.connected || n.stateChanging)
            return
        if (n.known || !secured(n)) {
            lastAttempt = n
            attemptWasNew = false
            pendingNet = null
            n.connect()
        } else {
            pendingNet = n
            pskInput.text = ""
            pskInput.forceActiveFocus()
        }
    }

    function submitPsk() {
        if (!pendingNet)
            return
        lastAttempt = pendingNet
        attemptWasNew = true
        pendingNet.connectWithPsk(pskInput.text)
        pendingNet = null
        pskInput.text = ""
    }

    function forget(n) {
        errorMsg = ""
        if (pendingNet === n)
            pendingNet = null
        if (lastAttempt === n)
            lastAttempt = null
        n.forget()
    }

    function failReason(reason) {
        switch (reason) {
        case ConnectionFailReason.NoSecrets:
        case ConnectionFailReason.WifiClientFailed:
            return "wrong password"
        case ConnectionFailReason.WifiAuthTimeout:
            return "authentication timed out"
        case ConnectionFailReason.WifiClientDisconnected:
            return "disconnected by access point"
        case ConnectionFailReason.WifiNetworkLost:
            return "network lost"
        default:
            return ConnectionFailReason.toString(reason)
        }
    }

    function recoverFocus() {
        focusRecovery.restart()
    }

    Timer {
        id: focusRecovery
        interval: 0
        onTriggered: if (root.visible) wifiSwitch.forceActiveFocus(Qt.TabFocusReason)
    }

    Connections {
        target: root.lastAttempt

        function onConnectionFailed(reason) {
            const n = root.lastAttempt
            root.errorMsg = n.name + ": " + root.failReason(reason)
            if (!root.attemptWasNew)
                return
            if (n.known)
                n.forget()
            root.pendingNet = n
            pskInput.text = ""
            pskInput.forceActiveFocus()
        }
    }

    PanelHeader {
        icon: "󰖩"
        title: "Wi-Fi"
        subtitle: !Networking.wifiEnabled ? "off"
            : root.wifiNet ? root.wifiNet.name
            : root.curDev === root.wiredDev && root.wiredDev ? "wired"
            : "disconnected"

        PanelSwitch {
            id: wifiSwitch
            anchors.verticalCenter: parent.verticalCenter
            checked: Networking.wifiEnabled
            accessibleName: "Wi-Fi"
            onToggled: Networking.wifiEnabled = !Networking.wifiEnabled
        }

        IconButton {
            anchors.verticalCenter: parent.verticalCenter
            glyph: "󰒓"
            accessibleName: "Network settings"
            onClicked: {
                root.close()
                Quickshell.execDetached(["nm-connection-editor"])
            }
        }
    }

    // current connection: ip + device
    BarText {
        visible: root.curDev != null
        width: parent.width
        elide: Text.ElideRight
        text: (root.ipAddr || "…") + (root.curDev ? "  ·  " + root.curDev.name : "")
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    SectionLabel {
        visible: root.knownNets.length > 0
        text: "Known"
    }

    Repeater {
        model: root.knownNets

        NetRow { panel: root }
    }

    PanelButton {
        id: otherToggle
        visible: root.otherNets.length > 0
        width: parent.width
        height: 16
        accessibleName: (root.otherOpen ? "Hide" : "Show") + " other networks"
        onClicked: root.otherOpen = !root.otherOpen

        SectionLabel {
            anchors.fill: parent
            text: (root.otherOpen ? "▾ " : "▸ ") + "Other (" + root.otherNets.length + ")"
        }
    }

    Repeater {
        model: root.otherOpen ? root.otherNets : []

        NetRow { panel: root }
    }

    Column {
        visible: root.pendingNet != null
        width: parent.width
        spacing: 4

        BarText {
            text: "password for " + (root.pendingNet ? root.pendingNet.name : "")
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.overlay1
        }

        Rectangle {
            width: parent.width
            height: 26
            color: Theme.surface0
            border.color: Theme.surface1
            border.width: 1

            TextInput {
                id: pskInput
                anchors.fill: parent
                anchors.leftMargin: 8
                anchors.rightMargin: 8
                verticalAlignment: TextInput.AlignVCenter
                echoMode: TextInput.Password
                color: Theme.text
                font.family: Theme.fontFamily
                font.pixelSize: 13
                clip: true
                activeFocusOnTab: true
                Accessible.name: "Network password"
                onAccepted: root.submitPsk()
            }
        }
    }

    BarText {
        visible: root.errorMsg !== ""
        text: root.errorMsg
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.red
    }

    KeyHints {
        hints: [{ key: "enter", action: "connect" }, { key: "x", action: "forget" },
                { key: "esc", action: "close" }]
    }
}
