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
    property bool keyboardMode: false
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
        keyboardMode = false
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
        keyboardMode = false
        if (closing)
            closing.managedClose()
    }

    function focusHorizontal(item, direction) {
        keyboardMode = true
        // within a row, step to the neighbour; never jump to another row
        const row = rowOf(item)
        if (row.length > 1) {
            const sorted = row.slice().sort((a, b) =>
                a.mapToGlobal(0, 0).x - b.mapToGlobal(0, 0).x)
            sorted[sorted.indexOf(item) + direction]?.forceActiveFocus(Qt.TabFocusReason)
            return
        }
        const origin = item.mapToGlobal(item.width / 2, item.height / 2)
        let candidate = item.nextItemInFocusChain(true)
        let best = null
        let bestScore = Infinity
        let count = 0

        while (candidate && candidate !== item && count++ < 512) {
            const point = candidate.mapToGlobal(candidate.width / 2, candidate.height / 2)
            const dx = point.x - origin.x
            const dy = point.y - origin.y
            const primary = dx * direction
            if (primary > 1) {
                const perpendicular = Math.abs(dy)
                const score = primary * 1000 + perpendicular
                if (score < bestScore) {
                    best = candidate
                    bestScore = score
                }
            }
            candidate = candidate.nextItemInFocusChain(true)
        }

        if (best)
            best.forceActiveFocus(Qt.TabFocusReason)
    }

    // Buttons with horizontalNavigation that share a parent form one row:
    // Up/Down skip the rest of the row and enter the next one at its active
    // choice (current / selected), or its first button.
    function rowOf(item) {
        if (!item?.horizontalNavigation || !item.parent)
            return []
        return item.parent.children.filter(c => c.horizontalNavigation && c.visible
            && c.enabled && c.activeFocusOnTab)
    }

    function focusNext(item, forward) {
        keyboardMode = true
        const row = rowOf(item)
        let next = item.nextItemInFocusChain(forward)
        for (let i = 0; next && next !== item && row.includes(next) && i < 512; i++)
            next = next.nextItemInFocusChain(forward)
        if (!next || next === item)
            return
        const target = rowOf(next)
        if (target.length)
            next = target.find(c => c.current === true || c.selected === true) ?? target[0]
        next.forceActiveFocus(Qt.TabFocusReason)
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
