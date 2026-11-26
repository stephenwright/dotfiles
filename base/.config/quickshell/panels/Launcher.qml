import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../lib"
import "../services"

PanelWindow {
    id: root

    visible: false
    implicitWidth: 560
    // fixed at the tallest size, with the box drawn at content height inside:
    // resizing the surface makes Hyprland animate it, stretching stale frames
    implicitHeight: 44 + maxRows * rowHeight
    color: "transparent"
    mask: Region { item: box }
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher"
    // OnDemand, not Exclusive: an exclusive-keyboard layer pins focus to itself,
    // which keeps HyprlandFocusGrab from ever clearing on outside clicks
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property var category: null
    property var results: []
    property int selected: 0

    readonly property int maxRows: 12
    readonly property int rowHeight: 30

    // "> cmd" runs a shell command, "= expr" evaluates with qalc. Functions,
    // not bindings: refilter runs from onTextChanged, possibly before a
    // binding on input.text would have updated.
    function mode() {
        return input.text.startsWith(">") ? "run"
            : input.text.startsWith("=") ? "calc" : ""
    }

    function modeArg() {
        return input.text.slice(1).trim()
    }

    onSelectedChanged: list.positionViewAtIndex(selected, ListView.Contain)

    Component.onCompleted: PanelManager.register("launcher", root)
    Component.onDestruction: PanelManager.unregister("launcher", root)

    function toggle() {
        PanelManager.toggle(root)
    }

    function close() {
        PanelManager.close(root)
    }

    function managedOpen() {
        category = null
        input.text = ""
        refilter()
        visible = true
        input.forceActiveFocus()
    }

    function managedClose() {
        visible = false
    }

    function descend(cat) {
        category = cat
        input.text = ""
        refilter()
    }

    function back() {
        category = null
        input.text = ""
        refilter()
    }

    function appEntries() {
        return DesktopEntries.applications.values
            .filter(a => !a.noDisplay)
            .map(a => ({ name: a.name, entry: a }))
            .sort((a, b) => a.name.localeCompare(b.name))
    }

    function categoryList() {
        return [{ name: "Apps", children: appEntries() }].concat(Commands.categories)
    }

    // flatten to searchable leaves; stew entries get a category-prefixed label
    // (no Array.flatMap — Qt's JS engine doesn't implement it)
    function leaves(cats) {
        const out = []
        for (const c of cats)
            for (const e of c.children)
                out.push(Object.assign({}, e, {
                    label: c.name === "Apps" ? e.name : c.name + ": " + e.name
                }))
        return out
    }

    function refilter() {
        const q = input.text.trim()
        const arg = modeArg()
        if (mode() === "run") {
            results = arg ? [{ label: arg, shell: arg }] : []
        } else if (mode() === "calc") {
            results = []
            if (arg)
                calcDebounce.restart()
        } else if (!q) {
            results = category ? category.children : categoryList()
        } else {
            const scope = leaves(category ? [category] : categoryList())
            results = scope
                .map(e => ({ e, s: Fuzzy.score(q, e.label) }))
                .filter(x => x.s >= 0)
                .sort((a, b) => b.s - a.s)
                .map(x => x.e)
        }
        selected = 0
    }

    Timer {
        id: calcDebounce
        interval: 120
        onTriggered: {
            calc.running = false
            calc.command = ["qalc", "-t", "--", root.modeArg()]
            calc.running = true
        }
    }

    Process {
        id: calc
        stdout: StdioCollector {
            onStreamFinished: {
                const r = this.text.trim()
                if (root.mode() === "calc" && r)
                    root.results = [{ label: r, copy: r }]
            }
        }
    }

    // inTerminal: Shift+Enter on a "> cmd" row; the shell stays open afterwards
    function activate(inTerminal) {
        const e = results[selected]
        if (!e)
            return
        if (e.children) {
            descend(e)
            return
        }
        close()
        if (e.entry && e.entry.runInTerminal)
            // DesktopEntry.execute() ignores Terminal=true
            Quickshell.execDetached({
                command: Settings.inTerminal(e.entry.command),
                workingDirectory: e.entry.workingDirectory
            })
        else if (e.entry)
            e.entry.execute()
        else if (e.run)
            e.run()
        else if (e.copy)
            Quickshell.execDetached(["wl-copy", "--", e.copy])
        else if (e.shell && inTerminal)
            Quickshell.execDetached(Settings.inTerminal(["sh", "-c", e.shell + "; exec ${SHELL:-sh}"]))
        else if (e.shell)
            Quickshell.execDetached(["sh", "-c", e.shell])
        else
            Quickshell.execDetached(["sh", "-c", e.cmd])
    }

    function tagFor(e) {
        if (e.children)
            return "›"
        if (e.state)
            return e.state() ? "on" : "off"
        return e.entry ? (e.entry.runInTerminal ? "term" : "app")
            : e.shell ? "run ⇧term"
            : e.copy ? "copy"
            : e.run ? "qs"
            : e.cmd.includes("stew") ? "stew" : "sh"
    }

    IpcHandler {
        target: "launcher"

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
        id: box
        width: parent.width
        height: 44 + list.height
        color: Theme.panelBg
        border.color: Theme.mauve
        border.width: 2

        Column {
            anchors.fill: parent
            anchors.margins: 2

            Item {
                width: parent.width
                height: 40

                BarText {
                    id: breadcrumb
                    visible: root.category !== null
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: root.category ? root.category.name + " ›" : ""
                    color: Theme.mauve
                    font.pixelSize: Theme.fontSizeLarge
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: root.category ? breadcrumb.width + 20 : 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: Theme.fontSizeLarge
                    clip: true

                    onTextChanged: root.refilter()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Backspace && !input.text && root.category) {
                            root.back()
                        } else if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab) {
                            root.selected = Math.min(root.selected + 1, root.results.length - 1)
                        } else if (event.key === Qt.Key_Up || event.key === Qt.Key_Backtab) {
                            root.selected = Math.max(root.selected - 1, 0)
                        } else if (event.key === Qt.Key_PageDown) {
                            root.selected = Math.min(root.selected + root.maxRows, root.results.length - 1)
                        } else if (event.key === Qt.Key_PageUp) {
                            root.selected = Math.max(root.selected - root.maxRows, 0)
                        } else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter) {
                            root.activate(event.modifiers & Qt.ShiftModifier)
                        } else {
                            return
                        }
                        event.accepted = true
                    }

                    BarText {
                        visible: !input.text
                        anchors.verticalCenter: parent.verticalCenter
                        text: root.category ? "search…" : "search everything…"
                        color: Theme.overlay0
                        font.pixelSize: Theme.fontSizeLarge
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
                height: Math.min(root.results.length, root.maxRows) * root.rowHeight
                clip: true
                boundsBehavior: Flickable.StopAtBounds
                model: root.results

                delegate: MouseArea {
                    id: row
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: root.rowHeight
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
                        text: row.modelData.label ?? row.modelData.name
                        font.pixelSize: Theme.fontSizeLarge
                        color: row.index === root.selected ? Theme.mauve : Theme.text
                    }
                    BarText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        text: root.tagFor(row.modelData)
                        font.pixelSize: Theme.fontSizeLarge
                        color: row.modelData.children ? Theme.mauve
                            : row.modelData.state && row.modelData.state() ? Theme.green : Theme.overlay0
                    }
                }
            }
        }
    }
}
