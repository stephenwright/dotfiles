import QtQuick
import "../lib"
import "../services"

BarWidget {
    text: "󰀻"
    fg: Theme.mauve
    hoverBg: Qt.alpha(Theme.mauve, 0.2)

    onClicked: PanelManager.toggleByName("launcher")
}
