import QtQuick
import Quickshell
import Quickshell.Io

BarWidget {
    id: root

    property int percent: 0

    text: (percent >= 66 ? "󰃠" : percent >= 33 ? "󰃟" : "󰃞") + " " + percent + "%"

    Process {
        id: proc
        command: ["sh", "-c", "brightnessctl -m | cut -d, -f4 | tr -d '%'"]
        stdout: StdioCollector {
            onStreamFinished: root.percent = parseInt(this.text) || 0
        }
    }
    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
    Timer {
        id: refresh
        interval: 150
        onTriggered: proc.running = true
    }

    function set(arg) {
        Quickshell.execDetached(["brightnessctl", "set", arg])
        refresh.start()
    }

    onScrolledUp: set("5%+")
    onScrolledDown: set("5%-")
    onClicked: event => set(event.button === Qt.RightButton ? "100%" : "50%")
}
