import QtQuick
import Quickshell
import Quickshell.Wayland
import "../lib"
import "../services"

// Toast popups, top-center (top-only anchor centers horizontally).
// Left-click invokes the default action, right-click dismisses,
// timeout hides the toast but keeps it in history.
PanelWindow {
    id: root

    visible: Notifs.popups.length > 0
    color: "transparent"
    exclusiveZone: 0
    WlrLayershell.layer: WlrLayer.Overlay
    WlrLayershell.namespace: "notifications"

    anchors {
        top: true
    }
    margins.top: 8
    implicitWidth: 480
    implicitHeight: column.implicitHeight

    Column {
        id: column
        width: parent.width
        spacing: 8

        Repeater {
            model: Notifs.popups.slice(0, 5)

            Rectangle {
                id: toast
                required property var modelData

                width: parent.width
                implicitHeight: body.implicitHeight + 24
                color: Theme.base
                border.color: Notifs.urgencyColor(modelData.urgency)
                border.width: 2

                // Notification objects die after close; drop the popup ref
                Connections {
                    target: toast.modelData
                    function onClosed() {
                        Notifs.expirePopup(toast.modelData)
                    }
                }

                Timer {
                    interval: Notifs.timeoutFor(toast.modelData)
                    running: interval > 0
                    onTriggered: Notifs.expirePopup(toast.modelData)
                }

                MouseArea {
                    anchors.fill: parent
                    acceptedButtons: Qt.LeftButton | Qt.RightButton
                    onClicked: event => {
                        if (event.button === Qt.RightButton) {
                            toast.modelData.dismiss()
                        } else if (toast.modelData.actions.length > 0) {
                            toast.modelData.actions[0].invoke()
                            Notifs.expirePopup(toast.modelData)
                        } else {
                            Notifs.expirePopup(toast.modelData)
                        }
                    }
                }

                Column {
                    id: body
                    anchors.left: parent.left
                    anchors.right: parent.right
                    anchors.top: parent.top
                    anchors.margins: 12
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
                            source: toast.modelData.image
                                || Quickshell.iconPath(toast.modelData.appIcon, true)
                            visible: source.toString() !== ""
                        }

                        Column {
                            width: parent.width - (icon.visible ? 42 : 0)
                            spacing: 2

                            BarText {
                                width: parent.width
                                elide: Text.ElideRight
                                font.bold: true
                                text: toast.modelData.appName
                                    + (toast.modelData.summary
                                        ? " · " + toast.modelData.summary : "")
                            }
                            BarText {
                                width: parent.width
                                visible: text !== ""
                                wrapMode: Text.Wrap
                                maximumLineCount: 4
                                elide: Text.ElideRight
                                textFormat: Text.StyledText
                                font.pixelSize: 11
                                color: Theme.subtext0
                                text: toast.modelData.body
                            }
                        }
                    }

                    Row {
                        visible: toast.modelData.actions.length > 0
                        spacing: 6

                        Repeater {
                            model: toast.modelData.actions

                            MouseArea {
                                id: actBtn
                                required property var modelData

                                width: actText.implicitWidth + 20
                                height: 22
                                hoverEnabled: true
                                onClicked: {
                                    actBtn.modelData.invoke()
                                    Notifs.expirePopup(toast.modelData)
                                }

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
                                    font.pixelSize: 11
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
