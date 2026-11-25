pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Backlight level read from sysfs. Polled because sysfs doesn't notify on
// writes, and keybinds change it through brightnessctl behind our back.
// Unavailable (and never polled) on machines without a backlight.
Singleton {
    id: root

    property string device: ""
    property int max: 0
    property int raw: 0

    readonly property bool available: device !== "" && max > 0
    readonly property int percent: max > 0 ? Math.round(raw * 100 / max) : 0

    // the same device brightnessctl picks by default for the backlight class
    Process {
        running: true
        command: ["brightnessctl", "-m", "-c", "backlight"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(",")
                root.max = parseInt(p[4]) || 0
                root.device = p[0] || ""
            }
        }
    }

    FileView {
        id: level
        path: root.device ? "/sys/class/backlight/" + root.device + "/brightness" : ""
        printErrors: false
        onLoaded: root.raw = parseInt(text()) || 0
    }

    Timer {
        interval: 250
        running: root.available
        repeat: true
        onTriggered: level.reload()
    }

    // arg is brightnessctl syntax: "40%", "5%+", "5%-"
    function set(arg) {
        if (!available)
            return
        Quickshell.execDetached(["brightnessctl", "-d", device, "set", arg])
    }
}
