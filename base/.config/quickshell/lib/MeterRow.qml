import QtQuick
import "../services"

// labeled progress bar: "label ......... detail" over a thin fill
Column {
    property string label
    property string detail
    property real frac
    property color barColor: Theme.mauve

    width: parent.width
    spacing: 3

    Item {
        width: parent.width
        height: 14

        BarText {
            anchors.left: parent.left
            text: label
            font.pixelSize: 11
            color: Theme.subtext0
        }
        BarText {
            anchors.right: parent.right
            text: detail
            font.pixelSize: 11
            color: Theme.text
        }
    }
    Rectangle {
        width: parent.width
        height: 4
        color: Theme.surface1

        Rectangle {
            width: parent.width * Math.max(0, Math.min(1, frac))
            height: parent.height
            color: barColor
        }
    }
}
