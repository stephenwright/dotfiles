import QtQuick
import "../services"

// dim label with a hairline to the right; children are trailing controls
Item {
    id: root

    property string text
    default property alias trailing: trailingRow.data

    width: parent ? parent.width : 0
    height: 16

    BarText {
        id: label
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.text
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    Rectangle {
        anchors.left: label.right
        anchors.leftMargin: 8
        anchors.right: trailingRow.left
        anchors.rightMargin: trailingRow.width > 0 ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        height: 1
        color: Theme.surface0
    }

    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 8
    }
}
