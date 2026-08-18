import Quickshell
import "../lib"
import "../services"

BarWidget {
    text: "⏻"
    fg: Theme.red
    hoverBg: Qt.alpha(Theme.red, 0.2)

    onClicked: Quickshell.execDetached(["sh", "-c", "~/bin/stew session"])
}
