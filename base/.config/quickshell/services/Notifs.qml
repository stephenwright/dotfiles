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
    property var popups: []

    PersistentProperties {
        id: persist
        reloadableId: "notifs"

        property bool dnd: false
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
            if (!persist.dnd)
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

    // hide the toast but keep the notification in history
    function expirePopup(n) {
        popups = popups.filter(p => p !== n)
    }

    function toggleDnd() {
        persist.dnd = !persist.dnd
        if (persist.dnd)
            popups = []
    }

    function dismissAll() {
        popups = []
        for (const n of [...server.trackedNotifications.values])
            n.dismiss()
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
