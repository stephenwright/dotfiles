import QtQuick
import "../services"

Item {
    id: netRow

    required property var modelData
    property var panel

    width: parent.width
    height: 26

    Component.onDestruction: {
        if ((connectBtn.activeFocus || forgetBtn.activeFocus) && panel)
            panel.recoverFocus()
    }

    PanelButton {
        id: connectBtn
        anchors.left: parent.left
        anchors.right: forgetBtn.visible ? forgetBtn.left : parent.right
        height: parent.height
        accessibleName: "Connect to " + netRow.modelData.name
        backgroundColor: netRow.modelData.connected ? Theme.surface0 : "transparent"
        onClicked: netRow.panel.activate(netRow.modelData)
        onKeyPressed: event => {
            if ((event.key === Qt.Key_X || event.key === Qt.Key_Delete) && netRow.modelData.known) {
                netRow.panel.forget(netRow.modelData)
                event.accepted = true
            }
        }

        // connected network is marked like SelectRow
        Rectangle {
            visible: netRow.modelData.connected
            width: 2
            height: parent.height
            color: Theme.mauve
        }

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 8
            anchors.right: status.left
            anchors.rightMargin: 4
            elide: Text.ElideRight
            text: netRow.panel.sigIcon(netRow.modelData) + " " + netRow.modelData.name
                + (netRow.panel.secured(netRow.modelData) ? " 󰌾" : "")
            color: connectBtn.showFocus ? Theme.mauve : Theme.text
        }
        BarText {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 8
            font.pixelSize: Theme.fontSizeHint
            text: netRow.modelData.stateChanging ? "connecting…"
                : netRow.modelData.connected ? "connected" : ""
            color: Theme.overlay0
        }
    }

    PanelButton {
        id: forgetBtn
        visible: netRow.modelData.known
        // the row is the keyboard stop; x forgets from there
        activeFocusOnTab: false
        width: 22
        height: parent.height
        anchors.right: parent.right
        accessibleName: "Forget " + netRow.modelData.name
        onClicked: netRow.panel.forget(netRow.modelData)

        BarText {
            anchors.centerIn: parent
            text: "󰆴"
            font.pixelSize: Theme.fontSizeSmall
            color: forgetBtn.hovered || forgetBtn.showFocus ? Theme.red : Theme.overlay0
        }
    }
}
