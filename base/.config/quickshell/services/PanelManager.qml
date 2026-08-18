pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Coordinates bar-anchored panels: at most one open, single-click switching,
// and keybind access via `qs ipc call panels toggle <name>`.
Singleton {
    id: root

    property var open: null
    readonly property var registry: ({})   // panelName -> [instance per screen]

    function register(name, panel) {
        if (!registry[name])
            registry[name] = []
        registry[name].push(panel)
    }

    function toggle(p) {
        if (open === p) {
            close()
            return
        }
        if (open)
            open.visible = false
        p.openAt()
        open = p
    }

    function close(p) {
        if (p && p !== open) {
            p.visible = false
            return
        }
        if (open)
            open.visible = false
        open = null
    }

    // focus grab cleared by a click outside the panel and its bar
    function dismissed(p) {
        if (open === p)
            open = null
        p.visible = false
    }

    function toggleByName(name) {
        const list = registry[name] ?? []
        if (!list.length)
            return
        const mon = Hyprland.focusedMonitor
        const p = list.find(x => mon && x.anchorItem
            && x.anchorItem.QsWindow.window.screen.name === mon.name) ?? list[0]
        toggle(p)
    }

    IpcHandler {
        target: "panels"
        function toggle(name: string): void {
            root.toggleByName(name)
        }
    }
}
