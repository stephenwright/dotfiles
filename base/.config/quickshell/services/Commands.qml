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
                { name: "lock", cmd: "~/bin/stew session lock" },
                { name: "logout", cmd: "~/bin/stew session logout" },
                { name: "sleep", cmd: "~/bin/stew session sleep" },
                { name: "restart", cmd: "~/bin/stew session restart" },
                { name: "shutdown", cmd: "~/bin/stew session shutdown" }
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
                { name: "next", cmd: "~/bin/stew wall next" },
                { name: "prev", cmd: "~/bin/stew wall prev" },
                { name: "pick", cmd: "~/bin/stew wall pick" }
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
