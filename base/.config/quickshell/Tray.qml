import QtQuick
import Quickshell
import Quickshell.Services.SystemTray
import Quickshell.Widgets

Row {
    height: parent.height
    spacing: 8

    Repeater {
        model: SystemTray.items

        MouseArea {
            id: trayItem
            required property var modelData

            width: 20
            height: parent ? parent.height : 0
            acceptedButtons: Qt.LeftButton | Qt.RightButton

            IconImage {
                anchors.centerIn: parent
                implicitSize: 16
                source: trayItem.modelData.icon
            }

            onClicked: event => {
                if (event.button === Qt.LeftButton && !trayItem.modelData.onlyMenu) {
                    trayItem.modelData.activate()
                } else if (trayItem.modelData.hasMenu) {
                    const pos = trayItem.mapToItem(null, 0, trayItem.height)
                    menuAnchor.anchor.rect.x = pos.x
                    menuAnchor.anchor.rect.y = pos.y
                    menuAnchor.open()
                }
            }

            QsMenuAnchor {
                id: menuAnchor
                menu: trayItem.modelData.menu
                anchor.window: trayItem.QsWindow.window
            }
        }
    }
}
