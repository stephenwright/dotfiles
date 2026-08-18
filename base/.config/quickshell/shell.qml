//@ pragma UseQApplication
import Quickshell
import "bar"
import "panels"

ShellRoot {
    Variants {
        model: Quickshell.screens

        Bar {}
    }

    Launcher {}
    NotificationPopups {}
}
