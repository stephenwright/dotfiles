import QtQuick
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    text: Caffeine.on ? "󱎴" : "󰍹"
    fg: Caffeine.on ? Theme.green : Theme.text

    onScrolledUp: Brightness.set("5%+")
    onScrolledDown: Brightness.set("5%-")
    active: panel.visible

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            PanelManager.close()
            Brightness.set("100%")
        } else {
            panel.toggle()
        }
    }

    DisplayPanel {
        id: panel
        anchorItem: root
    }
}
