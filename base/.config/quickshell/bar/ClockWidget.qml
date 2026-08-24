import Quickshell
import "../lib"
import "../services"
import "../panels"

BarWidget {
    id: root

    SystemClock {
        id: clock
        precision: SystemClock.Minutes
    }

    text: Qt.formatDateTime(clock.date, "ddd dd, hh:mm AP")

    onClicked: panel.toggle()
    // match panel wheel direction: scroll down = next month
    onScrolledUp: if (panel.visible) panel.page(-1)
    onScrolledDown: if (panel.visible) panel.page(1)

    CalendarPanel {
        id: panel
        anchorItem: root
    }
}
