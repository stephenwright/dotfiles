pragma Singleton
import QtQuick
import Quickshell

// stew commands surfaced in the launcher, grouped by category; edit freely.
// The "Apps" category is added dynamically from desktop entries.
Singleton {
    readonly property var categories: [
        {
            name: "Profiles",
            children: [
                { name: "work", cmd: "~/bin/stew profile work" },
                { name: "home", cmd: "~/bin/stew profile home" },
                { name: "meet", cmd: "~/bin/stew profile meet" },
                { name: "mirror", cmd: "~/bin/stew profile mirror" },
                { name: "swap workspace", cmd: "~/bin/stew profile swap" }
            ]
        },
        {
            name: "Session",
            children: [
                { name: "lock", run: () => Session.lock() },
                { name: "logout", run: () => Session.logout() },
                { name: "sleep", run: () => Session.suspend() },
                { name: "restart", run: () => Session.reboot() },
                { name: "shutdown", run: () => Session.shutdown() }
            ]
        },
        {
            name: "Notifications",
            children: [
                { name: "do not disturb", run: () => Notifs.toggleDnd() },
                { name: "history", run: () => PanelManager.toggleByName("notifications") },
                { name: "dismiss all", run: () => Notifs.dismissAll() }
            ]
        },
        {
            name: "Wallpaper",
            children: [
                { name: "pick", run: () => PanelManager.toggleByName("wallpaper") }
            ]
        },
        {
            name: "Capture",
            children: [
                { name: "toggle recording", cmd: "~/bin/stew capture toggle" }
            ]
        },
        {
            name: "Mux",
            children: [
                { name: "binsentry", cmd: "alacritty -e ~/bin/stew mux binsentry" }
            ]
        }
    ]
}
