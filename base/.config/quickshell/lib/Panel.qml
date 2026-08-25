import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland
import "../services"

// Base for bar-anchored panels: chrome, positioning, focus, and dismissal.
// Children declared in instances land in the inner content Column.
// Open/close always goes through PanelManager so only one panel is up.
PanelWindow {
    id: root

    property Item anchorItem
    property string panelName: "panel"
    property int panelWidth: 300
    property int contentSpacing: 10
    property Item initialFocusItem: null
    default property alias contentData: content.data
    readonly property real contentWidth: content.width

    // per-panel refresh hook; runs just before the panel becomes visible
    signal opening()

    // key events not handled by the base
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
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    Component.onCompleted: PanelManager.register(panelName, root)
    Component.onDestruction: PanelManager.unregister(panelName, root)

    function toggle() {
        PanelManager.toggle(root)
    }

    function close() {
        PanelManager.close(root)
    }

    function managedOpen() {
        const win = anchorItem.QsWindow.window
        screen = win.screen
        const r = anchorItem.mapToItem(null, 0, 0)
        const x = r.x + anchorItem.width / 2 - implicitWidth / 2
        margins.left = Math.round(Math.max(Theme.panelMargin,
            Math.min(x, screen.width - implicitWidth - Theme.panelMargin)))
        opening()
        visible = true
        Qt.callLater(() => {
            const target = root.initialFocusItem
            if (target && target.visible && target.enabled)
                target.forceActiveFocus(Qt.TabFocusReason)
            else
                scope.forceActiveFocus(Qt.TabFocusReason)
        })
    }

    function managedClose() {
        visible = false
    }

    HyprlandFocusGrab {
        // wait for the surface to be mapped, or the grab registers nothing;
        // the bar window is included so a click on another widget reaches it
        // and switches panels in one click instead of just clearing the grab
        active: root.visible && root.backingWindowVisible
        windows: PanelManager.grabWindows(root)
        onCleared: PanelManager.dismissed(root)
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.close()
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
                PanelManager.keyboardMode = true
                root.keyPressed(event)
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
