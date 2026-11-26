import QtQuick
import "../services"

// one of a row of short fixed choices (profiles, formats)
PanelButton {
    id: root

    property bool current: false
    property string label

    height: 26
    accessibleName: label
    horizontalNavigation: true
    backgroundColor: current ? Qt.alpha(Theme.mauve, 0.25) : "transparent"
    borderColor: current ? Theme.mauve : Theme.surface1

    BarText {
        anchors.centerIn: parent
        text: root.label
        color: root.current || root.hovered || root.showFocus ? Theme.mauve : Theme.text
    }
}
