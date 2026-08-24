import QtQuick
import Quickshell
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "notifications"
    panelWidth: 420
    contentSpacing: 8
    wantsKeyboard: true

    property int selected: 0
    property int expandedIndex: -1
    property bool historyOpen: false

    onOpening: {
        selected = 0
        expandedIndex = -1
        historyOpen = false
        Notifs.clearDndMissed()
    }

    onKeyPressed: event => {
        if (event.key === Qt.Key_Down || event.key === Qt.Key_Tab || event.key === Qt.Key_J)
            selected = Math.min(selected + 1, list.count - 1)
        else if (event.key === Qt.Key_Up || event.key === Qt.Key_K)
            selected = Math.max(selected - 1, 0)
        else if (event.key === Qt.Key_Return || event.key === Qt.Key_Enter)
            expandedIndex = expandedIndex === selected ? -1 : selected
        else if (event.key === Qt.Key_Delete || event.key === Qt.Key_X)
            list.model[selected]?.dismiss()
        else
            return
        list.positionViewAtIndex(Math.max(0, selected), ListView.Contain)
        event.accepted = true
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
        MouseArea {
            id: dndSwitch
            width: 34
            height: 16
            anchors.verticalCenter: parent.verticalCenter
            anchors.right: clearBtn.left
            anchors.rightMargin: 12
            onClicked: Notifs.toggleDnd()

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

        MouseArea {
            id: clearBtn
            width: 20
            height: parent.height
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: Notifs.dismissAll()
            BarText {
                anchors.centerIn: parent
                text: "󰎟"
                font.pixelSize: Theme.fontSize
                color: clearBtn.containsMouse ? Theme.mauve : Theme.overlay1
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

        delegate: Item {
            id: row
            required property var modelData
            required property int index

            readonly property bool expanded: root.expandedIndex === index
            readonly property bool isSelected: root.selected === index

            width: ListView.view.width
            height: inner.implicitHeight + 12

            Rectangle {
                anchors.fill: parent
                color: row.isSelected ? Qt.alpha(Theme.surface0, 0.7) : "transparent"
                border.color: Qt.alpha(Notifs.urgencyColor(row.modelData.urgency), 0.5)
                border.width: 1
            }

            MouseArea {
                id: rowArea
                anchors.fill: parent
                hoverEnabled: true
                onEntered: root.selected = row.index
                onClicked: root.expandedIndex = row.expanded ? -1 : row.index
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
                    MouseArea {
                        id: closeBtn
                        width: 16
                        height: parent.height
                        anchors.right: parent.right
                        hoverEnabled: true
                        onClicked: row.modelData.dismiss()
                        BarText {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Theme.fontSizeSmall
                            color: closeBtn.containsMouse ? Theme.red : Theme.overlay1
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

                        MouseArea {
                            id: actBtn
                            required property var modelData

                            width: actText.implicitWidth + 16
                            height: 20
                            hoverEnabled: true
                            onClicked: actBtn.modelData.invoke()

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

    // dismissed notifications (plain-data snapshots), collapsed by default
    Item {
        width: parent.width
        height: 18
        visible: Notifs.history.length > 0

        MouseArea {
            id: histToggle
            anchors.left: parent.left
            width: histLabel.implicitWidth
            height: parent.height
            hoverEnabled: true
            onClicked: root.historyOpen = !root.historyOpen

            BarText {
                id: histLabel
                anchors.verticalCenter: parent.verticalCenter
                text: (root.historyOpen ? "▾ " : "▸ ")
                    + "history (" + Notifs.history.length + ")"
                font.pixelSize: Theme.fontSizeSmall
                color: histToggle.containsMouse ? Theme.text : Theme.overlay1
            }
        }

        MouseArea {
            id: histClearBtn
            visible: root.historyOpen
            width: 20
            height: parent.height
            anchors.right: parent.right
            hoverEnabled: true
            onClicked: Notifs.clearHistory()
            BarText {
                anchors.centerIn: parent
                text: "󰎟"
                font.pixelSize: 13
                color: histClearBtn.containsMouse ? Theme.mauve : Theme.overlay1
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

        delegate: Item {
            id: histRow
            required property var modelData
            required property int index

            property bool expanded: false

            width: ListView.view.width
            height: histInner.implicitHeight + 12

            Rectangle {
                anchors.fill: parent
                color: "transparent"
                border.color: Qt.alpha(Notifs.urgencyColor(histRow.modelData.urgency), 0.2)
                border.width: 1
            }

            MouseArea {
                anchors.fill: parent
                onClicked: histRow.expanded = !histRow.expanded
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
                    MouseArea {
                        id: histDelBtn
                        width: 16
                        height: parent.height
                        anchors.right: parent.right
                        hoverEnabled: true
                        onClicked: Notifs.deleteFromHistory(histRow.index)
                        BarText {
                            anchors.centerIn: parent
                            text: "✕"
                            font.pixelSize: Theme.fontSizeSmall
                            color: histDelBtn.containsMouse ? Theme.red : Theme.overlay1
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
