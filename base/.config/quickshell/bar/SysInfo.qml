import QtQuick
import Quickshell
import Quickshell.Io
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    property int cpu: 0
    property int temp: 0
    property real memTot: 0
    property real memAvail: 0
    property real swapTot: 0
    property real swapFree: 0
    property real diskUsed: 0
    property real diskSize: 0
    property real diskAvail: 0

    readonly property int memPct: memTot > 0 ? Math.round((memTot - memAvail) * 100 / memTot) : 0
    readonly property int diskPct: diskSize > 0 ? Math.round(diskUsed * 100 / diskSize) : 0

    readonly property bool critical: cpu >= 90 || memPct >= 80 || diskPct >= 90 || temp >= 80
    readonly property bool warning: cpu >= 70 || memPct >= 70 || diskPct >= 70 || temp >= 70

    text: "󰄨"
    fg: critical ? Theme.red : warning ? Theme.yellow : Theme.text
    blink: critical

    function gb(kb) {
        return (kb / 1048576).toFixed(1) + "G"
    }

    Process {
        id: proc
        command: ["sh", "-c",
            "cpu=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}'); " +
            "mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} /SwapTotal/{st=$2} /SwapFree/{sf=$2} " +
            "END{print t, a, st, sf}' /proc/meminfo); " +
            "disk=$(df -k --output=used,size,avail / | tail -1); " +
            "temp=0; for h in /sys/class/hwmon/*; do " +
            "if [ \"$(cat $h/name 2>/dev/null)\" = acpitz ]; then temp=$(( $(cat $h/temp1_input) / 1000 )); break; fi; done; " +
            "echo \"$cpu $mem $disk $temp\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/)
                root.cpu = parseInt(p[0]) || 0
                root.memTot = parseInt(p[1]) || 0
                root.memAvail = parseInt(p[2]) || 0
                root.swapTot = parseInt(p[3]) || 0
                root.swapFree = parseInt(p[4]) || 0
                root.diskUsed = parseInt(p[5]) || 0
                root.diskSize = parseInt(p[6]) || 0
                root.diskAvail = parseInt(p[7]) || 0
                root.temp = parseInt(p[8]) || 0
            }
        }
    }

    Timer {
        interval: panel.visible ? 1000 : 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }

    onClicked: event => {
        if (event.button === Qt.RightButton)
            Quickshell.execDetached(Settings.systemMonitor)
        else
            panel.toggle()
    }

    SystemPanel {
        id: panel
        anchorItem: root
    }
}
