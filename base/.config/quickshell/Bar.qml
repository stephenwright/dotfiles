import QtQuick
import Quickshell

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
            spacing: 4

            Workspaces {}
            FocusedWindow {}
        }

        ClockWidget {
            anchors.centerIn: parent
        }

        Row {
            anchors.right: parent.right
            height: parent.height
            spacing: 4

            Tray {}
            SysInfo {}
            Backlight {}
            Battery {}
            NetworkStatus {}
            Audio {}
            Capture {}
            NotifyBell {}
            Caffeine {}
            PowerButton {}
        }
    }
}
