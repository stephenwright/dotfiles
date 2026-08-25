import QtQuick
import Quickshell
import Quickshell.Io
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "display"
    initialFocusItem: brightnessSlider

    property bool nightOn: false
    property string profile: ""

    readonly property var profiles: ["work", "home", "meet", "mirror"]

    onOpening: refresh()

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
    }

    // close first so the panel isn't in the frozen frame / fighting slurp's grab
    function shot(mode) {
        close()
        Quickshell.execDetached(["sh", "-c",
            "sleep 0.2; hyprshot --mode " + mode + " --clipboard-only --freeze"])
    }

    function record(format) {
        close()
        Quickshell.execDetached(["sh", "-c", "~/bin/stew capture start --format " + format])
    }

    function toggleNight() {
        if (nightOn)
            Quickshell.execDetached(["pkill", "-x", "wlsunset"])
        else
            Quickshell.execDetached(["wlsunset", "-t", "4000", "-T", "4050"])
        nightOn = !nightOn
        lateRefresh.start()
    }

    BarText {
        text: "Brightness"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    Row {
        width: parent.width
        spacing: 10

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: "󰃟"
        }

        PanelSlider {
            id: brightnessSlider
            width: parent.width - 24 - 40 - 20
            value: (root.anchorItem ? root.anchorItem.percent : 0) / 100
            accessibleName: "Brightness"

            property int lastSent: -1
            onMoved: v => {
                const p = Math.round(v * 100)
                if (p !== lastSent) {
                    lastSent = p
                    root.anchorItem.set(p + "%")
                }
            }
        }

        BarText {
            width: 40
            horizontalAlignment: Text.AlignRight
            anchors.verticalCenter: parent.verticalCenter
            text: (root.anchorItem ? root.anchorItem.percent : 0) + "%"
            color: Theme.subtext0
        }
    }

    PanelToggle {
        id: nightRow
        width: parent.width
        height: 26
        checked: root.nightOn
        accessibleName: "Night light"
        onToggled: root.toggleNight()
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            text: "󰖔 Night light"
            color: root.nightOn ? Theme.peach : Theme.text
        }
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4
            text: root.nightOn ? "on" : "off"
            color: root.nightOn ? Theme.peach : Theme.overlay0
        }
    }

    PanelToggle {
        id: awakeRow
        width: parent.width
        height: 26
        checked: Caffeine.on
        accessibleName: "Stay awake"
        onToggled: Caffeine.on = !Caffeine.on
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.left: parent.left
            anchors.leftMargin: 4
            text: "󰅶 Stay awake"
            color: Caffeine.on ? Theme.green : Theme.text
        }
        BarText {
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: parent.right
            anchors.rightMargin: 4
            text: Caffeine.on ? "on" : "off"
            color: Caffeine.on ? Theme.green : Theme.overlay0
        }
    }

    BarText {
        text: "Profile"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    PanelChoiceGroup {
        width: parent.width
        columns: 2
        options: root.profiles
        accessibleName: "Profile"
        optionCurrent: option => option === root.profile
        onChosen: option => root.setProfile(option)
    }

    BarText {
        text: "Screenshot"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    PanelChoiceGroup {
        width: parent.width
        columns: 3
        options: [
            { label: "region", run: () => root.shot("region") },
            { label: "window", run: () => root.shot("window") },
            { label: "screen", run: () => root.shot("output") },
        ]
        accessibleName: "Screenshot"
        optionText: option => option.label
        onChosen: option => option.run()
    }

    BarText {
        text: "Record"
        font.pixelSize: Theme.fontSizeSmall
        color: Theme.overlay1
    }

    PanelChoiceGroup {
        width: parent.width
        columns: 3
        options: [
            { label: "gif", run: () => root.record("gif") },
            { label: "mp4", run: () => root.record("mp4") },
            { label: "webm", run: () => root.record("webm") },
        ]
        accessibleName: "Record"
        optionText: option => option.label
        onChosen: option => option.run()
    }
}
