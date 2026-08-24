import QtQuick
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "session"
    panelWidth: 200
    contentSpacing: 4
    wantsKeyboard: true

    // destructive rows arm on the first click/enter and run on the second
    property var armed: null
    property int selected: 0

    onOpening: {
        armed = null
        selected = 0
    }

    readonly property var actions: [
        { icon: "󰌾", label: "lock", confirm: false, run: () => Session.lock() },
        { icon: "󰒲", label: "sleep", confirm: false, run: () => Session.suspend() },
        { icon: "󰍃", label: "logout", confirm: true, run: () => Session.logout() },
        { icon: "󰜉", label: "restart", confirm: true, run: () => Session.reboot() },
        { icon: "󰐥", label: "shutdown", confirm: true, run: () => Session.shutdown() }
    ]

    function trigger(a) {
        if (!a.confirm || armed === a.label) {
            armed = null
            close()
            a.run()
        } else {
            armed = a.label
            disarm.restart()
        }
    }

    onKeyPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_J)
            selected = Math.min(selected + 1, actions.length - 1)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
            selected = Math.max(selected - 1, 0)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            trigger(actions[selected])
        else
            return
        event.accepted = true
    }

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = null
    }

    Repeater {
        model: root.actions

        MouseArea {
            id: row
            required property var modelData
            required property int index

            readonly property bool isArmed: root.armed === modelData.label
            readonly property bool isSelected: root.selected === index

            width: parent.width
            height: 28
            hoverEnabled: true
            onEntered: root.selected = index
            onClicked: root.trigger(modelData)

            Rectangle {
                anchors.fill: parent
                color: row.isArmed ? Qt.alpha(Theme.red, 0.25)
                     : row.isSelected ? Qt.alpha(Theme.surface0, 0.7)
                     : "transparent"
            }
            Rectangle {
                width: 3
                height: parent.height
                color: row.isSelected && !row.isArmed ? Theme.mauve : "transparent"
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: row.modelData.icon + "  " + row.modelData.label
                color: row.isArmed ? Theme.red
                     : row.isSelected ? Theme.mauve
                     : Theme.text
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 6
                visible: row.isArmed
                text: "again to confirm"
                font.pixelSize: Theme.fontSizeHint
                color: Theme.red
            }
        }
    }
}
