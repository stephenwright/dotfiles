pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// CPU, memory and temperature read straight from /proc and sysfs (no
// subprocesses); disk usage via df on a slow timer. One poller for all bars.
Singleton {
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

    property var prevCpu: null
    property string tempPath: ""

    function gb(kb) {
        return (kb / 1048576).toFixed(1) + "G"
    }

    FileView {
        id: stat
        path: "/proc/stat"
    }
    FileView {
        id: meminfo
        path: "/proc/meminfo"
    }
    FileView {
        id: tempFile
        path: root.tempPath
        printErrors: false
    }

    // hwmon numbering isn't stable across boots; resolve the acpitz sensor once
    Process {
        running: true
        command: ["sh", "-c",
            "for h in /sys/class/hwmon/*; do "
            + "[ \"$(cat $h/name 2>/dev/null)\" = acpitz ] && echo $h/temp1_input && break; done"]
        stdout: StdioCollector {
            onStreamFinished: root.tempPath = this.text.trim()
        }
    }

    Process {
        id: df
        command: ["df", "-k", "--output=used,size,avail", "/"]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split("\n").pop().trim().split(/\s+/)
                root.diskUsed = parseInt(p[0]) || 0
                root.diskSize = parseInt(p[1]) || 0
                root.diskAvail = parseInt(p[2]) || 0
            }
        }
    }

    Timer {
        interval: PanelManager.current?.panelName === "system" ? 1000 : 2000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: root.sample()
    }

    Timer {
        interval: 60000
        running: true
        repeat: true
        triggeredOnStart: true
        onTriggered: if (!df.running) df.running = true
    }

    function sample() {
        stat.reload()
        meminfo.reload()

        const m = meminfo.text()
        const kb = key => Number(m.match(new RegExp("^" + key + ":\\s+(\\d+)", "m"))?.[1] ?? 0)
        memTot = kb("MemTotal")
        memAvail = kb("MemAvailable")
        swapTot = kb("SwapTotal")
        swapFree = kb("SwapFree")

        // user nice system idle iowait irq softirq steal (guest is already in user)
        const f = stat.text().match(/^cpu\s+(.*)$/m)?.[1].trim().split(/\s+/).slice(0, 8).map(Number)
        if (f) {
            const idle = f[3] + f[4]
            const total = f.reduce((a, b) => a + b, 0)
            if (prevCpu) {
                const dt = total - prevCpu.total
                cpu = dt > 0 ? Math.round(100 * (1 - (idle - prevCpu.idle) / dt)) : 0
            }
            prevCpu = { total, idle }
        }

        if (tempPath) {
            tempFile.reload()
            temp = Math.round(Number(tempFile.text().trim()) / 1000) || 0
        }
    }
}
