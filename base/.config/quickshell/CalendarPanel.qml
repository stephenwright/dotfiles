import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Wayland

PanelWindow {
    id: root

    property Item clockItem
    property int year: 2000
    property int month: 0
    property var cells: buildCells(year, month, visible)
    property double lastCleared: 0

    visible: false
    implicitWidth: 280
    implicitHeight: 248
    color: "transparent"

    anchors {
        top: true
        left: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "calendar"

    function toggle() {
        if (visible) {
            visible = false
            return
        }
        // a click that dismissed the grab also reaches the clock on release;
        // don't let it immediately reopen the panel
        if (Date.now() - lastCleared < 300)
            return
        const win = clockItem.QsWindow.window
        screen = win.screen
        const r = clockItem.mapToItem(null, 0, 0)
        margins.left = Math.max(0, Math.round(r.x + clockItem.width / 2 - implicitWidth / 2))
        reset()
        visible = true
    }

    function reset() {
        const now = new Date()
        year = now.getFullYear()
        month = now.getMonth()
    }

    function page(d) {
        const m = month + d
        year += Math.floor(m / 12)
        month = ((m % 12) + 12) % 12
    }

    // 6x7 grid; extra arg forces "today" refresh each open
    function buildCells(y, m, _vis) {
        const loc = Qt.locale()
        const startDow = loc.firstDayOfWeek % 7
        const first = new Date(y, m, 1)
        const offset = (first.getDay() - startDow + 7) % 7
        const today = new Date()
        const out = []
        for (let i = 0; i < 42; i++) {
            const d = new Date(y, m, 1 - offset + i)
            out.push({
                day: d.getDate(),
                cur: d.getMonth() === m,
                today: d.getDate() === today.getDate()
                    && d.getMonth() === today.getMonth()
                    && d.getFullYear() === today.getFullYear()
            })
        }
        return out
    }

    function dowNames() {
        const loc = Qt.locale()
        const names = []
        for (let i = 0; i < 7; i++) {
            const dow = ((loc.firstDayOfWeek - 1 + i) % 7) + 1
            names.push(loc.dayName(dow, Locale.ShortFormat))
        }
        return names
    }

    HyprlandFocusGrab {
        // wait for the surface to be mapped, or the grab registers nothing
        active: root.visible && root.backingWindowVisible
        windows: [root]
        onCleared: {
            root.lastCleared = Date.now()
            root.visible = false
        }
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        border.color: Theme.mauve
        border.width: 2

        MouseArea {
            anchors.fill: parent
            property real wheelAcc: 0
            onWheel: event => {
                wheelAcc += event.angleDelta.y
                while (wheelAcc >= 120) {
                    wheelAcc -= 120
                    root.page(-1)
                }
                while (wheelAcc <= -120) {
                    wheelAcc += 120
                    root.page(1)
                }
            }
        }

        Column {
            anchors.fill: parent
            anchors.margins: 12
            spacing: 6

            Item {
                width: parent.width
                height: 24

                MouseArea {
                    id: prevBtn
                    width: 24
                    height: parent.height
                    anchors.left: parent.left
                    hoverEnabled: true
                    onClicked: root.page(-1)
                    BarText {
                        anchors.centerIn: parent
                        text: "‹"
                        font.pixelSize: 16
                        color: prevBtn.containsMouse ? Theme.mauve : Theme.overlay1
                    }
                }

                MouseArea {
                    id: title
                    anchors.centerIn: parent
                    width: titleText.implicitWidth
                    height: parent.height
                    onClicked: root.reset()
                    BarText {
                        id: titleText
                        anchors.centerIn: parent
                        text: Qt.locale().standaloneMonthName(root.month, Locale.LongFormat) + " " + root.year
                        color: Theme.mauve
                        font.bold: true
                    }
                }

                MouseArea {
                    id: nextBtn
                    width: 24
                    height: parent.height
                    anchors.right: parent.right
                    hoverEnabled: true
                    onClicked: root.page(1)
                    BarText {
                        anchors.centerIn: parent
                        text: "›"
                        font.pixelSize: 16
                        color: nextBtn.containsMouse ? Theme.mauve : Theme.overlay1
                    }
                }
            }

            Row {
                Repeater {
                    model: root.dowNames()

                    BarText {
                        required property var modelData
                        width: 36
                        horizontalAlignment: Text.AlignHCenter
                        text: modelData
                        font.pixelSize: 11
                        color: Theme.overlay1
                    }
                }
            }

            Grid {
                columns: 7

                Repeater {
                    model: root.cells

                    Item {
                        required property var modelData
                        width: 36
                        height: 28

                        Rectangle {
                            anchors.fill: parent
                            color: modelData.today ? Qt.alpha(Theme.mauve, 0.25) : "transparent"
                        }
                        BarText {
                            anchors.centerIn: parent
                            text: parent.modelData.day
                            font.bold: parent.modelData.today
                            color: parent.modelData.today ? Theme.mauve
                                 : parent.modelData.cur ? Theme.text
                                 : Theme.overlay0
                        }
                    }
                }
            }
        }
    }
}
