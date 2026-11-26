pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// Outputs from `hyprctl monitors all` (includes disabled outputs and available
// modes, which HyprlandMonitor doesn't expose) and layout changes. Changes are
// applied at runtime and saved (mode, position, scale per output) to
// ~/.local/state/hypr/monitors.lua, which hyprland.lua loads after its own
// monitor rules. On/off and mirroring are never saved: a screen saved as off
// could leave a later boot with no display.
Singleton {
    id: root

    property var list: []
    // output -> { mode, position?, scale }, mirrored in monitors.lua
    property var saved: ({})
    readonly property string savedPath: Quickshell.statePath("monitors.json")
    readonly property var enabled: list.filter(m => !m.disabled)
    // fixed point for layout changes; the others are placed beside it
    readonly property var anchor: enabled.length
        ? enabled.reduce((a, m) => m.id < a.id ? m : a) : null

    signal identifyRequested()

    function refresh() {
        proc.running = true
    }

    function refreshSoon() {
        settle.restart()
    }

    function identify() {
        identifyRequested()
    }

    function find(name) {
        return list.find(m => m.name === name) ?? null
    }

    function isPlaced(m) {
        return !m.disabled && m.mirrorOf === "none"
    }

    function parseMode(mode) {
        const p = /^(\d+)x(\d+)@([\d.]+)/.exec(mode)
        return p ? { w: +p[1], h: +p[2], hz: +p[3] } : null
    }

    function modeOf(m) {
        return m.width + "x" + m.height + "@" + m.refreshRate.toFixed(2)
    }

    // size in layout coordinates for a given mode and scale
    function logical(m, mode, scale) {
        const p = parseMode(mode ?? modeOf(m)) ?? { w: m.width, h: m.height }
        const s = scale ?? m.scale
        const w = Math.round(p.w / s)
        const h = Math.round(p.h / s)
        return m.transform % 2 === 1 ? { w: h, h: w } : { w: w, h: h }
    }

    function sideOf(m, ref) {
        const a = logical(m)
        const b = logical(ref)
        if (m.x + a.w <= ref.x)
            return "left"
        if (m.x >= ref.x + b.w)
            return "right"
        if (m.y + a.h <= ref.y)
            return "above"
        if (m.y >= ref.y + b.h)
            return "below"
        return ""
    }

    function positionBeside(size, ref, refSize, side) {
        switch (side) {
        case "left":
            return { x: ref.x - size.w, y: ref.y + Math.round((refSize.h - size.h) / 2) }
        case "right":
            return { x: ref.x + refSize.w, y: ref.y + Math.round((refSize.h - size.h) / 2) }
        case "above":
            return { x: ref.x + Math.round((refSize.w - size.w) / 2), y: ref.y - size.h }
        case "below":
            return { x: ref.x + Math.round((refSize.w - size.w) / 2), y: ref.y + refSize.h }
        }
        return null
    }

    // c = { mode?, scale?, side? } for one placed output. The anchor is pinned
    // at 0,0 (the config may give it an auto position, which Hyprland would
    // recompute after every move) and every other placed output is re-placed on
    // its side, so a size change doesn't leave a gap or an overlap.
    function change(name, c) {
        const cur = anchor
        if (!cur)
            return
        const refMode = name === cur.name ? (c.mode ?? modeOf(cur)) : modeOf(cur)
        const refScale = name === cur.name ? (c.scale ?? cur.scale) : cur.scale
        const refSize = logical(cur, refMode, refScale)
        const ref = Object.assign({}, cur, { x: 0, y: 0 })
        const specs = [spec(cur, { mode: refMode, scale: refScale, position: "0x0" })]
        for (const m of enabled) {
            if (m === cur || !isPlaced(m))
                continue
            const own = m.name === name ? c : {}
            const mode = own.mode ?? modeOf(m)
            const scale = own.scale ?? m.scale
            const side = own.side ?? (sideOf(m, cur) || "right")
            const pos = positionBeside(logical(m, mode, scale), ref, refSize, side)
            specs.push(spec(m, {
                mode: mode,
                scale: scale,
                position: pos ? pos.x + "x" + pos.y : undefined,
            }))
        }
        send(specs)
        save(specs)
        settle.restart()
    }

    // While a connected output is off, the anchor may not be the usual one, so
    // positions computed now would be wrong for the full set: keep the saved ones.
    function save(specs) {
        const keepPositions = list.some(m => m.disabled)
        const next = Object.assign({}, saved)
        for (const s of specs) {
            const prev = next[s.output]
            const entry = { mode: s.mode, scale: s.scale }
            const position = keepPositions ? prev?.position : s.position
            if (position)
                entry.position = position
            next[s.output] = entry
        }
        saved = next

        const lines = Object.keys(next).sort().map(o => {
            const e = Object.assign({ output: o }, next[o])
            return "hl.monitor({ " + Object.keys(e)
                .map(k => k + " = " + JSON.stringify(e[k])).join(", ") + " })"
        })
        const lua = "-- Written by the shell's display settings; edits here are overwritten.\n"
            + lines.join("\n") + "\n"
        Quickshell.execDetached(["sh", "-c",
            'mkdir -p "$HOME/.local/state/hypr" '
            + '&& printf "%s" "$1" > "$HOME/.local/state/hypr/monitors.lua.tmp" '
            + '&& mv "$HOME/.local/state/hypr/monitors.lua.tmp" "$HOME/.local/state/hypr/monitors.lua" '
            + '&& printf "%s" "$2" > "$3.tmp" && mv "$3.tmp" "$3"',
            "sh", lua, JSON.stringify(next, null, 2) + "\n", savedPath])
    }

    function setEnabled(name, on) {
        const m = find(name)
        if (!m || (!on && enabled.length <= 1))
            return
        send([spec(m, {
            disabled: !on,
            mode: on && m.width === 0 ? "preferred" : undefined,
            position: on && m.width === 0 ? "auto-right" : undefined,
        })])
        settle.restart()
    }

    // Runtime hl.monitor merges into the existing rule, so every call states
    // all the contested keys. A disabled output must never stay in a mirror set
    // (dangling mirror ref crashes Hyprland on the next unplug).
    function spec(m, c) {
        const disabled = c.disabled ?? m.disabled
        return {
            output: m.name,
            mode: c.mode ?? modeOf(m),
            position: c.position ?? (m.x + "x" + m.y),
            scale: c.scale ?? m.scale,
            disabled: disabled,
            mirror: disabled || m.mirrorOf === "none" ? "" : m.mirrorOf,
        }
    }

    // one hyprctl call, so the outputs are reconfigured together and in order
    function send(specs) {
        if (Hypr.lua) {
            const calls = specs.map(s => "hl.monitor({"
                + Object.keys(s).map(k => k + " = " + JSON.stringify(s[k])).join(", ") + "})")
            Quickshell.execDetached(["hyprctl", "eval", calls.join("; ")])
        } else {
            const rules = specs.map(s => "keyword monitor " + (s.disabled ? s.output + ",disable"
                : [s.output, s.mode, s.position, s.scale].join(",")
                    + (s.mirror ? ",mirror," + s.mirror : "")))
            Quickshell.execDetached(["hyprctl", "--batch", rules.join(" ; ")])
        }
    }

    FileView {
        path: root.savedPath
        printErrors: false
        onLoaded: {
            try {
                root.saved = JSON.parse(text())
            } catch (e) {
                console.warn("Monitors: unreadable", root.savedPath, e)
            }
        }
    }

    Process {
        id: proc
        command: ["hyprctl", "monitors", "all", "-j"]
        stdout: StdioCollector {
            onStreamFinished: {
                try {
                    root.list = JSON.parse(this.text)
                } catch (e) {
                    console.warn("Monitors: bad hyprctl output", e)
                }
            }
        }
    }

    Timer {
        id: settle
        interval: 600
        onTriggered: root.refresh()
    }

    Connections {
        target: Hyprland
        function onRawEvent(event) {
            if (event.name.startsWith("monitoradded") || event.name.startsWith("monitorremoved")
                    || event.name === "configreloaded")
                settle.restart()
        }
    }

    Component.onCompleted: refresh()
}
