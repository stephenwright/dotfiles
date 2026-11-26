import QtQuick
import "../services"

// on/off switch visual; input comes from the enclosing PanelToggle
Rectangle {
    id: root

    property bool on: false
    property color onColor: Theme.mauve

    implicitWidth: 30
    implicitHeight: 14
    color: on ? Qt.alpha(onColor, 0.4) : Theme.surface1

    Rectangle {
        width: 10
        height: 10
        anchors.verticalCenter: parent.verticalCenter
        x: root.on ? parent.width - width - 2 : 2
        color: root.on ? root.onColor : Theme.overlay0
    }
}
