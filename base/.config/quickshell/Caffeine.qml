import QtQuick
import Quickshell
import Quickshell.Wayland

BarWidget {
    id: root

    property bool on: false

    text: on ? "󰅶" : "󰛊"
    fg: on ? Theme.green : "#ffffff"
    hoverBg: Qt.alpha(Theme.yellow, 0.2)

    onClicked: on = !on

    IdleInhibitor {
        window: root.QsWindow.window
        enabled: root.on
    }
}
