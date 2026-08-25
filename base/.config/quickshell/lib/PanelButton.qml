import QtQuick
import "../services"

Item {
    id: root

    default property alias contentData: content.data
    property string accessibleName: ""
    property color backgroundColor: "transparent"
    property color hoverBackgroundColor: Qt.alpha(Theme.surface0, 0.7)
    property color focusBackgroundColor: hoverBackgroundColor
    property color borderColor: "transparent"
    property color focusBorderColor: Theme.mauve
    property bool horizontalNavigation: false
    readonly property bool hovered: pointer.containsMouse
    readonly property bool pressed: pointer.pressed
    readonly property bool showFocus: activeFocus && PanelManager.keyboardMode

    signal clicked()
    signal keyPressed(var event)

    activeFocusOnTab: visible && enabled
    Accessible.role: Accessible.Button
    Accessible.name: accessibleName
    Accessible.focusable: true
    Accessible.focused: activeFocus
    Accessible.pressed: pressed
    Accessible.onPressAction: root.clicked()

    Rectangle {
        anchors.fill: parent
        color: root.showFocus ? root.focusBackgroundColor
            : root.hovered ? root.hoverBackgroundColor
            : root.backgroundColor
        border.color: root.borderColor
        border.width: root.borderColor !== "transparent" ? 1 : 0
    }

    MouseArea {
        id: pointer
        anchors.fill: parent
        enabled: root.enabled
        hoverEnabled: true
        onPressed: {
            PanelManager.keyboardMode = false
            root.forceActiveFocus(Qt.MouseFocusReason)
        }
        onClicked: root.clicked()
    }

    Item {
        id: content
        anchors.fill: parent
    }

    Rectangle {
        z: 2
        anchors.fill: parent
        color: "transparent"
        border.color: root.focusBorderColor
        border.width: 1
        visible: root.showFocus
    }

    Keys.onPressed: event => {
        PanelManager.keyboardMode = true
        if (event.key === Qt.Key_Up || event.key === Qt.Key_Down) {
            PanelManager.focusNext(root, event.key === Qt.Key_Down)
            event.accepted = true
            return
        }
        if (root.horizontalNavigation
                && (event.key === Qt.Key_Left || event.key === Qt.Key_Right)) {
            PanelManager.focusHorizontal(root, event.key === Qt.Key_Right ? 1 : -1)
            event.accepted = true
            return
        }
        if (event.key !== Qt.Key_Return && event.key !== Qt.Key_Enter
                && event.key !== Qt.Key_Space) {
            root.keyPressed(event)
            return
        }
        root.clicked()
        event.accepted = true
    }
}
