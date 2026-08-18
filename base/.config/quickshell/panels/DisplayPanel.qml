import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../lib"
import "../services"

PanelWindow {
    id: root

    property Item anchorItem
    property double lastCleared: 0
    property bool nightOn: false
    property string profile: ""

    readonly property var profiles: ["work", "home", "meet", "mirror"]

    visible: false
    implicitWidth: 300
    implicitHeight: content.implicitHeight + 28
    color: "transparent"

    anchors {
        top: true
        left: true
    }
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "display"

    function toggle() {
        if (visible) {
            visible = false
            return
        }
        // a click that dismissed the grab also reaches the widget on release;
        // don't let it immediately reopen the panel
        if (Date.now() - lastCleared < 300)
            return
        const win = anchorItem.QsWindow.window
        screen = win.screen
        const r = anchorItem.mapToItem(null, 0, 0)
        const x = r.x + anchorItem.width / 2 - implicitWidth / 2
        margins.left = Math.round(Math.max(8, Math.min(x, screen.width - implicitWidth - 8)))
        refresh()
        visible = true
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
    }

    function toggleNight() {
        if (nightOn)
            Quickshell.execDetached(["pkill", "-x", "wlsunset"])
        else
            Quickshell.execDetached(["wlsunset", "-t", "4000", "-T", "4050"])
        nightOn = !nightOn
        lateRefresh.start()
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

        Column {
            id: content
            anchors.fill: parent
            anchors.margins: 12
            spacing: 10

            BarText {
                text: "Brightness"
                font.pixelSize: 11
                color: Theme.overlay1
            }

            Row {
                width: parent.width
                spacing: 10

                BarText {
                    anchors.verticalCenter: parent.verticalCenter
                    text: "󰃟"
                }

                VolSlider {
                    width: parent.width - 24 - 40 - 20
                    value: (root.anchorItem ? root.anchorItem.percent : 0) / 100

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

            MouseArea {
                id: nightRow
                width: parent.width
                height: 26
                hoverEnabled: true
                onClicked: root.toggleNight()

                Rectangle {
                    anchors.fill: parent
                    color: nightRow.containsMouse ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
                }
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

            BarText {
                text: "Profile"
                font.pixelSize: 11
                color: Theme.overlay1
            }

            Grid {
                columns: 2
                spacing: 6

                Repeater {
                    model: root.profiles

                    MouseArea {
                        id: profBtn
                        required property var modelData

                        readonly property bool current: modelData === root.profile

                        width: (content.width - 6) / 2
                        height: 26
                        hoverEnabled: true
                        onClicked: root.setProfile(modelData)

                        Rectangle {
                            anchors.fill: parent
                            color: profBtn.current ? Qt.alpha(Theme.mauve, 0.25)
                                 : profBtn.containsMouse ? Qt.alpha(Theme.surface0, 0.7)
                                 : "transparent"
                            border.color: profBtn.current ? Theme.mauve : Theme.surface1
                            border.width: 1
                        }
                        BarText {
                            anchors.centerIn: parent
                            text: profBtn.modelData
                            color: profBtn.current ? Theme.mauve : Theme.text
                        }
                    }
                }
            }
        }
    }
}
