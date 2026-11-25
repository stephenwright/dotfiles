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

    // live notifications grouped by app; ScriptModel keeps delegates (and
    // their expanded state) when other notifications arrive or close
    ListView {
        id: list
        width: parent.width
        height: Math.min(480, contentHeight)
        visible: Notifs.tracked.values.length > 0
        clip: true
        spacing: 6
        model: ScriptModel {
            values: Notifs.grouped
        }

        delegate: Column {
            id: entry
            required property var modelData
            required property int index

            readonly property string key: modelData ? Notifs.groupKey(modelData) : ""
            readonly property var siblings: Notifs.grouped.filter(n => Notifs.groupKey(n) === key)
            // see NotificationPopups: keep action bindings off dying objects
            property bool closed: false
            readonly property var settingsAction: closed ? null : Notifs.findAction(modelData, "settings")
            readonly property var defaultAction: closed ? null : Notifs.findAction(modelData, "default")
            readonly property var buttons: closed ? [] : Notifs.buttonActions(modelData)

            width: ListView.view.width
            spacing: 4

            Connections {
                target: entry.modelData
                function onClosed() {
                    entry.closed = true
                }
            }

            // group header, on the newest notification of each app
            Item {
                visible: entry.siblings[0] === entry.modelData
                width: parent.width
                height: 18

                BarText {
                    anchors.left: parent.left
                    anchors.right: groupClear.visible ? groupClear.left : parent.right
                    anchors.verticalCenter: parent.verticalCenter
                    elide: Text.ElideRight
                    font.pixelSize: Theme.fontSizeSmall
                    color: Theme.overlay1
                    text: (entry.modelData?.appName ?? "")
                        + (entry.siblings.length > 1 ? " (" + entry.siblings.length + ")" : "")
                }
                PanelButton {
                    id: groupClear
                    visible: entry.siblings.length > 1
                    width: 20
                    height: parent.height
                    anchors.right: parent.right
                    accessibleName: "Dismiss all " + (entry.modelData?.appName ?? "") + " notifications"
                    onClicked: {
                        Notifs.dismissGroup(entry.key)
                        root.focusHeader()
                    }
                    BarText {
                        anchors.centerIn: parent
                        text: "󰎟"
                        font.pixelSize: Theme.fontSizeSmall
                        color: groupClear.hovered || groupClear.showFocus ? Theme.mauve : Theme.overlay1
                    }
                }
            }

            PanelButton {
                id: row

                property bool expanded: false

                width: parent.width
                height: inner.implicitHeight + 12
                accessibleName: (entry.modelData?.appName ?? "") + " " + (entry.modelData?.summary ?? "")
                borderColor: Qt.alpha(Notifs.urgencyColor(entry.modelData?.urgency), 0.5)
                onClicked: expanded = !expanded
                onActiveFocusChanged: {
                    if (activeFocus)
                        list.positionViewAtIndex(entry.index, ListView.Contain)
                }
                onKeyPressed: event => {
                    if (event.key === Qt.Key_Delete || event.key === Qt.Key_X) {
                        root.dismiss(entry.modelData)
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
                            text: entry.modelData?.summary || entry.modelData?.appName || ""
                        }
                        BarText {
                            id: rowTime
                            anchors.right: gearBtn.visible ? gearBtn.left : closeBtn.left
                            anchors.rightMargin: 6
                            anchors.verticalCenter: parent.verticalCenter
                            font.pixelSize: Theme.fontSizeHint
                            color: Theme.overlay0
                            text: Notifs.timeOf(entry.modelData)
                        }
                        PanelButton {
                            id: gearBtn
                            visible: entry.settingsAction !== null
                            width: 16
                            height: parent.height
                            anchors.right: closeBtn.left
                            anchors.rightMargin: 4
                            accessibleName: "Notification settings"
                            onClicked: {
                                Notifs.invoke(entry.modelData, entry.settingsAction)
                                root.close()
                            }
                            BarText {
                                anchors.centerIn: parent
                                text: "󰒓"
                                font.pixelSize: Theme.fontSizeSmall
                                color: gearBtn.hovered || gearBtn.showFocus ? Theme.mauve : Theme.overlay1
                            }
                        }
                        PanelButton {
                            id: closeBtn
                            width: 16
                            height: parent.height
                            anchors.right: parent.right
                            accessibleName: "Dismiss notification"
                            onClicked: root.dismiss(entry.modelData)
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
                        text: entry.modelData?.body ?? ""
                    }

                    // "open" runs the default action, which toasts do on click
                    Row {
                        visible: row.expanded && (entry.defaultAction !== null || entry.buttons.length > 0)
                        spacing: 6

                        Repeater {
                            model: (entry.defaultAction ? [entry.defaultAction] : []).concat(entry.buttons)

                            PanelButton {
                                id: actBtn
                                required property var modelData

                                readonly property string label: modelData.identifier === "default"
                                    ? "open" : modelData.text

                                width: actText.implicitWidth + 16
                                height: 20
                                accessibleName: label
                                borderColor: Theme.surface1
                                onClicked: {
                                    Notifs.invoke(entry.modelData, actBtn.modelData)
                                    if (actBtn.modelData.identifier === "default")
                                        root.close()
                                }
                                BarText {
                                    id: actText
                                    anchors.centerIn: parent
                                    text: actBtn.label
                                }
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
