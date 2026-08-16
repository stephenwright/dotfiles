import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland

PanelWindow {
    id: root

    visible: false
    implicitWidth: 560
    implicitHeight: 44 + results.length * 30
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "launcher"
    // OnDemand, not Exclusive: an exclusive-keyboard layer pins focus to itself,
    // which keeps HyprlandFocusGrab from ever clearing on outside clicks
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property var category: null
    property var results: []
    property int selected: 0

    function toggle() {
        visible ? hide() : show()
    }

    function show() {
        category = null
        input.text = ""
        refilter()
        visible = true
        input.forceActiveFocus()
    }

    function hide() {
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

    // subsequence match with word-start and streak bonuses
    function score(query, target) {
        const q = query.toLowerCase()
        const t = target.toLowerCase()
        let qi = 0, s = 0, streak = 0
        for (let ti = 0; ti < t.length && qi < q.length; ti++) {
            if (t[ti] === q[qi]) {
                qi++
                streak++
                s += streak
                if (ti === 0 || " :-_/".includes(t[ti - 1]))
                    s += 3
            } else {
                streak = 0
            }
        }
        return qi === q.length ? s : -1
    }

    function refilter() {
        const q = input.text.trim()
        if (!q) {
            results = category ? category.children.slice(0, 12) : categoryList()
        } else {
            const scope = leaves(category ? [category] : categoryList())
            results = scope
                .map(e => ({ e, s: score(q, e.label) }))
                .filter(x => x.s >= 0)
                .sort((a, b) => b.s - a.s)
                .slice(0, 12)
                .map(x => x.e)
        }
        selected = 0
    }

    function activate() {
        const e = results[selected]
        if (!e)
            return
        if (e.children) {
            descend(e)
            return
        }
        hide()
        if (e.entry)
            e.entry.execute()
        else
            Quickshell.execDetached(["sh", "-c", e.cmd])
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

                BarText {
                    id: breadcrumb
                    visible: root.category !== null
                    anchors.verticalCenter: parent.verticalCenter
                    anchors.left: parent.left
                    anchors.leftMargin: 12
                    text: root.category ? root.category.name + " ›" : ""
                    color: Theme.mauve
                    font.pixelSize: 15
                }

                TextInput {
                    id: input
                    anchors.fill: parent
                    anchors.leftMargin: root.category ? breadcrumb.width + 20 : 12
                    anchors.rightMargin: 12
                    verticalAlignment: TextInput.AlignVCenter
                    color: Theme.text
                    font.family: Theme.fontFamily
                    font.pixelSize: 15
                    clip: true

                    onTextChanged: root.refilter()

                    Keys.onPressed: event => {
                        if (event.key === Qt.Key_Escape) {
                            root.category ? root.back() : root.hide()
                        } else if (event.key === Qt.Key_Backspace && !input.text && root.category) {
                            root.back()
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
                        text: root.category ? "search…" : "search everything…"
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
                        text: row.modelData.label ?? row.modelData.name
                        font.pixelSize: 13
                        color: row.index === root.selected ? Theme.mauve : Theme.text
                    }
                    BarText {
                        anchors.verticalCenter: parent.verticalCenter
                        anchors.right: parent.right
                        anchors.rightMargin: 12
                        text: row.modelData.children ? "›" : row.modelData.entry ? "app" : "stew"
                        font.pixelSize: row.modelData.children ? 13 : 11
                        color: row.modelData.children ? Theme.mauve : Theme.overlay0
                    }
                }
            }
        }
    }
}
