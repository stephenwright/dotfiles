pragma Singleton
import QtQuick
import Quickshell

// Behavioral preferences; Theme.qml stays purely visual.
Singleton {
    // command prefix for "run in a terminal"; mirrors $terminal in hyprland.conf
    readonly property var terminal: ["alacritty", "-e"]

    // full command; swap for a GUI monitor (e.g. ["gnome-system-monitor"])
    readonly property var systemMonitor: inTerminal(["btop"])

    function inTerminal(cmd) {
        return terminal.concat(cmd)
    }
}
