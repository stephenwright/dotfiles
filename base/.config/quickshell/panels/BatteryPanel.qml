import QtQuick
import Quickshell.Services.UPower
import "../lib"
import "../services"

Panel {
    id: root

    panelName: "battery"

    // anchorItem is the Battery bar widget; reuse its device lookup
    readonly property var bat: anchorItem ? anchorItem.bat : null
    readonly property int pct: anchorItem ? anchorItem.pct : 0

    readonly property var profileOpts: {
        const l = [
            { label: "saver", value: PowerProfile.PowerSaver },
            { label: "balanced", value: PowerProfile.Balanced },
        ]
        if (PowerProfiles.hasPerformanceProfile)
            l.push({ label: "performance", value: PowerProfile.Performance })
        return l
    }

    function fmtTime(s) {
        const h = Math.floor(s / 3600)
        const m = Math.round((s % 3600) / 60)
        return (h > 0 ? h + "h " : "") + m + "m"
    }

    readonly property string stateLine: {
        if (!bat)
            return ""
        switch (bat.state) {
        case UPowerDeviceState.Charging:
            return "charging" + (bat.timeToFull > 0 ? " · " + fmtTime(bat.timeToFull) + " to full" : "")
        case UPowerDeviceState.Discharging:
            return "discharging" + (bat.timeToEmpty > 0 ? " · " + fmtTime(bat.timeToEmpty) + " left" : "")
        case UPowerDeviceState.FullyCharged:
            return "fully charged"
        case UPowerDeviceState.PendingCharge:
            return "plugged in"
        default:
            return ""
        }
    }

    PanelHeader {
        icon: "󰁹"
        title: "Battery"
        subtitle: root.stateLine
    }

    MeterRow {
        label: "Charge"
        detail: root.pct + "%"
        frac: root.pct / 100
        barColor: !root.bat ? Theme.mauve
            : UPower.onBattery && root.pct <= 15 ? Theme.red
            : UPower.onBattery && root.pct <= 30 ? Theme.yellow
            : Theme.mauve
    }

    Item {
        width: parent.width
        height: 14
        visible: root.bat !== null && root.bat.healthSupported

        BarText {
            anchors.left: parent.left
            text: "Health"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.subtext0
        }
        BarText {
            anchors.right: parent.right
            text: root.bat ? Math.round(root.bat.healthPercentage) + "%" : ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.text
        }
    }

    Item {
        width: parent.width
        height: 14
        visible: root.bat !== null && root.bat.changeRate > 0

        BarText {
            anchors.left: parent.left
            text: "Power draw"
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.subtext0
        }
        BarText {
            anchors.right: parent.right
            text: root.bat ? root.bat.changeRate.toFixed(1) + " W" : ""
            font.pixelSize: Theme.fontSizeSmall
            color: Theme.text
        }
    }

    SectionLabel {
        text: "Profile"
    }

    Row {
        spacing: 6

        Repeater {
            id: profiles
            model: root.profileOpts

            SegmentButton {
                required property var modelData

                width: (root.contentWidth - 6 * (root.profileOpts.length - 1))
                    / root.profileOpts.length
                current: PowerProfiles.profile === modelData.value
                label: modelData.label
                accessibleName: "Power profile " + modelData.label
                onClicked: PowerProfiles.profile = modelData.value
            }
        }
    }

    onOpening: {
        const index = root.profileOpts.findIndex(
            option => option.value === PowerProfiles.profile)
        initialFocusItem = profiles.itemAt(Math.max(0, index))
    }
}
