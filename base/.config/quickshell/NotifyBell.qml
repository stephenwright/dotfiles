import QtQuick
import Quickshell
import Quickshell.Io

BarWidget {
    id: root

    property bool dnd: false

    text: dnd ? "" : "󰂚"
    fg: dnd ? Theme.red : Theme.sapphire

    Process {
        id: proc
        command: ["sh", "-c", "makoctl mode 2>/dev/null | grep -qw dnd && echo dnd || echo normal"]
        stdout: StdioCollector {
            onStreamFinished: root.dnd = this.text.trim() === "dnd"
        }
    }
    Timer {
        interval: 1000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: proc.running = true
    }
    Timer {
        id: refresh
        interval: 300
        onTriggered: proc.running = true
    }

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            Quickshell.execDetached(["sh", "-c", "~/bin/stew notify dnd"])
            refresh.start()
        } else {
            Quickshell.execDetached(["sh", "-c", "~/bin/stew notify menu"])
        }
    }
}
