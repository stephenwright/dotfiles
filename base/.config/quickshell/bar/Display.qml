import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Wayland
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    property int percent: 0

    text: "󰍹"
    fg: Caffeine.on ? Theme.green : Theme.text

    // one inhibitor per bar/screen; overlapping inhibitors are harmless
    IdleInhibitor {
        window: root.QsWindow.window
        enabled: Caffeine.on
    }

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
    onClicked: event => {
        if (event.button === Qt.RightButton) {
            PanelManager.close()
            set("100%")
        } else {
            panel.toggle()
        }
    }

    DisplayPanel {
        id: panel
        anchorItem: root
    }
}
