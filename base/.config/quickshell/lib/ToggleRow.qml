import QtQuick
import "../services"

PanelToggle {
    id: root

    property string icon
    property string label
    property color onColor: Theme.mauve

    width: parent ? parent.width : 0
    height: 26
    accessibleName: label

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.leftMargin: 4
        text: (root.icon ? root.icon + "  " : "") + root.label
        color: root.showFocus ? Theme.mauve : Theme.text
    }

    SwitchIndicator {
        anchors.verticalCenter: parent.verticalCenter
        anchors.right: parent.right
        anchors.rightMargin: 4
        on: root.checked
        onColor: root.onColor
    }
}
