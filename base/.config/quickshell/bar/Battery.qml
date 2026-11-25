import QtQuick
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    // on machines with no laptop battery the widget hides itself entirely
    readonly property var bat: Power.bat
    visible: bat !== null

    readonly property int pct: Power.pct
    readonly property bool charging: Power.charging
    readonly property bool plugged: Power.plugged

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
