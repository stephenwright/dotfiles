import QtQuick

PanelButton {
    id: root

    property bool checked: false
    signal toggled()

    Accessible.role: Accessible.CheckBox
    Accessible.checkable: true
    Accessible.checked: checked
    Accessible.onToggleAction: root.toggled()
    onClicked: toggled()
}
