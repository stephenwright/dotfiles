import QtQuick
import "../services"

// first row of every anchored panel: icon, bold title, dim subtitle, and
// trailing controls (children; give them anchors.verticalCenter)
Item {
    id: root

    property string icon
    property string title
    property string subtitle
    property color iconColor: Theme.text
    default property alias trailing: trailingRow.data

    width: parent ? parent.width : 0
    height: 22

    BarText {
        id: iconText
        visible: root.icon !== ""
        width: visible ? implicitWidth : 0
        anchors.left: parent.left
        anchors.verticalCenter: parent.verticalCenter
        text: root.icon
        color: root.iconColor
    }

    BarText {
        id: titleText
        anchors.left: iconText.right
        anchors.leftMargin: root.icon !== "" ? 8 : 0
        anchors.verticalCenter: parent.verticalCenter
        text: root.title
        font.bold: true
    }

    BarText {
        anchors.left: titleText.right
        anchors.leftMargin: 8
        anchors.right: trailingRow.left
        anchors.rightMargin: 8
        anchors.verticalCenter: parent.verticalCenter
        elide: Text.ElideRight
        text: root.subtitle
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    Row {
        id: trailingRow
        anchors.right: parent.right
        anchors.verticalCenter: parent.verticalCenter
        height: parent.height
        spacing: 10
    }
}
