import QtQuick

Item {
    id: root

    property real value: 0
    signal moved(real value)

    height: 20

    function clamp(v) {
        return Math.max(0, Math.min(1, v))
    }

    Rectangle {
        anchors.verticalCenter: parent.verticalCenter
        width: parent.width
        height: 4
        color: Theme.surface1

        Rectangle {
            width: parent.width * root.clamp(root.value)
            height: parent.height
            color: Theme.mauve
        }
    }

    Rectangle {
        x: (parent.width - width) * root.clamp(root.value)
        anchors.verticalCenter: parent.verticalCenter
        width: 10
        height: 10
        color: Theme.text
    }

    MouseArea {
        anchors.fill: parent
        onPressed: event => root.moved(root.clamp(event.x / width))
        onPositionChanged: event => {
            if (pressed)
                root.moved(root.clamp(event.x / width))
        }
        property real wheelAcc: 0
        onWheel: event => {
            wheelAcc += event.angleDelta.y
            const steps = Math.trunc(wheelAcc / 120)
            if (steps !== 0) {
                wheelAcc -= steps * 120
                root.moved(root.clamp(root.value + steps * 0.05))
            }
        }
    }
}
