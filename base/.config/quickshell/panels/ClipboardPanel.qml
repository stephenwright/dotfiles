import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../lib"
import "../services"

// cliphist history picker, launcher-style centered window. Image entries get
// thumbnails decoded into the cache dir, one batch per open.
PanelWindow {
    id: root

    visible: false
    implicitWidth: 640
    implicitHeight: 44 + list.height
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
    // thumbnail file names known to exist; filled as the decode script reports them
    property var thumbsReady: ({})

    readonly property string thumbDir: Quickshell.cachePath("clipboard-thumbs")
    readonly property int rowHeight: 30
    readonly property int imageRowHeight: 64
    readonly property int maxListHeight: 480

    onSelectedChanged: list.positionViewAtIndex(selected, ListView.Contain)

    Component.onCompleted: PanelManager.register("clipboard", root)
    Component.onDestruction: PanelManager.unregister("clipboard", root)

    function toggle() {
        PanelManager.toggle(root)
    }

    function close() {
        PanelManager.close(root)
    }

    function managedOpen() {
        input.text = ""
        entries = []
        results = []
        listProc.running = true
        visible = true
        input.forceActiveFocus()
    }

    function managedClose() {
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
                    const id = line.slice(0, tab)
                    const preview = line.slice(tab + 1)
                    // e.g. "[[ binary data 47 KiB png 1920x1080 ]]"
                    const img = preview.match(/^\[\[ binary data (.+?) (\w+) (\d+x\d+) \]\]$/)
                    out.push({
                        id: id,
                        preview: img ? img[2] + " " + img[3] + " · " + img[1] : preview,
                        thumb: img ? id + "." + img[2] : ""
                    })
                }
                root.entries = out
                root.refilter()
                const thumbs = out.filter(e => e.thumb).map(e => e.thumb)
                thumbProc.command = ["sh", "-c", root.thumbScript, "sh", root.thumbDir].concat(thumbs)
                thumbProc.running = true
            }
        }
    }

    // decode missing thumbnails (newest first, reporting each as it's ready),
    // then drop ones whose entry left the history
    readonly property string thumbScript: [
        'dir=$1; shift; mkdir -p "$dir"',
        'for f; do',
        '  [ -s "$dir/$f" ] || { cliphist decode "${f%.*}" > "$dir/$f.tmp" && mv "$dir/$f.tmp" "$dir/$f"; }',
        '  [ -s "$dir/$f" ] && echo "$f"',
        'done',
        'for p in "$dir"/*; do',
        '  case " $* " in *" ${p##*/} "*) ;; *) rm -f "$p" ;; esac',
        'done',
    ].join("\n")

    Process {
        id: thumbProc
        stdout: SplitParser {
            onRead: f => root.thumbsReady = Object.assign({}, root.thumbsReady, { [f]: true })
        }
    }

    function refilter() {
        const q = input.text.trim()
        results = !q ? entries
            : entries
                .map(e => ({ e, s: Fuzzy.score(q, e.preview) }))
                .filter(x => x.s >= 0)
                .sort((a, b) => b.s - a.s)
                .map(x => x.e)
        selected = 0
    }

    function activate() {
        const e = results[selected]
        if (!e)
            return
        close()
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
        windows: PanelManager.grabWindows(root)
        onCleared: PanelManager.dismissed(root)
    }

    Shortcut {
        sequence: "Escape"
        enabled: root.visible
        context: Qt.WindowShortcut
        onActivated: root.close()
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
                        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            root.selected = Math.min(root.selected + 1, root.results.length - 1)
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            root.selected = Math.max(root.selected - 1, 0)
                        } else if (event.key === Qt.Key_PageDown) {
                            root.selected = Math.min(root.selected + 10, root.results.length - 1)
                        } else if (event.key === Qt.Key_PageUp) {
                            root.selected = Math.max(root.selected - 10, 0)
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

            ListView {
                id: list
                width: parent.width
                height: Math.min(contentHeight, root.maxListHeight)
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.results

                delegate: MouseArea {
                    id: row
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: modelData.thumb ? root.imageRowHeight : root.rowHeight
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
                    Rectangle {
                        id: thumbFrame
                        visible: row.modelData.thumb !== ""
                        x: 12
                        width: visible ? 96 : 0
                        height: parent.height - 8
                        anchors.verticalCenter: parent.verticalCenter
                        color: Theme.mantle

                        Image {
                            anchors.fill: parent
                            anchors.margins: 1
                            asynchronous: true
                            fillMode: Image.PreserveAspectFit
                            sourceSize: Qt.size(192, 112)
                            source: root.thumbsReady[row.modelData.thumb]
                                ? "file://" + root.thumbDir + "/" + row.modelData.thumb
                                : ""
                        }
                    }
                    BarText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.left: thumbFrame.visible ? thumbFrame.right : parent.left
                        anchors.leftMargin: 12
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        elide: Text.ElideRight
                        text: (row.modelData.thumb ? "󰋩 " : "") + row.modelData.preview.trim()
                        font.pixelSize: Theme.fontSize
                        color: row.index === root.selected ? Theme.mauve : Theme.text
                    }
                }
            }
        }
    }
}
