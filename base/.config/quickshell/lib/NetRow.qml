import QtQuick
import "../services"

MouseArea {
    id: netRow

    required property var modelData
    property var panel

    width: parent.width
    height: 26
    hoverEnabled: true
    onClicked: panel.activate(modelData)

    Rectangle {
        anchors.fill: parent
        color: netRow.containsMouse ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
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
        font.pixelSize: 10
        text: netRow.modelData.connected ? "✓"
            : netRow.modelData.stateChanging ? "…" : ""
        color: netRow.modelData.connected ? Theme.green
             : netRow.modelData.stateChanging ? Theme.yellow
             : Theme.overlay0
    }
}
