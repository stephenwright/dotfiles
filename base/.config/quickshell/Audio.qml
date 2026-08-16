import QtQuick
import Quickshell
import Quickshell.Io

BarWidget {
    id: root

    property int volume: 0
    property bool muted: false

    text: (muted ? "󰝟" : volume >= 67 ? "󰕾" : volume >= 34 ? "󰖀" : "󰕿") + " " + volume + "%"
    fg: muted ? Theme.overlay0 : Theme.text

    Process {
        id: proc
        command: ["sh", "-c", "wpctl get-volume @DEFAULT_AUDIO_SINK@"]
        stdout: StdioCollector {
            onStreamFinished: {
                const m = this.text.match(/Volume: ([0-9.]+)( \[MUTED\])?/)
                if (m) {
                    root.volume = Math.round(parseFloat(m[1]) * 100)
                    root.muted = !!m[2]
                }
            }
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
        interval: 150
        onTriggered: proc.running = true
    }

    function run(cmd) {
        Quickshell.execDetached(["sh", "-c", cmd])
        refresh.start()
    }

    onScrolledUp: run("wpctl set-volume -l 1.0 @DEFAULT_AUDIO_SINK@ 5%+")
    onScrolledDown: run("wpctl set-volume @DEFAULT_AUDIO_SINK@ 5%-")
    onClicked: event => {
        if (event.button === Qt.RightButton)
            run("wpctl set-mute @DEFAULT_AUDIO_SINK@ toggle")
        else
            Quickshell.execDetached(["pavucontrol"])
    }
}
