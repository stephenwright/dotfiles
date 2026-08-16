import QtQuick

MouseArea {
    id: root

    property alias text: label.text
    property color fg: Theme.text
    property color hoverBg: Qt.rgba(1, 1, 1, 0.08)
    property bool blink: false

    signal scrolledUp()
    signal scrolledDown()

    height: parent ? parent.height : implicitHeight
    implicitWidth: label.implicitWidth + Theme.padding * 2
    hoverEnabled: true
    acceptedButtons: Qt.LeftButton | Qt.RightButton | Qt.MiddleButton

    Rectangle {
        anchors.fill: parent
        color: root.containsMouse ? root.hoverBg : "transparent"
    }

    BarText {
        id: label
        anchors.centerIn: parent
        color: root.fg
    }

    // accumulate to full 120-unit notches; hi-res wheels/touchpads send many small events
    property real wheelAcc: 0
    onWheel: event => {
        wheelAcc += event.angleDelta.y
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
