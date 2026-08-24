import QtQuick
import Quickshell
import Quickshell.Hyprland
import Quickshell.Io
import Quickshell.Wayland
import "../lib"
import "../services"

// thumbnail grid over ~/wallpaper; stew-wall does the actual set/persist
PanelWindow {
    id: root

    visible: false
    implicitWidth: 3 * 200 + 16
    implicitHeight: 16 + Math.min(Math.max(rows, 1), 3) * 130
    color: "transparent"
    exclusionMode: ExclusionMode.Ignore
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "wallpaper"
    WlrLayershell.keyboardFocus: visible ? WlrKeyboardFocus.OnDemand : WlrKeyboardFocus.None

    property var walls: []
    property string current: ""
    readonly property int rows: Math.ceil(walls.length / 3)

    Component.onCompleted: PanelManager.register("wallpaper", root)

    function toggle() {
        visible ? hide() : show()
    }

    function show() {
        listProc.running = true
        curProc.running = true
        visible = true
        keys.forceActiveFocus()
    }

    function hide() {
        visible = false
    }

    function apply(path) {
        hide()
        current = path
        Quickshell.execDetached([Quickshell.env("HOME") + "/bin/stew", "wall", "set", path])
    }

    Process {
        id: listProc
        command: ["sh", "-c",
            "find ~/wallpaper -maxdepth 1 -type f \\( -iname '*.jpg' -o -iname '*.jpeg' -o -iname '*.png' \\) | sort"]
        stdout: StdioCollector {
            onStreamFinished: root.walls = this.text.trim().split("\n").filter(l => l)
        }
    }

    Process {
        id: curProc
        command: ["sh", "-c", "~/bin/stew wall current"]
        stdout: StdioCollector {
            onStreamFinished: root.current = this.text.trim()
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

        Item {
            id: keys
            anchors.fill: parent
            focus: true
            Keys.onEscapePressed: root.hide()

            GridView {
                id: grid
                anchors.fill: parent
                anchors.margins: 8
                clip: true
                cellWidth: 200
                cellHeight: 130
                model: root.walls

                delegate: MouseArea {
                    id: cell
                    required property var modelData

                    readonly property bool isCurrent: modelData === root.current

                    width: grid.cellWidth
                    height: grid.cellHeight
                    hoverEnabled: true
                    onClicked: root.apply(modelData)

                    Rectangle {
                        anchors.fill: parent
                        anchors.margins: 4
                        color: "transparent"
                        border.color: cell.isCurrent ? Theme.mauve
                            : cell.containsMouse ? Theme.overlay1 : Theme.surface1
                        border.width: cell.isCurrent ? 2 : 1

                        Image {
                            anchors.fill: parent
                            anchors.margins: 3
                            asynchronous: true
                            fillMode: Image.PreserveAspectCrop
                            sourceSize.width: 200
                            source: "file://" + cell.modelData
                        }

                        Rectangle {
                            anchors {
                                left: parent.left
                                right: parent.right
                                bottom: parent.bottom
                                margins: 3
                            }
                            height: 16
                            color: Qt.rgba(0, 0, 0, 0.6)

                            BarText {
                                anchors.centerIn: parent
                                width: parent.width - 8
                                horizontalAlignment: Text.AlignHCenter
                                elide: Text.ElideMiddle
                                font.pixelSize: Theme.fontSizeHint
                                text: cell.modelData.split("/").pop()
                                color: cell.isCurrent ? Theme.mauve : Theme.subtext0
                            }
                        }
                    }
                }
            }
        }
    }
}
