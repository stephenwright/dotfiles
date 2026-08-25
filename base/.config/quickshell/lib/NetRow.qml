import QtQuick
import "../services"

PanelButton {
    id: netRow

    required property var modelData
    property var panel

    width: parent.width
    height: 26
    enabled: !modelData.connected && !modelData.stateChanging
    accessibleName: "Connect to " + modelData.name
    onClicked: panel.activate(modelData)
    Component.onDestruction: {
        if (activeFocus && panel)
            panel.recoverFocus()
    }
    BarText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        width: parent.width - 60
        elide: Text.ElideRight
        text: netRow.panel.sigIcon(netRow.modelData) + " " + netRow.modelData.name
            + (netRow.panel.secured(netRow.modelData) ? " 󰌾" : "")
        color: netRow.modelData.connected ? Theme.green : Theme.text
    }
    BarText {
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
