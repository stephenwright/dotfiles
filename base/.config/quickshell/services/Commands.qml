pragma Singleton
import QtQuick
import Quickshell

// stew commands surfaced in the launcher, grouped by category; edit freely.
// The "Apps" category is added dynamically from desktop entries.
// `icon` is a Nerd Font glyph (nf-md range). Optional `state: () => bool`
// shows on/off next to toggles.
Singleton {
    readonly property var categories: [
        {
            name: "Display", icon: "󰍹",
            children: [
                { name: "stay awake", icon: "󰅶", run: () => Caffeine.on = !Caffeine.on, state: () => Caffeine.on },
                { name: "wallpaper", icon: "󰋩", run: () => PanelManager.toggleByName("wallpaper") },
                { name: "screenshot / record", icon: "󰄀", run: () => PanelManager.toggleByName("display") },
                { name: "toggle recording", icon: "󰑊", cmd: "~/bin/stew capture toggle", state: () => Recorder.recording },
            ],
        },
        {
            name: "Notifications", icon: "󰂚",
            children: [
                { name: "do not disturb", icon: "󰂛", run: () => Notifs.toggleDnd(), state: () => Notifs.dnd },
                { name: "history", icon: "󰋚", run: () => PanelManager.toggleByName("notifications") },
                { name: "dismiss all", icon: "󰎟", run: () => Notifs.dismissAll() },
            ],
        },
        {
            name: "Profiles", icon: "󰍺",
            children: [
                { name: "work", icon: "󰃖", cmd: "~/bin/stew profile work" },
                { name: "home", icon: "󰋜", cmd: "~/bin/stew profile home" },
                { name: "meet", icon: "󰕧", cmd: "~/bin/stew profile meet" },
                { name: "mirror", icon: "󰆏", cmd: "~/bin/stew profile mirror" },
                { name: "swap workspace", icon: "󰓡", cmd: "~/bin/stew profile swap" },
            ],
        },
        {
            name: "Session", icon: "󰐥",
            children: [
                { name: "lock", icon: "󰌾", run: () => Session.lock() },
                { name: "logout", icon: "󰍃", run: () => Session.logout() },
                { name: "sleep", icon: "󰒲", run: () => Session.suspend() },
                { name: "restart", icon: "󰜉", run: () => Session.reboot() },
                { name: "shutdown", icon: "󰐥", run: () => Session.shutdown() },
            ]
        },
        {
            name: "Tools", icon: "󰖷",
            children: [
                { name: "clipboard", icon: "󰅇", cmd: "qs ipc call clipboard toggle" },
                { name: "colour picker", icon: "󰈊", cmd: "sleep 0.2; hyprpicker -a -n" },
            ],
        },
    ]
}
