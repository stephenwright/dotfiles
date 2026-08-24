import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../lib"
import "../services"

// cliphist history picker, launcher-style centered window
PanelWindow {
    id: root

    visible: false
    implicitWidth: 640
    implicitHeight: 44 + results.length * 30
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "clipboard"
    // OnDemand, not Exclusive: an exclusive-keyboard layer pins focus to itself,
    // which keeps HyprlandFocusGrab from ever clearing on outside clicks
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property var entries: []
    property var results: []
    property int selected: 0

    function toggle() {
        visible ? hide() : show()
    }

    function show() {
        input.text = ""
        entries = []
        results = []
        listProc.running = true
        visible = true
        input.forceActiveFocus()
    }

    function hide() {
        visible = false
    }

    Process {
        id: listProc
        command: ["cliphist", "list"]
        stdout: StdioCollector {
            onStreamFinished: {
                const out = []
                for (const line of this.text.split("\n")) {
                    const tab = line.indexOf("\t")
                    if (tab < 0)
                        continue
                    const preview = line.slice(tab + 1)
                    out.push({
                        id: line.slice(0, tab),
                        preview: preview,
                        isImage: preview.startsWith("[[ binary data")
                    })
                }
                root.entries = out
                root.refilter()
            }
        }
    }

    function refilter() {
        const q = input.text.trim()
        results = (!q ? entries
            : entries
                .map(e => ({ e, s: Fuzzy.score(q, e.preview) }))
                .filter(x => x.s >= 0)
                .sort((a, b) => b.s - a.s)
                .map(x => x.e)
        ).slice(0, 15)
        selected = 0
    }

    function activate() {
        const e = results[selected]
        if (!e)
            return
        hide()
        Quickshell.execDetached(["sh", "-c", "cliphist decode " + e.id + " | wl-copy"])
    }

    IpcHandler {
        target: "clipboard"

        function toggle(): void {
            root.toggle()
        }
    }

    HyprlandFocusGrab {
        // wait for the surface to be mapped, or the grab registers nothing
        active: root.visible && root.backingWindowVisible
        windows: [root]
        onCleared: root.hide()
    }

    Rectangle {
        anchors.fill: parent
        color: Theme.base
        border.color: Theme.mauve
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 2

            Item {
                width: parent.width
                height: 40

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    clip: true

                    onTextChanged: root.refilter()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.hide()
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            root.selected = Math.min(root.selected + 1, root.results.length - 1)
                        } else if (event.key === Qt.Key_Up) {
                            root.selected = Math.max(root.selected - 1, 0)
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate()
                        } else {
                            return
                        }
                        event.accepted = true
                    }

                    BarText {
                        visible: !input.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: "clipboard history…"
                        color: Theme.overlay0
                        font.pixelSize: 15
                    }
                }

                Rectangle {
                    anchors { left: parent.left; right: parent.right; bottom: parent.bottom }
                    height: 1
                    color: Theme.surface1
                }
            }

            Repeater {
                model: root.results

                MouseArea {
                    id: row
                    required property var modelData
                    required property int index

                    width: parent.width
                    height: 30
                    hoverEnabled: true

                    onClicked: {
                        root.selected = index
                        root.activate()
                    }

                    Rectangle {
                        anchors.fill: parent
                        color: row.index === root.selected ? Theme.surface0
                             : row.containsMouse ? Qt.alpha(Theme.surface0, 0.5)
                             : "transparent"
                    }
                    Rectangle {
                        width: 3
                        height: parent.height
                        color: row.index === root.selected ? Theme.mauve : "transparent"
                    }
                    BarText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        elide: Text.ElideRight
                        text: (row.modelData.isImage ? "󰋩 image · " : "")
                            + row.modelData.preview.trim()
                        font.pixelSize: Theme.fontSize
                        color: row.index === root.selected ? Theme.mauve : Theme.text
                    }
                }
            }
        }
    }
}
