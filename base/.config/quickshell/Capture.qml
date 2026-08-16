import QtQuick
import Quickshell
import Quickshell.Io

BarWidget {
    id: root

    property bool recording: false

    text: "⏺"
    fg: recording ? Theme.red : Theme.overlay0

    Process {
        id: proc
        command: ["sh", "-c", "~/bin/stew capture status 2>/dev/null | grep -q recording && echo rec || echo idle"]
        stdout: StdioCollector {
            onStreamFinished: root.recording = this.text.trim() === "rec"
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

    onClicked: {
        Quickshell.execDetached(["sh", "-c", "~/bin/stew capture toggle"])
        refresh.start()
    }
}
