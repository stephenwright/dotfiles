import QtQuick
import Quickshell
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    text: ""
    fg: SysStats.critical ? Theme.red : SysStats.warning ? Theme.yellow : Theme.text
    blink: SysStats.critical

    active: panel.visible

    onClicked: event => {
        if (event.button === Qt.RightButton) {
            PanelManager.close()
            Quickshell.execDetached(Settings.systemMonitor)
        } else {
            panel.toggle()
        }
    }

    SystemPanel {
        id: panel
        anchorItem: root
    }
}
