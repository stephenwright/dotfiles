import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"

// Base for bar-anchored panels: chrome, positioning, and dismissal.
// Children declared in instances land in the inner content Column.
// Open/close always goes through PanelManager so only one panel is up.
PanelWindow {
    id: root

    property Item anchorItem
    property string panelName: "panel"
    property int panelWidth: 300
    property int contentSpacing: 10
    property bool wantsKeyboard: false
    default property alias contentData: content.data
    readonly property real contentWidth: content.width

    // per-panel refresh hook; runs just before the panel becomes visible
    signal opening()

    // key events not handled by the base (Escape closes); only fires
    // when wantsKeyboard is set
    signal keyPressed(var event)

    visible: false
    implicitWidth: panelWidth
    implicitHeight: content.implicitHeight + Theme.panelPadding * 2 + 4
    color: "transparent"

    anchors {
        top: true
        left: true
    }
    margins.top: Theme.panelMargin
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: root.panelName
    // OnDemand, not Exclusive: an exclusive-keyboard layer pins focus to itself,
    // which keeps HyprlandFocusGrab from ever clearing on outside clicks
    WlrLayershell.keyboardFocus: wantsKeyboard && visible
        ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Component.onCompleted: PanelManager.register(panelName, root)

    function toggle() {
        PanelManager.toggle(root)
    }

    function close() {
        PanelManager.close(root)
    }

    // PanelManager only: center over anchorItem, clamped to the screen
    function openAt() {
        const win = anchorItem.QsWindow.window
        screen = win.screen
        const r = anchorItem.mapToItem(null, 0, 0)
        const x = r.x + anchorItem.width / 2 - implicitWidth / 2
        margins.left = Math.round(Math.max(Theme.panelMargin,
            Math.min(x, screen.width - implicitWidth - Theme.panelMargin)))
        opening()
        visible = true
        if (wantsKeyboard)
            scope.forceActiveFocus()
    }

    HyprlandFocusGrab {
        // wait for the surface to be mapped, or the grab registers nothing;
        // the bar window is included so a click on another widget reaches it
        // and switches panels in one click instead of just clearing the grab
        active: root.visible && root.backingWindowVisible
        windows: root.anchorItem ? [root, root.anchorItem.QsWindow.window] : [root]
        onCleared: PanelManager.dismissed(root)
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        border.color: Theme.mauve
        border.width: 2

        FocusScope {
            id: scope
            anchors.fill: parent
            focus: true

            Keys.onPressed: event => {
                if (event.key === Qt.Key_Escape) {
                    PanelManager.close(root)
                    event.accepted = true
                } else {
                    root.keyPressed(event)
                }
            }

            Column {
                id: content
                anchors.fill: parent
                anchors.margins: Theme.panelPadding
                spacing: root.contentSpacing
            }
        }
    }
}
