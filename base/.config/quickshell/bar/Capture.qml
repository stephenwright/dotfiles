import QtQuick
import Quickshell
import Quickshell.Io
import "../lib"
import "../services"

// recording indicator only: hidden when idle, red ⏺ while recording, click stops.
// Start recording / take screenshots from the Display panel (or PRINT / stew capture).
BarWidget {
    id: root

    property bool recording: false

    visible: recording
    text: "⏺"
    fg: Theme.red

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
        PanelManager.close()
        Quickshell.execDetached(["sh", "-c", "~/bin/stew capture stop"])
        refresh.start()
    }
}
