import QtQuick
import Quickshell.Services.UPower
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    // isLaptopBattery also filters out peripheral batteries (e.g. Logitech hidpp);
    // on machines with no laptop battery the widget hides itself entirely
    readonly property var bat: UPower.devices.values.find(d =>
        d.ready && d.isPresent && d.isLaptopBattery) ?? null
    visible: bat !== null

    readonly property int pct: bat ? Math.round(bat.percentage * 100) : 0
    readonly property bool charging: bat && bat.state === UPowerDeviceState.Charging
    readonly property bool plugged: !UPower.onBattery

    readonly property var icons: ["󰁺", "󰁻", "󰁼", "󰁽", "󰁾", "󰁿", "󰂀", "󰂁", "󰂂", "󰁹"]
    readonly property string icon: charging ? "󰂄"
        : plugged ? "󰚥"
        : icons[Math.min(9, Math.floor(pct / 10))]

    text: icon
    fg: !plugged && pct <= 15 ? Theme.red
        : !plugged && pct <= 30 ? Theme.yellow
        : Theme.text
    blink: !plugged && pct <= 15

    onClicked: panel.toggle()

    BatteryPanel {
        id: panel
        anchorItem: root
    }
}
