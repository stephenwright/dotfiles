import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Networking
import Quickshell.Wayland

PanelWindow {
    id: root

    property Item anchorItem
    property double lastCleared: 0
    property var pendingNet: null
    property var lastAttempt: null
    property string errorMsg: ""

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

    visible: false
    implicitWidth: 320
    implicitHeight: content.implicitHeight + 28
    color: "transparent"

    anchors {
        top: true
        left: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "network"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

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
        pendingNet = null
        errorMsg = ""
        refreshIp()
        visible = true
    }

    function activate(n) {
        errorMsg = ""
        if (n.connected || n.stateChanging)
            return
        if (n.known || !secured(n)) {
            lastAttempt = n
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
        pendingNet.connectWithPsk(pskInput.text)
        pendingNet = null
        pskInput.text = ""
    }

    Connections {
        target: root.lastAttempt

        function onConnectionFailed(reason) {
            root.errorMsg = "Connection failed"
        }
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
            spacing: 8

            Item {
                width: parent.width
                height: 18

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "Wi-Fi"
                    font.pixelSize: 11
                    color: Theme.overlay1
                }

                MouseArea {
                    id: wifiSwitch
                    width: 34
                    height: 16
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.right: gearBtn.left
                    anchors.rightMargin: 10
                    onClicked: Networking.wifiEnabled = !Networking.wifiEnabled

                    Rectangle {
                        anchors.fill: parent
                        color: Networking.wifiEnabled ? Qt.alpha(Theme.mauve, 0.4) : Theme.surface1

                        Rectangle {
                            width: 12
                            height: 12
                            anchors.verticalCenter: parent.verticalCenter
                            x: Networking.wifiEnabled ? parent.width - width - 2 : 2
                            color: Networking.wifiEnabled ? Theme.mauve : Theme.overlay0
                        }
                    }
                }

                MouseArea {
                    id: gearBtn
                    width: 20
                    height: parent.height
                    anchors.right: parent.right
                    hoverEnabled: true
                    onClicked: {
                        root.visible = false
                        Quickshell.execDetached(["nm-connection-editor"])
                    }
                    BarText {
                        anchors.centerIn: parent
                        text: ""
                        font.pixelSize: 12
                        color: gearBtn.containsMouse ? Theme.mauve : Theme.overlay1
                    }
                }
            }

            // current connection: ip + device (wired falls back to device name)
            BarText {
                visible: root.curDev != null
                width: parent.width
                elide: Text.ElideRight
                text: (root.curDev === root.wiredDev ? "󰈀 " : "󰩟 ")
                    + (root.ipAddr || "…")
                    + (root.curDev ? " on " + root.curDev.name : "")
                font.pixelSize: 11
                color: Theme.subtext0
            }

            BarText {
                visible: root.knownNets.length > 0
                text: "Known"
                font.pixelSize: 11
                color: Theme.overlay1
            }

            Repeater {
                model: root.knownNets

                NetRow { panel: root }
            }

            BarText {
                visible: root.otherNets.length > 0
                text: "Other"
                font.pixelSize: 11
                color: Theme.overlay1
            }

            Repeater {
                model: root.otherNets

                NetRow { panel: root }
            }

            BarText {
                visible: !Networking.wifiEnabled
                text: "Wi-Fi is off"
                color: Theme.overlay0
            }

            Column {
                visible: root.pendingNet != null
                width: parent.width
                spacing: 4

                BarText {
                    text: "password for " + (root.pendingNet ? root.pendingNet.name : "")
                    font.pixelSize: 11
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
                        onAccepted: root.submitPsk()

                        Keys.onPressed: event => {
                            if (event.key === Qt.Key_Escape) {
                                root.pendingNet = null
                                event.accepted = true
                            }
                        }
                    }
                }
            }

            BarText {
                visible: root.errorMsg !== ""
                text: root.errorMsg
                font.pixelSize: 11
                color: Theme.red
            }
        }
    }
}
