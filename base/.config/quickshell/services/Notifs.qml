pragma Singleton
import QtQuick
import Quickshell
import Quickshell.Io
import Quickshell.Services.Notifications

// Notification daemon (replaces mako). Tracked notifications are the live
// list in NotifyPanel; popups holds the currently-toasted ones.
Singleton {
    id: root

    readonly property bool dnd: store.dnd
    readonly property int missedWhileDnd: store.dndMissed
    readonly property var history: store.history
    readonly property var tracked: server.trackedNotifications
    readonly property var arrivals: JSON.parse(persist.arrivalsJson || "{}")
    property var popups: []

    readonly property int maxPopups: 5
    readonly property int maxTracked: 100
    readonly property int maxHistory: 100
    readonly property int dedupWindowMs: 5000

    // live notifications, grouped by app (newest group first), newest first within a group
    readonly property var grouped: {
        const groups = new Map()
        for (const n of tracked.values) {
            const k = groupKey(n)
            if (!groups.has(k))
                groups.set(k, [])
            groups.get(k).push(n)
        }
        const byNewest = (a, b) => arrivalOf(b) - arrivalOf(a)
        return [...groups.values()]
            .map(g => g.sort(byNewest))
            .sort((a, b) => byNewest(a[0], b[0]))
            .reduce((all, g) => all.concat(g), [])
    }

    // history and DND survive restarts; arrival times only need to survive
    // reloads, like the keepOnReload notifications they describe
    FileView {
        path: Quickshell.statePath("notifications.json")
        blockLoading: true
        printErrors: false
        watchChanges: true
        onFileChanged: reload()
        onAdapterUpdated: writeAdapter()
        onLoadFailed: error => {
            if (error === FileViewError.FileNotFound)
                writeAdapter()
        }

        JsonAdapter {
            id: store

            property bool dnd: false
            property int dndMissed: 0
            property var history: []
        }
    }

    // objects/arrays in persisted vars don't survive reloads reliably
    // ("JSValue can't be reassigned to another engine") — persist a JSON string
    PersistentProperties {
        id: persist
        reloadableId: "notifs"

        property string arrivalsJson: "{}"
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
            const dup = root.findDuplicate(n)
            if (dup) {
                // left untracked, so the copy is discarded
                root.show(dup)
                return
            }
            n.tracked = true
            root.setArrival(n, Date.now())
            if (store.dnd)
                store.dndMissed++
            else
                root.pushPopup(n)
            const all = server.trackedNotifications.values
            if (all.length > root.maxTracked)
                all[0].dismiss()
        }
    }

    // built from the tracked model rather than in onNotification so
    // notifications kept across a config reload are wired up again
    Variants {
        model: server.trackedNotifications.values

        Connections {
            required property var modelData
            target: modelData

            function onClosed() {
                root.archive(modelData)
            }
            // replacements update in place without a new onNotification
            function onSummaryChanged() {
                root.show(modelData)
            }
            function onBodyChanged() {
                root.show(modelData)
            }
        }
    }

    function groupKey(n) {
        return n.desktopEntry || n.appName
    }

    // mako-parity defaults when the client leaves the timeout to us; 0 = sticky
    function timeoutFor(n) {
        if (!n)
            return 0
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

    // "default" is the click action and "settings" gets a gear; the rest are buttons
    function findAction(n, identifier) {
        if (!n)
            return null
        for (let i = 0; i < n.actions.length; i++)
            if (n.actions[i].identifier === identifier)
                return n.actions[i]
        return null
    }

    function buttonActions(n) {
        const out = []
        if (!n)
            return out
        for (let i = 0; i < n.actions.length; i++) {
            const a = n.actions[i]
            if (a.identifier !== "default" && a.identifier !== "settings")
                out.push(a)
        }
        return out
    }

    // invoking closes the notification unless it's resident; resident ones
    // stay in the panel but shouldn't keep toasting
    function invoke(n, action) {
        const resident = n.resident
        action.invoke()
        if (resident)
            expirePopup(n)
    }

    function activate(n) {
        const a = findAction(n, "default")
        if (a)
            invoke(n, a)
        else
            expirePopup(n)
    }

    function arrivalOf(n) {
        return n ? arrivals[n.id] ?? 0 : 0
    }

    function timeOf(n) {
        const t = arrivalOf(n)
        return t ? Qt.formatTime(new Date(t), "hh:mm") : ""
    }

    function setArrival(n, time) {
        const a = Object.assign({}, arrivals)
        if (time)
            a[n.id] = time
        else
            delete a[n.id]
        persist.arrivalsJson = JSON.stringify(a)
    }

    function findDuplicate(n) {
        const now = Date.now()
        for (const t of tracked.values)
            if (t.appName === n.appName && t.summary === n.summary && t.body === n.body
                    && now - arrivalOf(t) < dedupWindowMs)
                return t
        return null
    }

    // newest on top; overflow drops the oldest non-critical toast first
    function pushPopup(n) {
        const next = [n, ...popups.filter(p => p !== n)]
        while (next.length > maxPopups) {
            let i = next.length - 1
            while (i > 0 && next[i].urgency === NotificationUrgency.Critical)
                i--
            next.splice(i > 0 ? i : next.length - 1, 1)
        }
        popups = next
    }

    // re-toast an existing notification (update or duplicate); the new
    // arrival time restarts its toast timer
    function show(n) {
        setArrival(n, Date.now())
        if (!store.dnd)
            pushPopup(n)
    }

    // hide the toast but keep the notification in the panel
    function expirePopup(n) {
        popups = popups.filter(p => p !== n)
    }

    function toggleDnd() {
        store.dnd = !store.dnd
        store.dndMissed = 0
        if (store.dnd)
            popups = []
    }

    function clearDndMissed() {
        store.dndMissed = 0
    }

    function dismissAll() {
        popups = []
        for (const n of [...tracked.values])
            n.dismiss()
    }

    function dismissGroup(key) {
        for (const n of [...tracked.values])
            if (groupKey(n) === key)
                n.dismiss()
    }

    // Notification objects die after close; history keeps a plain-data snapshot
    function archive(n) {
        expirePopup(n)
        const entry = {
            appName: n.appName,
            desktopEntry: n.desktopEntry,
            summary: n.summary,
            body: n.body,
            urgency: n.urgency,
            time: arrivalOf(n) || Date.now()
        }
        store.history = [entry, ...history].slice(0, maxHistory)
        setArrival(n, 0)
    }

    function deleteFromHistory(i) {
        const h = [...history]
        h.splice(i, 1)
        store.history = h
    }

    function clearHistory() {
        store.history = []
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
