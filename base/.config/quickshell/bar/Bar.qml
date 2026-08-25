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
    implicitHeight: Theme.barHeight
    color: Theme.barBg

    Component.onCompleted: PanelManager.registerBar(root)
    Component.onDestruction: PanelManager.unregisterBar(root)

    Item {
        anchors.fill: parent

        MouseArea {
            anchors.fill: parent
            onClicked: PanelManager.close()
        }

        Row {
            anchors.left: parent.left
            height: parent.height
            spacing: Theme.barSpacing

            LauncherButton {}
            Workspaces { screen: root.screen }
            FocusedWindow {}
        }

        ClockWidget {
            anchors.centerIn: parent
        }

        Row {
            anchors.right: parent.right
            height: parent.height
            spacing: Theme.barSpacing

            Tray { id: tray }
            Row {
                visible: tray.count > 0
                height: parent.height
                leftPadding: Theme.barSpacing
                rightPadding: Theme.barSpacing
                Rectangle {
                    width: 1
                    height: 14
                    anchors.verticalCenter: parent.verticalCenter
                    color: Theme.surface1
                }
            }
            Capture {}
            Display {}
            BluetoothStatus {}
            NetworkStatus {}
            NotifyBell {}
            SysInfo {}
            Battery {}
            Audio {}
            PowerButton {}
        }
    }
}
