import QtQuick
import Quickshell
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "capture"
    panelWidth: 220
    contentSpacing: 4
    wantsKeyboard: true

    property int selected: 0

    onOpening: selected = 0

    // delay so the panel is gone before hyprshot freezes the screen
    readonly property var shots: [
        { icon: "", label: "region", idx: 0, run: () => shot("region") },
        { icon: "", label: "window", idx: 1, run: () => shot("window") },
        { icon: "", label: "screen", idx: 2, run: () => shot("output") }
    ]
    readonly property var recs: [
        { icon: "", label: "gif", idx: 3, run: () => record("gif") },
        { icon: "", label: "mp4", idx: 4, run: () => record("mp4") },
        { icon: "", label: "webm", idx: 5, run: () => record("webm") }
    ]
    readonly property var actions: shots.concat(recs)

    function shot(mode) {
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.2; hyprshot --mode " + mode + " --clipboard-only --freeze"])
    }

    function record(format) {
        Quickshell.execDetached(["sh", "-c", "~/bin/stew capture start --format " + format])
        anchorItem.pollSoon()
    }

    function trigger(a) {
        close()
        a.run()
    }

    onKeyPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_J)
            selected = Math.min(selected + 1, actions.length - 1)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
            selected = Math.max(selected - 1, 0)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            trigger(actions[selected])
        else
            return
        event.accepted = true
    }

    Component {
        id: rowDelegate

        MouseArea {
            id: row
            required property var modelData

            readonly property bool isSelected: root.selected === modelData.idx

            width: parent.width
            height: 28
            hoverEnabled: true
            onEntered: root.selected = modelData.idx
            onClicked: root.trigger(modelData)

            Rectangle {
                anchors.fill: parent
                color: row.isSelected ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
            }
            Rectangle {
                width: 3
                height: parent.height
                color: row.isSelected ? Theme.mauve : "transparent"
            }
            BarText {
                anchors.verticalCenter: parent.verticalCenter
                anchors.left: parent.left
                anchors.leftMargin: 8
                text: row.modelData.icon + "  " + row.modelData.label
                color: row.isSelected ? Theme.mauve : Theme.text
            }
        }
    }

    BarText {
        text: "Screenshot"
        font.pixelSize: 11
        color: Theme.overlay1
    }

    Repeater {
        model: root.shots
        delegate: rowDelegate
    }

    BarText {
        text: "Record"
        font.pixelSize: 11
        color: Theme.overlay1
    }

    Repeater {
        model: root.recs
        delegate: rowDelegate
    }
}
