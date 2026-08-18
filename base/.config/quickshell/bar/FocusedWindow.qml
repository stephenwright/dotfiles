import QtQuick
import Quickshell.Hyprland
import Quickshell.Wayland
import "../lib"
import "../services"

Row {
    id: root
    height: parent.height
    spacing: 8

    readonly property var activeWin: ToplevelManager.activeToplevel

    MouseArea {
        id: closeBtn
        visible: root.activeWin != null
        width: visible ? closeLabel.implicitWidth + 16 : 0
        height: parent.height
        hoverEnabled: true
        acceptedButtons: Qt.LeftButton | Qt.MiddleButton

        onClicked: event => {
            if (event.button === Qt.MiddleButton)
                Hyprland.dispatch("forcekillactive")
            else
                root.activeWin?.close()
        }

        Rectangle {
            anchors.fill: parent
            color: closeBtn.containsMouse ? Qt.alpha(Theme.red, 0.3) : "transparent"
        }
        Rectangle {
            anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
            height: 3
            color: closeBtn.containsMouse ? Theme.red : "transparent"
        }
        BarText {
            id: closeLabel
            anchors.centerIn: parent
            text: "x"
            font.bold: true
            color: closeBtn.containsMouse ? "#ffffff" : Theme.red
        }
    }

    BarText {
        anchors.verticalCenter: parent.verticalCenter
        text: root.activeWin?.title ?? ""
        elide: Text.ElideRight
        width: Math.min(implicitWidth, 560)
    }
}
