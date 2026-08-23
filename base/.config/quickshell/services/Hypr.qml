pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Hyprland

// The lua config provider only accepts hl.dsp.* dispatcher expressions;
// legacy dispatch strings fail. Call sites pass both forms.
Singleton {
    id: root

    property bool lua: false

    function dispatch(legacy, luaExpr) {
        Hyprland.dispatch(lua ? luaExpr : legacy)
    }

    Process {
        command: ["sh", "-c", "hyprctl systeminfo | awk '/^configProvider:/{print $2}'"]
        running: true
        stdout: StdioCollector {
            onStreamFinished: root.lua = this.text.trim() === "lua"
        }
    }
}
