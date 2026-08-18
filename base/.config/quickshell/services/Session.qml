pragma Singleton
import QtQuick
import Quickshell

// Session actions, shared by SessionPanel, the launcher, and keybinds.
// ~/bin/stew session <action> remains the CLI equivalent.
Singleton {
    function lock() {
        Quickshell.execDetached(["hyprlock"])
    }

    function logout() {
        Quickshell.execDetached(["hyprctl", "dispatch", "exit"])
    }

    function suspend() {
        Quickshell.execDetached(["systemctl", "suspend"])
    }

    function reboot() {
        Quickshell.execDetached(["systemctl", "reboot"])
    }

    function shutdown() {
        Quickshell.execDetached(["systemctl", "poweroff"])
    }
}
