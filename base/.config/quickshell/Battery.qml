import QtQuick
import Quickshell.Io

BarWidget {
    id: root

    property int capacity: 0
    property string status: ""
    property bool acOnline: false

    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: status === "Charging" ? "󰂄"
        : acOnline ? "󰚥"
        : icons[Math.min(9, Math.floor(capacity / 10))]

    text: icon + " " + capacity + "%"
    fg: !acOnline && capacity <= 15 ? Theme.red
        : !acOnline && capacity <= 30 ? Theme.yellow
        : Theme.text
    blink: !acOnline && capacity <= 15

    Process {
        id: proc
        command: ["sh", "-c",
            "cat /sys/class/power_supply/BAT0/capacity /sys/class/power_supply/BAT0/status /sys/class/power_supply/AC/online"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split("\n")
                root.capacity = parseInt(p[0]) || 0
                root.status = (p[1] || "").trim()
                root.acOnline = (p[2] || "").trim() === "1"
            }
        }
    }
    Timer {
        interval: 10000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
}
