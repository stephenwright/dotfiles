import QtQuick
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    readonly property int count: Notifs.tracked.values.length

    text: Notifs.dnd ? "" : count > 0 ? "󱅫" : "󰂚"
    fg: Notifs.dnd ? Theme.red : Theme.sapphire

    onClicked: event => {
        if (event.button === Qt.RightButton)
            Notifs.toggleDnd()
        else
            panel.toggle()
    }

    NotifyPanel {
        id: panel
        anchorItem: root
    }
}
