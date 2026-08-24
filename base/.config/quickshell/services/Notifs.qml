pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon (replaces mako). Tracked notifications form the
// history shown in NotifyPanel; popups holds the currently-toasted ones.
Singleton {
    id: root

    readonly property bool dnd: persist.dnd
    readonly property var tracked: server.trackedNotifications
    readonly property var history: JSON.parse(persist.historyJson || "[]")
    readonly property int missedWhileDnd: persist.dndMissed
    property var popups: []

    // objects/arrays in persisted vars don't survive reloads reliably
    // ("JSValue can't be reassigned to another engine") — persist JSON strings
    PersistentProperties {
        id: persist
        reloadableId: "notifs"

        property bool dnd: false
        property string historyJson: "[]"
        property string arrivalsJson: "{}"   // notification id -> arrival ms
        property int dndMissed: 0
    }

    NotificationServer {
        id: server
        actionsSupported: true
        imageSupported: true
        bodySupported: true
        bodyMarkupSupported: true
        persistenceSupported: true
        keepOnReload: true

        onNotification: n => {
            n.tracked = true
            const a = root.arrivals()
            a[n.id] = Date.now()
            persist.arrivalsJson = JSON.stringify(a)
            n.closed.connect(() => root.archive(n))
            if (persist.dnd)
                persist.dndMissed++
            else
                root.popups = root.popups.concat([n])
            const all = server.trackedNotifications.values
            if (all.length > 100)
                all[0].dismiss()
        }
    }

    // mako-parity defaults when the client leaves the timeout to us; 0 = sticky
    function timeoutFor(n) {
        if (n.expireTimeout >= 0)
            return n.expireTimeout
        return n.urgency === NotificationUrgency.Low ? 4000
             : n.urgency === NotificationUrgency.Critical ? 0
             : 8000
    }

    function urgencyColor(u) {
        return u === NotificationUrgency.Low ? Theme.green
             : u === NotificationUrgency.Critical ? Theme.red
             : Theme.blue
    }

    function arrivals() {
        return JSON.parse(persist.arrivalsJson || "{}")
    }

    function arrivalOf(n) {
        return arrivals()[n.id] ?? 0
    }

    function timeOf(n) {
        const t = arrivalOf(n)
        return t ? Qt.formatTime(new Date(t), "hh:mm") : ""
    }

    // hide the toast but keep the notification in history
    function expirePopup(n) {
        popups = popups.filter(p => p !== n)
    }

    function toggleDnd() {
        persist.dnd = !persist.dnd
        persist.dndMissed = 0
        if (persist.dnd)
            popups = []
    }

    function clearDndMissed() {
        persist.dndMissed = 0
    }

    function dismissAll() {
        popups = []
        for (const n of [...server.trackedNotifications.values])
            n.dismiss()
    }

    // Notification objects die after close; history keeps a plain-data snapshot
    function archive(n) {
        const entry = {
            appName: n.appName,
            summary: n.summary,
            body: n.body,
            urgency: n.urgency,
            time: arrivalOf(n) || Date.now()
        }
        persist.historyJson = JSON.stringify([entry, ...history].slice(0, 100))
        const a = arrivals()
        delete a[n.id]
        persist.arrivalsJson = JSON.stringify(a)
    }

    function deleteFromHistory(i) {
        const h = [...history]
        h.splice(i, 1)
        persist.historyJson = JSON.stringify(h)
    }

    function clearHistory() {
        persist.historyJson = "[]"
    }

    IpcHandler {
        target: "notifs"

        function dismissAll(): void {
            root.dismissAll()
        }
        function toggleDnd(): void {
            root.toggleDnd()
        }
    }
}
