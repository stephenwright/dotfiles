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
        enabled: !netRow.modelData.connected && !netRow.modelData.stateChanging
        accessibleName: "Connect to " + netRow.modelData.name
        onClicked: netRow.panel.activate(netRow.modelData)

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            anchors.right: status.left
            anchors.rightMargin: 4
            elide: Text.ElideRight
            text: netRow.panel.sigIcon(netRow.modelData) + " " + netRow.modelData.name
                + (netRow.panel.secured(netRow.modelData) ? " 󰌾" : "")
            color: netRow.modelData.connected ? Theme.green : Theme.text
        }
        BarText {
            id: status
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4
            font.pixelSize: Theme.fontSizeHint
            text: netRow.modelData.connected ? "✓"
                : netRow.modelData.stateChanging ? "…" : ""
            color: netRow.modelData.connected ? Theme.green
                 : netRow.modelData.stateChanging ? Theme.yellow
                 : Theme.overlay0
        }
    }

    PanelButton {
        id: forgetBtn
        visible: netRow.modelData.known
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
