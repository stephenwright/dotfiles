import QtQuick
import Quickshell
import "../lib"
import "../services"

PanelWindow {
    id: root

    property var modelData
    screen: modelData

    anchors {
        top: true
        left: true
        right: true
    }
    implicitHeight: 30
    color: Theme.barBg

    Item {
        anchors.fill: parent

        Row {
            anchors.left: parent.left
            height: parent.height
            spacing: 10

            Workspaces { screen: root.screen }
            FocusedWindow {}
        }

        ClockWidget {
            anchors.centerIn: parent
        }

        Row {
            anchors.right: parent.right
            height: parent.height
            spacing: 8

            Tray { id: tray }
            Rectangle {
                visible: tray.count > 0
                width: 1
                height: 14
                anchors.verticalCenter: parent.verticalCenter
                color: Theme.surface1
            }
            SysInfo {}
            Backlight {}
            Battery {}
            NetworkStatus {}
            Audio {}
            Capture {}
            NotifyBell {}
            PowerButton {}
        }
    }
}
