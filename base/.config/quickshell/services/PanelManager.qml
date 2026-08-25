pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Coordinates managed panels: at most one open, single-click switching,
// outside-click dismissal, and keybind access via IPC.
Singleton {
    id: root

    property var current: null
    property var registry: ({})
    property var barWindows: []
    readonly property var workspaceEvents: [
        "workspace",
        "workspacev2",
        "activespecial",
        "activespecialv2",
    ]

    function register(name, panel) {
        const next = Object.assign({}, registry)
        const panels = (next[name] ?? []).filter(p => p !== panel)
        panels.push(panel)
        next[name] = panels
        registry = next
    }

    function unregister(name, panel) {
        if (current === panel) {
            current = null
            panel.managedClose()
        }
        const next = Object.assign({}, registry)
        const panels = (next[name] ?? []).filter(p => p !== panel)
        if (panels.length)
            next[name] = panels
        else
            delete next[name]
        registry = next
    }

    function registerBar(bar) {
        barWindows = barWindows.filter(w => w !== bar).concat([bar])
    }

    function unregisterBar(bar) {
        barWindows = barWindows.filter(w => w !== bar)
    }

    function grabWindows(panel) {
        return [panel].concat(barWindows)
    }

    function toggle(panel) {
        if (current === panel) {
            close()
            return
        }
        close()
        current = panel
        panel.managedOpen()
    }

    function close(panel) {
        if (panel && panel !== current) {
            panel.managedClose()
            return
        }
        const closing = current
        current = null
        if (closing)
            closing.managedClose()
    }

    function dismissed(panel) {
        close(panel)
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

    Connections {
        target: Hyprland

        function onRawEvent(event) {
            if (root.workspaceEvents.includes(event.name))
                root.close()
        }
    }

    IpcHandler {
        target: "panels"
        function toggle(name: string): void {
            root.toggleByName(name)
        }
    }
}
