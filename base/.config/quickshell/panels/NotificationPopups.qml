import QtQuick
import Quickshell
import Quickshell.Wayland
import "../lib"
import "../services"

// Toast popups, top-right, newest on top. Left-click runs the default action
// (opens the sender), right-click dismisses, hover holds the toast open,
// and timeout hides the toast but keeps the notification in the panel.
PanelWindow {
    id: root

    // the notification panel lists the same ones, and would show them through
    visible: Notifs.popups.length > 0 && PanelManager.current?.panelName !== "notifications"
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "qs-toasts"

    anchors {
        top: true
        right: true
    }
    margins.top: Theme.panelMargin
    margins.right: Theme.panelMargin
    implicitWidth: 480
    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            // ScriptModel keeps delegates for unchanged entries, so toast
            // timers and animations survive other popups coming and going
            model: ScriptModel {
                values: Notifs.popups
            }

            Rectangle {
                id: toast
                required property var modelData

                // set before the notification and its actions are destroyed, so
                // the action bindings drop them instead of rebuilding from dying objects
                property bool closed: false
                readonly property var settingsAction: closed ? null : Notifs.findAction(modelData, "settings")
                readonly property var buttons: closed ? [] : Notifs.buttonActions(modelData)
                // bumped when the notification is updated or re-sent
                readonly property real shownAt: Notifs.arrivalOf(modelData)

                width: parent.width
                implicitHeight: body.implicitHeight + 24
                color: Theme.panelBg
                border.color: Notifs.urgencyColor(modelData?.urgency)
                border.width: 2

                Component.onCompleted: enter.start()

                Connections {
                    target: toast.modelData
                    function onClosed() {
                        toast.closed = true
                    }
                }
                onShownAtChanged: if (timer.running) timer.restart()

                ParallelAnimation {
                    id: enter
                    NumberAnimation {
                        target: toast
                        property: "opacity"
                        from: 0
                        to: 1
                        duration: 180
                    }
                    NumberAnimation {
                        target: toast
                        property: "x"
                        from: 40
                        to: 0
                        duration: 180
                        easing.type: Easing.OutCubic
                    }
                }

                Timer {
                    id: timer
                    interval: Notifs.timeoutFor(toast.modelData)
                    running: interval > 0 && !hover.hovered
                    onTriggered: Notifs.expirePopup(toast.modelData)
                }

                HoverHandler {
                    id: hover
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        if (event.button === Qt.RightButton)
                            toast.modelData.dismiss()
                        else
                            Notifs.activate(toast.modelData)
                    }
                }

                Column {
                    id: body
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: Theme.panelPadding
                    spacing: 4

                    Row {
                        width: parent.width
                        spacing: 10

                        Image {
                            id: icon
                            width: 32
                            height: 32
                            sourceSize: Qt.size(64, 64)
                            fillMode: Image.PreserveAspectFit
                            source: toast.modelData?.image
                                || Quickshell.iconPath(toast.modelData?.appIcon ?? "", true)
                            visible: source.toString() !== ""
                        }

                        Column {
                            width: parent.width - (icon.visible ? 42 : 0)
                            spacing: 2

                            Item {
                                width: parent.width
                                height: titleText.implicitHeight

                                BarText {
                                    id: titleText
                                    anchors.left: parent.left
                                    anchors.right: gear.visible ? gear.left : parent.right
                                    anchors.rightMargin: gear.visible ? 6 : 0
                                    elide: Text.ElideRight
                                    font.bold: true
                                    text: (toast.modelData?.appName ?? "")
                                        + (toast.modelData?.summary
                                            ? " · " + toast.modelData.summary : "")
                                }

                                // app-provided settings action (e.g. Chrome's site settings)
                                MouseArea {
                                    id: gear
                                    visible: toast.settingsAction !== null
                                    width: 18
                                    height: parent.height
                                    anchors.right: parent.right
                                    hoverEnabled: true
                                    onClicked: Notifs.invoke(toast.modelData, toast.settingsAction)

                                    BarText {
                                        anchors.centerIn: parent
                                        text: "󰒓"
                                        font.pixelSize: Theme.fontSizeSmall
                                        color: gear.containsMouse ? Theme.mauve : Theme.overlay1
                                    }
                                }
                            }

                            BarText {
                                width: parent.width
                                visible: text !== ""
                                wrapMode: Text.Wrap
                                maximumLineCount: 6
                                elide: Text.ElideRight
                                textFormat: Text.StyledText
                                color: Theme.subtext0
                                text: toast.modelData?.body ?? ""
                            }
                        }
                    }

                    Row {
                        visible: toast.buttons.length > 0
                        spacing: 6

                        Repeater {
                            model: toast.buttons

                            MouseArea {
                                id: actBtn
                                required property var modelData

                                width: actText.implicitWidth + 20
                                height: 22
                                hoverEnabled: true
                                onClicked: Notifs.invoke(toast.modelData, actBtn.modelData)

                                Rectangle {
                                    anchors.fill: parent
                                    color: actBtn.containsMouse
                                        ? Qt.alpha(Theme.mauve, 0.25) : Qt.alpha(Theme.surface0, 0.7)
                                    border.color: actBtn.containsMouse ? Theme.mauve : Theme.surface1
                                    border.width: 1
                                }
                                BarText {
                                    id: actText
                                    anchors.centerIn: parent
                                    text: actBtn.modelData.text
                                }
                            }
                        }
                    }
                }
            }
        }
    }
}
