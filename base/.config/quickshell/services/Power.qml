pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Services.UPower

// Laptop battery state plus low-battery notifications. Null battery (and
// no alerts) on machines without one.
Singleton {
    id: root

    // isLaptopBattery also filters out peripheral batteries (e.g. Logitech hidpp)
    readonly property var bat: UPower.devices.values.find(d =>
        d.ready && d.isPresent && d.isLaptopBattery) ?? null

    readonly property int pct: bat ? Math.round(bat.percentage * 100) : 0
    readonly property bool charging: bat !== null && bat.state === UPowerDeviceState.Charging
    readonly property bool plugged: !UPower.onBattery

    // each threshold alerts once per discharge; plugging in re-arms them
    readonly property var thresholds: [
        { pct: 5, urgency: "critical", title: "Battery critical" },
        { pct: 15, urgency: "normal", title: "Battery low" },
    ]
    property int alertedAt: 101

    onPctChanged: check()
    onPluggedChanged: check()
    onBatChanged: check()

    function check() {
        if (!bat || plugged) {
            alertedAt = 101
            return
        }
        const t = thresholds.find(t => pct <= t.pct)
        if (!t || t.pct >= alertedAt)
            return
        alertedAt = t.pct
        Quickshell.execDetached(["notify-send", "-a", "Battery", "-u", t.urgency,
            "-i", "battery-caution", t.title, pct + "% remaining — plug in soon"])
    }
}
