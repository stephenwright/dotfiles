pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// Screen-recording state from `stew capture`; one poller for all bars.
Singleton {
    id: root

    property bool recording: false

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
        onTriggered: if (!proc.running) proc.running = true
    }

    Timer {
        id: refresh
        interval: 300
        onTriggered: if (!proc.running) proc.running = true
    }

    function start(format) {
        Quickshell.execDetached(["sh", "-c", "~/bin/stew capture start --format " + format])
        refresh.start()
    }

    function stop() {
        Quickshell.execDetached(["sh", "-c", "~/bin/stew capture stop"])
        refresh.start()
    }
}
