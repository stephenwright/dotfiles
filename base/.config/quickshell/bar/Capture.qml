import QtQuick
import "../lib"
import "../services"

// recording indicator only: hidden when idle, red ⏺ while recording, click stops.
// Start recording / take screenshots from the Display panel (or PRINT / stew capture).
BarWidget {
    visible: Recorder.recording
    text: "⏺"
    fg: Theme.red

    onClicked: {
        PanelManager.close()
        Recorder.stop()
    }
}
