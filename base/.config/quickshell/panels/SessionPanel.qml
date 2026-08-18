import QtQuick
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "session"
    panelWidth: 200
    contentSpacing: 4

    // destructive rows arm on the first click and run on the second
    property var armed: null

    onOpening: armed = null

    readonly property var actions: [
        { icon: "󰌾", label: "lock", confirm: false, run: () => Session.lock() },
        { icon: "󰒲", label: "sleep", confirm: false, run: () => Session.suspend() },
        { icon: "󰍃", label: "logout", confirm: true, run: () => Session.logout() },
        { icon: "󰜉", label: "restart", confirm: true, run: () => Session.reboot() },
        { icon: "󰐥", label: "shutdown", confirm: true, run: () => Session.shutdown() }
    ]

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

            readonly property bool isArmed: root.armed === modelData.label

            width: parent.width
            height: 28
            hoverEnabled: true
            onClicked: {
                if (!modelData.confirm || isArmed) {
                    root.armed = null
                    root.close()
                    modelData.run()
                } else {
                    root.armed = modelData.label
                    disarm.restart()
                }
            }

            Rectangle {
                anchors.fill: parent
                color: row.isArmed ? Qt.alpha(Theme.red, 0.25)
                     : row.containsMouse ? Qt.alpha(Theme.surface0, 0.7)
                     : "transparent"
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 6
                text: row.modelData.icon + "  " + row.modelData.label
                color: row.isArmed ? Theme.red : Theme.text
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.right: parent.right
                anchors.rightMargin: 6
                visible: row.isArmed
                text: "again to confirm"
                font.pixelSize: 10
                color: Theme.red
            }
        }
    }
}
