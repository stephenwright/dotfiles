import QtQuick
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    readonly property int count: Notifs.tracked.values.length

    text: Notifs.dnd ? "" : count > 0 ? "󱅫" : ""
    fg: Notifs.dnd ? Theme.red : Theme.sapphire

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            PanelManager.close()
            Notifs.toggleDnd()
        } else {
            panel.toggle()
        }
    }

    // notifications arrived while DND is on
    Rectangle {
        visible: Notifs.dnd && Notifs.missedWhileDnd > 0
        width: 7
        height: 7
        radius: 3.5
        anchors.top: parent.top
        anchors.right: parent.right
        anchors.topMargin: 4
        anchors.rightMargin: 3
        color: Theme.red
        border.color: Theme.base
        border.width: 1
    }

    NotifyPanel {
        id: panel
        anchorItem: root
    }
}
