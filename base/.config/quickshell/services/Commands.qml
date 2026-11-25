pragma Singleton
import QtQuick
import Quickshell

// stew commands surfaced in the launcher, grouped by category; edit freely.
// The "Apps" category is added dynamically from desktop entries.
// Optional `state: () => bool` shows on/off next to toggles.
Singleton {
    readonly property var categories: [
        {
            name: "Display",
            children: [
                { name: "stay awake", run: () => Caffeine.on = !Caffeine.on, state: () => Caffeine.on },
                { name: "wallpaper", run: () => PanelManager.toggleByName("wallpaper") },
                { name: "screenshot / record", run: () => PanelManager.toggleByName("display") },
                { name: "toggle recording", cmd: "~/bin/stew capture toggle", state: () => Recorder.recording },
            ],
        },
        {
            name: "Notifications",
            children: [
                { name: "do not disturb", run: () => Notifs.toggleDnd(), state: () => Notifs.dnd },
                { name: "history", run: () => PanelManager.toggleByName("notifications") },
                { name: "dismiss all", run: () => Notifs.dismissAll() },
            ],
        },
        {
            name: "Profiles",
            children: [
                { name: "work", cmd: "~/bin/stew profile work" },
                { name: "home", cmd: "~/bin/stew profile home" },
                { name: "meet", cmd: "~/bin/stew profile meet" },
                { name: "mirror", cmd: "~/bin/stew profile mirror" },
                { name: "swap workspace", cmd: "~/bin/stew profile swap" },
            ],
        },
        {
            name: "Session",
            children: [
                { name: "lock", run: () => Session.lock() },
                { name: "logout", run: () => Session.logout() },
                { name: "sleep", run: () => Session.suspend() },
                { name: "restart", run: () => Session.reboot() },
                { name: "shutdown", run: () => Session.shutdown() },
            ]
        },
        {
            name: "Tools",
            children: [
                { name: "clipboard", cmd: "qs ipc call clipboard toggle" },
                { name: "color picker", cmd: "sleep 0.2; hyprpicker -a -n" },
            ],
        },
    ]
}
