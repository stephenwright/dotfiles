import QtQuick
import Quickshell
import Quickshell.Io

BarWidget {
    id: root

    property string kind: ""
    property string label: ""

    text: kind === "wifi" ? "󰤨 " + label
        : kind === "ethernet" ? "󰈀 " + label
        : "󰤭 Disconnected"
    fg: kind === "wifi" ? Theme.green
        : kind === "ethernet" ? Theme.sapphire
        : Theme.red

    Process {
        id: proc
        command: ["sh", "-c",
            "nmcli -t -f NAME,TYPE,DEVICE connection show --active | grep -vE ':(loopback|tun|bridge):' | head -1"]
        stdout: StdioCollector {
            onStreamFinished: {
                const line = this.text.trim()
                if (!line) {
                    root.kind = ""
                    root.label = ""
                    return
                }
                const p = line.split(":")
                if (p[1] && p[1].includes("wireless")) {
                    root.kind = "wifi"
                    root.label = p[0]
                } else {
                    root.kind = "ethernet"
                    root.label = p[2] || p[0]
                }
            }
        }
    }
    Timer {
        interval: 5000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }

    onClicked: Quickshell.execDetached(["nm-connection-editor"])
}
