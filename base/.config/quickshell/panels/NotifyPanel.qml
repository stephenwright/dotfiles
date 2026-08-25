import QtQuick
import Quickshell
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "notifications"
    panelWidth: 420
    contentSpacing: 8
    initialFocusItem: dndSwitch

    property bool historyOpen: false

    onOpening: {
        historyOpen = false
        Notifs.clearDndMissed()
    }

    function focusHeader() {
        Qt.callLater(() => dndSwitch.forceActiveFocus(Qt.TabFocusReason))
    }

    function dismiss(notification) {
        notification.dismiss()
        focusHeader()
    }

    function dismissAll() {
        Notifs.dismissAll()
        focusHeader()
    }

    function deleteHistory(index) {
        Notifs.deleteFromHistory(index)
        focusHeader()
    }

    Item {
        width: parent.width
        height: 18

        BarText {
            anchors.verticalCenter: parent.verticalCenter
            text: "Notifications"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.overlay1
        }

        // DND toggle
        PanelToggle {
            id: dndSwitch
            width: 34
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: clearBtn.left
            anchors.rightMargin: 12
            checked: Notifs.dnd
            accessibleName: "Do not disturb"
            onToggled: Notifs.toggleDnd()

            Rectangle {
                anchors.fill: parent
                color: Notifs.dnd ? Qt.alpha(Theme.red, 0.4) : Theme.surface1

                Rectangle {
                    width: 12
                    height: 12
                    anchors.verticalCenter: parent.verticalCenter
                    x: Notifs.dnd ? parent.width - width - 2 : 2
                    color: Notifs.dnd ? Theme.red : Theme.overlay0
                }
            }
            BarText {
                anchors.right: parent.left
                anchors.rightMargin: 6
                anchors.verticalCenter: parent.verticalCenter
                text: "dnd"
                font.pixelSize: Theme.fontSizeSmall
                color: Notifs.dnd ? Theme.red : Theme.overlay1
            }
        }

        PanelButton {
            id: clearBtn
            width: 20
            height: parent.height
            anchors.right: parent.right
            accessibleName: "Dismiss all notifications"
            onClicked: root.dismissAll()
            BarText {
                anchors.centerIn: parent
                text: "󰎟"
                font.pixelSize: Theme.fontSize
                color: clearBtn.hovered || clearBtn.showFocus ? Theme.mauve : Theme.overlay1
            }
        }
    }

    BarText {
        visible: Notifs.tracked.values.length === 0
        text: "no notifications"
        color: Theme.overlay0
    }

    ListView {
        id: list
        width: parent.width
        height: Math.min(480, contentHeight)
        visible: Notifs.tracked.values.length > 0
        clip: true
        spacing: 6
        model: Notifs.tracked.values.slice().reverse()

        delegate: PanelButton {
            id: row
            required property var modelData
            required property int index

            property bool expanded: false

            width: ListView.view.width
            height: inner.implicitHeight + 12
            accessibleName: row.modelData.appName + " " + row.modelData.summary
            borderColor: Qt.alpha(Notifs.urgencyColor(row.modelData.urgency), 0.5)
            onClicked: expanded = !expanded
            onActiveFocusChanged: {
                if (activeFocus)
                    list.positionViewAtIndex(index, ListView.Contain)
            }
            onKeyPressed: event => {
                if (event.key === Qt.Key_Delete || event.key === Qt.Key_X) {
                    root.dismiss(row.modelData)
                    event.accepted = true
                }
            }

            Column {
                id: inner
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                Item {
                    width: parent.width
                    height: 16

                    BarText {
                        anchors.left: parent.left
                        anchors.right: rowTime.left
                        anchors.rightMargin: 6
                        elide: Text.ElideRight
                        font.bold: true
                        text: row.modelData.appName
                            + (row.modelData.summary ? " · " + row.modelData.summary : "")
                    }
                    BarText {
                        id: rowTime
                        anchors.right: closeBtn.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeHint
                        color: Theme.overlay0
                        text: Notifs.timeOf(row.modelData)
                    }
                    PanelButton {
                        id: closeBtn
                        width: 16
                        height: parent.height
                        anchors.right: parent.right
                        accessibleName: "Dismiss notification"
                        onClicked: root.dismiss(row.modelData)
                        BarText {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Theme.fontSizeSmall
                            color: closeBtn.hovered || closeBtn.showFocus ? Theme.red : Theme.overlay1
                        }
                    }
                }

                BarText {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: row.expanded ? 20 : 2
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    color: Theme.subtext0
                    text: row.modelData.body
                }

                Row {
                    visible: row.expanded && row.modelData.actions.length > 0
                    spacing: 6

                    Repeater {
                        model: row.modelData.actions

                        PanelButton {
                            id: actBtn
                            required property var modelData

                            width: actText.implicitWidth + 16
                            height: 20
                            accessibleName: actBtn.modelData.text
                            borderColor: Theme.surface1
                            onClicked: actBtn.modelData.invoke()
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

    // dismissed notifications (plain-data snapshots), collapsed by default
    Item {
        width: parent.width
        height: 18
        visible: Notifs.history.length > 0

        PanelButton {
            id: histToggle
            anchors.left: parent.left
            width: histLabel.implicitWidth
            height: parent.height
            accessibleName: root.historyOpen ? "Collapse notification history"
                : "Expand notification history"
            onClicked: root.historyOpen = !root.historyOpen

            BarText {
                id: histLabel
                anchors.verticalCenter: parent.verticalCenter
                text: (root.historyOpen ? "▾ " : "▸ ")
                    + "history (" + Notifs.history.length + ")"
                font.pixelSize: Theme.fontSizeSmall
                color: histToggle.hovered || histToggle.showFocus ? Theme.text : Theme.overlay1
            }
        }

        PanelButton {
            id: histClearBtn
            visible: root.historyOpen
            width: 20
            height: parent.height
            anchors.right: parent.right
            accessibleName: "Clear notification history"
            onClicked: {
                Notifs.clearHistory()
                root.focusHeader()
            }
            BarText {
                anchors.centerIn: parent
                text: "󰎟"
                font.pixelSize: 13
                color: histClearBtn.hovered || histClearBtn.showFocus ? Theme.mauve : Theme.overlay1
            }
        }
    }

    ListView {
        id: histList
        width: parent.width
        height: Math.min(240, contentHeight)
        visible: root.historyOpen && Notifs.history.length > 0
        clip: true
        spacing: 6
        model: Notifs.history

        delegate: PanelButton {
            id: histRow
            required property var modelData
            required property int index

            property bool expanded: false

            width: ListView.view.width
            height: histInner.implicitHeight + 12
            accessibleName: histRow.modelData.appName + " " + histRow.modelData.summary
            borderColor: Qt.alpha(Notifs.urgencyColor(histRow.modelData.urgency), 0.2)
            onClicked: expanded = !expanded
            onActiveFocusChanged: {
                if (activeFocus)
                    histList.positionViewAtIndex(index, ListView.Contain)
            }
            onKeyPressed: event => {
                if (event.key === Qt.Key_Delete || event.key === Qt.Key_X) {
                    root.deleteHistory(histRow.index)
                    event.accepted = true
                }
            }

            Column {
                id: histInner
                anchors.left: parent.left
                anchors.right: parent.right
                anchors.top: parent.top
                anchors.margins: 6
                spacing: 2

                Item {
                    width: parent.width
                    height: 16

                    BarText {
                        anchors.left: parent.left
                        anchors.right: histTime.left
                        anchors.rightMargin: 6
                        elide: Text.ElideRight
                        color: Theme.overlay1
                        text: histRow.modelData.appName
                            + (histRow.modelData.summary
                                ? " · " + histRow.modelData.summary : "")
                    }
                    BarText {
                        id: histTime
                        anchors.right: histDelBtn.left
                        anchors.rightMargin: 6
                        anchors.verticalCenter: parent.verticalCenter
                        font.pixelSize: Theme.fontSizeHint
                        color: Theme.overlay0
                        text: Qt.formatTime(new Date(histRow.modelData.time), "hh:mm")
                    }
                    PanelButton {
                        id: histDelBtn
                        width: 16
                        height: parent.height
                        anchors.right: parent.right
                        accessibleName: "Delete history entry"
                        onClicked: root.deleteHistory(histRow.index)
                        BarText {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Theme.fontSizeSmall
                            color: histDelBtn.hovered || histDelBtn.showFocus ? Theme.red : Theme.overlay1
                        }
                    }
                }

                BarText {
                    width: parent.width
                    visible: text !== ""
                    wrapMode: Text.Wrap
                    maximumLineCount: histRow.expanded ? 20 : 2
                    elide: Text.ElideRight
                    textFormat: Text.StyledText
                    color: Theme.overlay0
                    text: histRow.modelData.body
                }
            }
        }
    }
}
