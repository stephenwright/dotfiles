import QtQuick
import "../services"

// bare switch, for headers; full-width labelled toggles use ToggleRow
PanelToggle {
    id: root

    property color onColor: Theme.mauve

    width: 30
    height: 14

    SwitchIndicator {
        anchors.fill: parent
        on: root.checked
        onColor: root.onColor
    }
}
