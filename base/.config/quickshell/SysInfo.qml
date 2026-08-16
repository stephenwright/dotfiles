import QtQuick
import Quickshell
import Quickshell.Io

Row {
    id: root
    height: parent.height

    property int cpu: 0
    property int mem: 0
    property int disk: 0
    property int temp: 0

    Process {
        id: proc
        command: ["sh", "-c",
            "cpu=$(vmstat 1 2 | tail -1 | awk '{print 100-$15}'); " +
            "mem=$(awk '/MemTotal/{t=$2} /MemAvailable/{a=$2} END{printf \"%d\", (t-a)*100/t}' /proc/meminfo); " +
            "disk=$(df --output=used,size / | tail -1 | awk '{printf \"%d\", $1*100/$2}'); " +
            "temp=0; for h in /sys/class/hwmon/*; do " +
            "if [ \"$(cat $h/name 2>/dev/null)\" = acpitz ]; then temp=$(( $(cat $h/temp1_input) / 1000 )); break; fi; done; " +
            "echo \"$cpu $mem $disk $temp\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/)
                root.cpu = parseInt(p[0]) || 0
                root.mem = parseInt(p[1]) || 0
                root.disk = parseInt(p[2]) || 0
                root.temp = parseInt(p[3]) || 0
            }
        }
    }

    Timer {
        interval: 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!proc.running) proc.running = true
    }

    BarWidget {
        text: "󰻠 " + root.cpu + "%"
        fg: root.cpu >= 90 ? Theme.red : root.cpu >= 70 ? Theme.yellow : Theme.text
        blink: root.cpu >= 90
        onClicked: Quickshell.execDetached(["gnome-system-monitor"])
    }
    BarWidget {
        text: "󰍛 " + root.mem + "%"
        fg: root.mem >= 80 ? Theme.red : root.mem >= 70 ? Theme.yellow : Theme.text
        blink: root.mem >= 80
        onClicked: Quickshell.execDetached(["gnome-system-monitor"])
    }
    BarWidget {
        text: "󰋊 " + root.disk + "%"
        fg: root.disk >= 90 ? Theme.red : root.disk >= 70 ? Theme.yellow : Theme.text
        blink: root.disk >= 90
    }
    BarWidget {
        text: (root.temp >= 80 ? "󱃂" : root.temp >= 60 ? "󰔏" : "󱃃") + " " + root.temp + "°C"
        fg: root.temp >= 80 ? Theme.red : root.temp >= 70 ? Theme.yellow : Theme.text
        blink: root.temp >= 80
    }
}
