import QtQuick
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    text: "⏻"
    fg: Theme.red
    hoverBg: Qt.alpha(Theme.red, 0.2)

    active: panel.visible

    onClicked: panel.toggle()

    SessionPanel {
        id: panel
        anchorItem: root
    }
}
