import QtQuick
import Quickshell
import Quickshell.Services.Pipewire
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    readonly property var sink: Pipewire.defaultAudioSink
    readonly property real vol: sink?.audio?.volume ?? 0
    readonly property bool muted: sink?.audio?.muted ?? false
    readonly property int volPct: Math.round(vol * 100)

    PwObjectTracker {
        objects: root.sink ? [root.sink] : []
    }

    text: muted ? "󰝟" : volPct >= 67 ? "󰕾" : volPct >= 34 ? "󰖀" : "󰕿"
    fg: muted ? Theme.overlay0 : Theme.text

    function setVol(v) {
        if (sink?.audio)
            sink.audio.volume = Math.max(0, Math.min(1, v))
    }

    onScrolledUp: setVol(vol + 0.05)
    onScrolledDown: setVol(vol - 0.05)
    onClicked: event => {
        if (event.button === Qt.RightButton) {
            PanelManager.close()
            if (sink?.audio)
                sink.audio.muted = !sink.audio.muted
        } else if (event.button === Qt.MiddleButton) {
            PanelManager.close()
            Quickshell.execDetached(["pavucontrol"])
        } else {
            panel.toggle()
        }
    }

    SoundPanel {
        id: panel
        anchorItem: root
    }
}
