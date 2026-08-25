import QtQuick
import "../services"

Item {
    id: root

    property real value: 0
    property real stepSize: 0.05
    property real pageStep: 0.1
    property string accessibleName: ""
    signal moved(real value)

    height: 20
    activeFocusOnTab: visible && enabled
    Accessible.role: Accessible.Slider
    Accessible.name: accessibleName
    Accessible.description: Math.round(clamp(value) * 100) + "%"
    Accessible.focusable: true
    Accessible.focused: activeFocus
    Accessible.onIncreaseAction: moveTo(value + stepSize)
    Accessible.onDecreaseAction: moveTo(value - stepSize)

    function clamp(v) {
        return Math.max(0, Math.min(1, v))
    }

    function moveTo(v) {
        moved(clamp(v))
    }

    Rectangle {
        anchors.fill: parent
        color: "transparent"
        border.color: root.activeFocus && PanelManager.keyboardMode
            ? Theme.mauve : "transparent"
        border.width: root.activeFocus && PanelManager.keyboardMode ? 1 : 0
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        anchors.left: parent.left
        anchors.right: parent.right
        anchors.leftMargin: 2
        anchors.rightMargin: 2
        height: 4
        color: Theme.surface1

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            color: Theme.mauve
        }
    }

    Rectangle {
        x: 2 + (parent.width - width - 4) * root.clamp(root.value)
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        color: root.activeFocus && PanelManager.keyboardMode ? Theme.mauve : Theme.text
    }

    MouseArea {
        anchors.fill: parent
        onPressed: event => {
            PanelManager.keyboardMode = false
            root.forceActiveFocus(Qt.MouseFocusReason)
            root.moveTo(event.x / width)
        }
        onPositionChanged: event => {
            if (pressed)
                root.moveTo(event.x / width)
        }
        property real wheelAcc: 0
        onWheel: event => {
            PanelManager.keyboardMode = false
            wheelAcc += event.angleDelta.y
            const steps = Math.trunc(wheelAcc / 120)
            if (steps !== 0) {
                wheelAcc -= steps * 120
                root.moveTo(root.value + steps * root.stepSize)
            }
        }
    }

    Keys.onPressed: event => {
        PanelManager.keyboardMode = true
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down)
            PanelManager.focusNext(root, event.key === Qt.Key_Down)
        else if (event.key === Qt.Key_Left)
            moveTo(value - stepSize)
        else if (event.key === Qt.Key_Right)
            moveTo(value + stepSize)
        else if (event.key === Qt.Key_PageDown)
            moveTo(value - pageStep)
        else if (event.key === Qt.Key_PageUp)
            moveTo(value + pageStep)
        else if (event.key === Qt.Key_Home)
            moveTo(0)
        else if (event.key === Qt.Key_End)
            moveTo(1)
        else
            return
        event.accepted = true
    }
}
