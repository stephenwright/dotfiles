import QtQuick
import "../services"

// list entry; the active one is marked like the launcher's selected row
PanelButton {
    id: root

    property bool selected: false
    property string icon
    property string label
    property string detail
    property color labelColor: Theme.text
    // room kept free on the right for a trailing button child
    property int trailingSpace: 0

    width: parent ? parent.width : 0
    height: 26
    accessibleName: label
    backgroundColor: selected ? Theme.surface0 : "transparent"

    Rectangle {
        visible: root.selected
        width: 2
        height: parent.height
        color: Theme.mauve
    }

    BarText {
        anchors.left: parent.left
        anchors.leftMargin: 8
        anchors.right: detailText.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: (root.icon ? root.icon + "  " : "") + root.label
        color: root.showFocus ? Theme.mauve : root.labelColor
    }

    BarText {
        id: detailText
        anchors.right: parent.right
        anchors.rightMargin: 8 + root.trailingSpace
        anchors.verticalCenter: parent.verticalCenter
        text: root.detail
        font.pixelSize: Theme.fontSizeHint
        color: Theme.overlay0
    }
}
