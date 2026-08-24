//@ pragma UseQApplication
import Quickshell
import "bar"
import "panels"
import "services"

ShellRoot {
    // touch the lazy Hypr singleton so provider detection runs before first dispatch
    readonly property bool hyprLua: Hypr.lua

    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Launcher {}
    ClipboardPanel {}
    WallpaperPanel {}
    NotificationPopups {}
}
