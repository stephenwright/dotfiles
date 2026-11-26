import QtQuick
import "../services"

MouseArea {
    id: root

    property alias text: label.text
    property color fg: Theme.text
    property color hoverBg: Qt.rgba(1, 1, 1, 0.08)
    property bool blink: false
    // its panel is open: styled like the active workspace
    property bool active: false
    property int fontSize: 20

    signal scrolledUp()
    signal scrolledDown()

    height: parent ? parent.height : implicitHeight
    implicitWidth: label.implicitWidth + Theme.widgetPadding * 2
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    Rectangle {
        anchors.fill: parent
        color: root.active ? Qt.alpha(Theme.mauve, 0.2)
             : root.containsMouse ? root.hoverBg
             : "transparent"
    }
    Rectangle {
        visible: root.active
        anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
        height: 3
        color: Theme.mauve
    }

    BarText {
        id: label
        anchors.centerIn: parent
        color: root.active ? Theme.mauve : root.fg
        font.pixelSize: parent.fontSize
    }

    // accumulate to full 120-unit notches; hi-res wheels/touchpads send many small events,
    // and some touchpads report only pixelDelta
    property real wheelAcc: 0
    onWheel: event => {
        wheelAcc += event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y * 2.5
        while (wheelAcc >= 120) {
            wheelAcc -= 120
            root.scrolledUp()
        }
        while (wheelAcc <= -120) {
            wheelAcc += 120
            root.scrolledDown()
        }
    }

    SequentialAnimation {
        running: root.blink
        loops: Animation.Infinite
        NumberAnimation { target: label; property: "opacity"; to: 0.2; duration: 500 }
        NumberAnimation { target: label; property: "opacity"; to: 1.0; duration: 500 }
    }
    onBlinkChanged: if (!blink) label.opacity = 1
}
