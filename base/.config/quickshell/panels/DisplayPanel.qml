import QtQuick
import Quickshell
import Quickshell.Io
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "display"
    initialFocusItem: Brightness.available ? brightnessSlider : nightRow

    property bool nightOn: false
    property string profile: ""
    property string selectedName: ""
    property bool modesOpen: false

    readonly property var profiles: ["work", "home", "meet", "mirror"]
    readonly property var scales: [1, 1.25, 1.5, 2]
    readonly property var sel: Monitors.find(selectedName)
    readonly property bool selPlaced: sel !== null && Monitors.isPlaced(sel)
    readonly property bool selIsAnchor: sel !== null && sel.name === Monitors.anchor?.name
    readonly property int labelWidth: 52

    onOpening: {
        refresh()
        Monitors.refresh()
        selectedName = screen?.name ?? ""
        modesOpen = false
    }

    function refresh() {
        stateProc.running = true
    }

    Process {
        id: stateProc
        command: ["sh", "-c",
            "prof=$(cat ~/.cache/hypr_current_profile 2>/dev/null || echo none); " +
            "pgrep -x wlsunset >/dev/null && nl=on || nl=off; " +
            "echo \"$prof $nl\""]
        stdout: StdioCollector {
            onStreamFinished: {
                const p = this.text.trim().split(/\s+/)
                root.profile = p[0] || ""
                root.nightOn = p[1] === "on"
            }
        }
    }

    Timer {
        id: lateRefresh
        interval: 500
        onTriggered: root.refresh()
    }

    function setProfile(name) {
        Quickshell.execDetached(["sh", "-c", "~/bin/stew profile " + name])
        profile = name
        lateRefresh.start()
        Monitors.refreshSoon()
    }

    // close first so the panel isn't in the frozen frame / fighting slurp's grab
    function shot(mode) {
        close()
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.2; hyprshot --mode " + mode + " --clipboard-only --freeze"])
    }

    // copies the hex code and posts a notification with it
    function pickColor() {
        close()
        Quickshell.execDetached(["sh", "-c", "sleep 0.2; hyprpicker -a -n"])
    }

    function record(format) {
        close()
        Recorder.start(format)
    }

    function toggleNight() {
        if (nightOn)
            Quickshell.execDetached(["pkill", "-x", "wlsunset"])
        else
            Quickshell.execDetached(["wlsunset", "-t", "4000", "-T", "4050"])
        nightOn = !nightOn
        lateRefresh.start()
    }

    function modeLabel(mode) {
        const p = Monitors.parseMode(mode)
        return p ? p.w + "×" + p.h + " @ " + Math.round(p.hz) : mode
    }

    function isCurrentMode(m, mode) {
        const p = Monitors.parseMode(mode)
        return p !== null && p.w === m.width && p.h === m.height
            && Math.abs(p.hz - m.refreshRate) < 0.05
    }

    PanelHeader {
        icon: "󰍹"
        title: "Display"
        subtitle: (root.profile && root.profile !== "none" ? root.profile + " · " : "")
            + Monitors.enabled.length + (Monitors.enabled.length === 1 ? " monitor" : " monitors")
    }

    Row {
        visible: Brightness.available
        width: parent.width
        spacing: 10

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃟"
        }

        PanelSlider {
            id: brightnessSlider
            width: parent.width - 24 - 40 - 20
            value: Brightness.percent / 100
            accessibleName: "Brightness"

            property int lastSent: -1
            onMoved: v => {
                const p = Math.round(v * 100)
                if (p !== lastSent) {
                    lastSent = p
                    Brightness.set(p + "%")
                }
            }
        }

        BarText {
            width: 40
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            text: Brightness.percent + "%"
            color: Theme.subtext0
        }
    }

    ToggleRow {
        id: nightRow
        icon: "󰖔"
        label: "Night light"
        checked: root.nightOn
        onToggled: root.toggleNight()
    }

    ToggleRow {
        icon: "󰅶"
        label: "Stay awake"
        checked: Caffeine.on
        onToggled: Caffeine.on = !Caffeine.on
    }

    SectionLabel {
        text: "Profile"
    }

    Row {
        spacing: 6

        Repeater {
            model: root.profiles

            SegmentButton {
                required property var modelData

                width: (root.contentWidth - 6 * (root.profiles.length - 1)) / root.profiles.length
                current: modelData === root.profile
                label: modelData
                accessibleName: "Profile " + modelData
                onClicked: root.setProfile(modelData)
            }
        }
    }

    SectionLabel {
        text: "Screenshot"
    }

    Row {
        spacing: 6

        Repeater {
            model: [
                { label: "region", mode: "region" },
                { label: "window", mode: "window" },
                { label: "screen", mode: "output" },
            ]

            SegmentButton {
                required property var modelData

                width: (root.contentWidth - 12) / 3
                label: modelData.label
                accessibleName: "Screenshot " + modelData.label
                onClicked: root.shot(modelData.mode)
            }
        }
    }

    SectionLabel {
        text: "Record"
    }

    Row {
        spacing: 6

        Repeater {
            model: ["gif", "mp4", "webm"]

            SegmentButton {
                required property var modelData

                width: (root.contentWidth - 12) / 3
                label: modelData
                accessibleName: "Record " + modelData
                onClicked: root.record(modelData)
            }
        }
    }

    SegmentButton {
        width: parent.width
        label: "󰈊  colour picker"
        accessibleName: "Colour picker"
        onClicked: root.pickColor()
    }

    SectionLabel {
        text: "Monitors"

        PanelButton {
            id: identifyBtn
            anchors.verticalCenter: parent.verticalCenter
            width: identifyText.implicitWidth + 8
            height: parent.height
            accessibleName: "Identify monitors"
            onClicked: Monitors.identify()

            BarText {
                id: identifyText
                anchors.centerIn: parent
                text: "identify"
                font.pixelSize: Theme.fontSizeSmall
                color: identifyBtn.hovered || identifyBtn.showFocus ? Theme.mauve : Theme.subtext0
            }
        }
    }

    // live layout of the placed (enabled, non-mirroring) outputs
    Item {
        id: map

        readonly property var placed: Monitors.list.filter(m => Monitors.isPlaced(m))
        readonly property var box: {
            let x0 = Infinity, y0 = Infinity, x1 = -Infinity, y1 = -Infinity
            for (const m of placed) {
                const s = Monitors.logical(m)
                x0 = Math.min(x0, m.x)
                y0 = Math.min(y0, m.y)
                x1 = Math.max(x1, m.x + s.w)
                y1 = Math.max(y1, m.y + s.h)
            }
            return placed.length ? { x: x0, y: y0, w: x1 - x0, h: y1 - y0 } : { x: 0, y: 0, w: 1, h: 1 }
        }
        readonly property real k: Math.min((width - 24) / box.w, (height - 16) / box.h)

        width: parent.width
        height: 96

        Rectangle {
            anchors.fill: parent
            color: Qt.alpha(Theme.crust, 0.6)
        }

        Repeater {
            model: map.placed

            PanelButton {
                id: tile
                required property var modelData

                readonly property var size: Monitors.logical(modelData)
                readonly property bool selected: modelData.name === root.selectedName

                x: (map.width - map.box.w * map.k) / 2 + (modelData.x - map.box.x) * map.k + 1
                y: (map.height - map.box.h * map.k) / 2 + (modelData.y - map.box.y) * map.k + 1
                width: size.w * map.k - 2
                height: size.h * map.k - 2
                accessibleName: "Monitor " + modelData.name
                horizontalNavigation: true
                backgroundColor: selected ? Qt.alpha(Theme.mauve, 0.15) : Theme.base
                borderColor: selected ? Theme.mauve : Theme.surface2
                onClicked: {
                    root.selectedName = modelData.name
                    root.modesOpen = false
                }

                Column {
                    anchors.centerIn: parent
                    spacing: 1

                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.name
                        font.bold: true
                        font.pixelSize: Theme.fontSizeSmall
                        color: tile.selected ? Theme.mauve : Theme.text
                    }
                    BarText {
                        anchors.horizontalCenter: parent.horizontalCenter
                        text: tile.modelData.width + "×" + tile.modelData.height
                            + (tile.modelData.scale !== 1 ? " ·" + tile.modelData.scale + "×" : "")
                        font.pixelSize: Theme.fontSizeHint
                        color: Theme.subtext0
                    }
                }
            }
        }
    }

    // outputs that aren't on the map: disabled or mirroring
    Flow {
        width: parent.width
        spacing: 6
        visible: children.length > 1

        Repeater {
            model: Monitors.list.filter(m => !Monitors.isPlaced(m))

            SegmentButton {
                id: chip
                required property var modelData

                width: chipText.implicitWidth + 16
                current: modelData.name === root.selectedName
                accessibleName: "Monitor " + modelData.name
                onClicked: {
                    root.selectedName = modelData.name
                    root.modesOpen = false
                }

                BarText {
                    id: chipText
                    anchors.centerIn: parent
                    text: chip.modelData.name + (chip.modelData.disabled ? " · off"
                        : " · mirrors " + chip.modelData.mirrorOf)
                    font.pixelSize: Theme.fontSizeSmall
                    color: chip.current ? Theme.mauve : Theme.subtext0
                }
            }
        }
    }

    BarText {
        visible: root.sel !== null
        width: parent.width
        elide: Text.ElideRight
        text: root.sel ? (root.sel.model || root.sel.description) + "  ·  " + root.sel.name : ""
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    // mode: current mode; the list of available ones drops down over the
    // rows below so the panel keeps its height
    Item {
        width: parent.width
        height: 24
        z: 10
        enabled: root.selPlaced
        opacity: enabled ? 1 : 0.4

        BarText {
            width: root.labelWidth
            anchors.verticalCenter: parent.verticalCenter
            text: "mode"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.overlay1
        }

        PanelButton {
            id: modeBtn
            x: root.labelWidth
            width: parent.width - root.labelWidth
            height: parent.height
            accessibleName: "Display mode"
            borderColor: root.modesOpen ? Theme.mauve : Theme.surface1
            onClicked: root.modesOpen = !root.modesOpen

            BarText {
                anchors.left: parent.left
                anchors.leftMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.sel ? root.modeLabel(Monitors.modeOf(root.sel)) : ""
                color: modeBtn.showFocus ? Theme.mauve : Theme.text
            }
            BarText {
                anchors.right: parent.right
                anchors.rightMargin: 8
                anchors.verticalCenter: parent.verticalCenter
                text: root.modesOpen ? "▴" : "▾"
                color: Theme.overlay1
            }
        }

        Rectangle {
            visible: root.modesOpen
            x: root.labelWidth
            y: parent.height + 2
            width: parent.width - root.labelWidth
            height: modeList.height + 2
            color: Theme.base
            border.color: Theme.mauve
            border.width: 1

            ListView {
                id: modeList
                x: 1
                y: 1
                width: parent.width - 2
                height: Math.min(4, count) * 24
                clip: true
                model: root.sel ? root.sel.availableModes : []

                delegate: SelectRow {
                    required property var modelData
                    required property int index

                    width: ListView.view.width
                    height: 24
                    selected: root.sel !== null && root.isCurrentMode(root.sel, modelData)
                    label: root.modeLabel(modelData)
                    detail: Monitors.parseMode(modelData)?.hz.toFixed(2) + " Hz"
                    onActiveFocusChanged: {
                        if (activeFocus)
                            modeList.positionViewAtIndex(index, ListView.Contain)
                    }
                    onClicked: {
                        root.modesOpen = false
                        Monitors.change(root.selectedName, { mode: modelData.replace(/Hz$/, "") })
                        modeBtn.forceActiveFocus(Qt.TabFocusReason)
                    }
                }
            }
        }
    }

    Row {
        enabled: root.selPlaced
        opacity: enabled ? 1 : 0.4
        spacing: 6

        BarText {
            width: root.labelWidth - 6
            anchors.verticalCenter: parent.verticalCenter
            text: "scale"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.overlay1
        }

        Repeater {
            model: root.scales

            SegmentButton {
                required property var modelData

                width: (root.contentWidth - root.labelWidth - 6 * (root.scales.length - 1))
                    / root.scales.length
                current: root.sel !== null && Math.abs(root.sel.scale - modelData) < 0.01
                label: String(modelData)
                accessibleName: "Scale " + modelData
                onClicked: Monitors.change(root.selectedName, { scale: modelData })
            }
        }
    }

    // placement relative to the anchor output (the lowest-id enabled one),
    // which itself can't be placed
    Row {
        enabled: root.selPlaced && !root.selIsAnchor && Monitors.anchor !== null
        opacity: enabled ? 1 : 0.4
        spacing: 6

        readonly property var sides: ["left", "right", "above", "below"]
        readonly property string side: root.sel && Monitors.anchor
            ? Monitors.sideOf(root.sel, Monitors.anchor) : ""

        BarText {
            width: root.labelWidth - 6
            anchors.verticalCenter: parent.verticalCenter
            text: "place"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.overlay1
        }

        Repeater {
            model: parent.sides

            SegmentButton {
                required property var modelData

                width: (root.contentWidth - root.labelWidth - 6 * 3) / 4
                current: parent.enabled && parent.side === modelData
                label: modelData
                accessibleName: "Place " + modelData + " of " + (Monitors.anchor?.name ?? "")
                onClicked: Monitors.change(root.selectedName, { side: modelData })
            }
        }
    }

    ToggleRow {
        visible: root.sel !== null
        label: "Enabled"
        checked: root.sel !== null && !root.sel.disabled
        // never turn off the last screen
        enabled: root.sel !== null && (root.sel.disabled || Monitors.enabled.length > 1)
        onToggled: Monitors.setEnabled(root.selectedName, root.sel.disabled)
    }
}
