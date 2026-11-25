pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io

// global stay-awake state; held as one systemd idle inhibitor instead of
// per-window Wayland inhibitors, whose compositor-side state can go stale.
// The inhibitor waits on the shell's pid ($PPID before exec) so it can't
// outlive a qs exit or crash.
Singleton {
    property alias on: persist.on

    PersistentProperties {
        id: persist
        reloadableId: "caffeine"

        property bool on: false
    }

    Process {
        running: persist.on
        command: ["sh", "-c", "exec systemd-inhibit --what=idle --who=quickshell"
                  + " --why='stay awake' tail --pid=$PPID -f /dev/null"]
    }
}
