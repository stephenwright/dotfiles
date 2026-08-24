import QtQuick
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "calendar"
    panelWidth: 280
    implicitHeight: 248
    contentSpacing: 6

    property int year: 2000
    property int month: 0
    property var cells: buildCells(year, month, visible)

    onOpening: reset()

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

    WheelHandler {
        // WheelHandler defaults to mouse only; touchpads report pixelDelta with angleDelta 0
        acceptedDevices: PointerDevice.Mouse | PointerDevice.TouchPad
        property real wheelAcc: 0
        onWheel: event => {
            wheelAcc += event.angleDelta.y !== 0 ? event.angleDelta.y : event.pixelDelta.y * 2.5
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
                font.pixelSize: Theme.fontSizeSmall
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
