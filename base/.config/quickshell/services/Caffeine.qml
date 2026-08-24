pragma Singleton
import QtQuick
import Quickshell

// global stay-awake state; bar widgets bind IdleInhibitors to it
Singleton {
    property alias on: persist.on

    PersistentProperties {
        id: persist
        reloadableId: "caffeine"

        property bool on: false
    }
}
