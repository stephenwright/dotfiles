import QtQuick
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "session"
    panelWidth: 200
    contentSpacing: 4

    // destructive rows arm on the first click/enter and run on the second
    property var armed: null

    onOpening: {
        armed = null
        initialFocusItem = actionsRepeater.itemAt(0)
    }

    readonly property var actions: [
        { icon: "󰌾", label: "lock", confirm: false, run: () => Session.lock() },
        { icon: "󰒲", label: "sleep", confirm: false, run: () => Session.suspend() },
        { icon: "󰍃", label: "logout", confirm: true, run: () => Session.logout() },
        { icon: "󰜉", label: "restart", confirm: true, run: () => Session.reboot() },
        { icon: "󰐥", label: "shutdown", confirm: true, run: () => Session.shutdown() },
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

    Timer {
        id: disarm
        interval: 3000
        onTriggered: root.armed = null
    }

    Repeater {
        id: actionsRepeater
        model: root.actions

        PanelButton {
            id: row
            required property var modelData
            required property int index

            readonly property bool isArmed: root.armed === modelData.label

            width: parent.width
            height: 28
            accessibleName: modelData.label
            backgroundColor: isArmed ? Qt.alpha(Theme.red, 0.25) : "transparent"
            onClicked: root.trigger(modelData)
            onKeyPressed: event => {
                if (event.key === Qt.Key_J || event.key === Qt.Key_K) {
                    PanelManager.focusNext(row, event.key === Qt.Key_J)
                    event.accepted = true
                }
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: row.modelData.icon + "  " + row.modelData.label
                color: row.isArmed ? Theme.red
                     : row.showFocus ? Theme.mauve
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
