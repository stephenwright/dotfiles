import QtQuick
import Quickshell.Hyprland
import "../lib"
import "../services"

Row {
    height: parent.height
    spacing: 4

    Repeater {
        model: Hyprland.workspaces

        MouseArea {
            id: ws
            required property var modelData

            // hide special workspaces (negative ids)
            visible: modelData.id > 0
            width: visible ? wsLabel.implicitWidth + 16 : 0
            height: parent ? parent.height : 0
            hoverEnabled: true

            onClicked: Hypr.dispatch("workspace " + modelData.id,
                                     "hl.dsp.focus({workspace = " + modelData.id + "})")

            Rectangle {
                anchors.fill: parent
                color: ws.modelData.active ? Qt.alpha(Theme.mauve, 0.2)
                     : ws.containsMouse ? Qt.alpha(Theme.sapphire, 0.1)
                     : "transparent"
            }
            Rectangle {
                anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                height: 3
                color: ws.modelData.active ? Theme.mauve
                     : ws.containsMouse ? Theme.sapphire
                     : "transparent"
            }
            BarText {
                id: wsLabel
                anchors.centerIn: parent
                text: ws.modelData.name
                color: ws.modelData.active ? Theme.mauve
                     : ws.containsMouse ? Theme.sapphire
                     : Theme.text
            }
        }
    }
}
