import QtQuick
import "../services"

// footer row of keyboard hints: [{ key: "x", action: "dismiss" }, ...]
Item {
    id: root

    property var hints: []
    property int inset: 0

    width: parent ? parent.width : 0
    height: 20

    Rectangle {
        width: parent.width
        height: 1
        color: Theme.surface0
    }

    Row {
        id: row
        x: root.inset
        y: 1 + Math.round((root.height - 1 - row.height) / 2)
        spacing: 14

        Repeater {
            model: root.hints

            Row {
                required property var modelData
                spacing: 5

                BarText {
                    text: modelData.key
                    font.pixelSize: Theme.fontSizeHint
                    color: Theme.subtext0
                }
                BarText {
                    text: modelData.action
                    font.pixelSize: Theme.fontSizeHint
                    color: Theme.overlay0
                }
            }
        }
    }
}
