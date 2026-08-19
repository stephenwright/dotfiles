# quickshell config

Bar, notification daemon, and panel/picker UI for Hyprland. Replaced waybar +
mako + most fuzzel dialogs (Aug 2026). Catppuccin Macchiato throughout.

## Layout

```
shell.qml     entry: one Bar per screen + global windows (Launcher,
              ClipboardPanel, WallpaperPanel, NotificationPopups)
services/     singletons only — the one dir with a hand-written qmldir.
              Theme, Commands (launcher tree), PanelManager, Notifs
              (notification daemon), Session (actions), Fuzzy (matcher)
lib/          shared components: Panel (base for anchored panels),
              BarWidget (clickable bar item), BarText, VolSlider, MeterRow, NetRow
bar/          Bar.qml + one file per widget
panels/       anchored panels (derive from lib/Panel) + standalone centered
              windows (Launcher-style: Clipboard, Wallpaper) + NotificationPopups
```

Rules of thumb:

- Singletons live in `services/` and must be listed in `services/qmldir`
  (`singleton Name File.qml`). Other dirs need no qmldir; files import
  siblings' dirs relatively (`import "../lib"`).
- State + actions shared by ≥2 consumers go in a service singleton; bar
  widgets, panels, the launcher, and IPC keybinds all call the same function.
  One-off exec calls stay inline.

## How panels work

`lib/Panel.qml` owns chrome, positioning (centered over `anchorItem`, clamped
to screen), and dismissal. `services/PanelManager.qml` keeps at most one open.

- Every panel registers by `panelName`; keybinds/scripts open them with
  `qs ipc call panels toggle <name>` (session, notifications, battery, …).
  PanelManager picks the instance on the focused monitor (panels are
  per-screen — each Bar instantiates its own).
- One-click switching works because the panel's HyprlandFocusGrab includes
  the **bar window**: clicking another widget reaches that widget (which
  toggles via PanelManager) instead of merely clearing the grab. Don't
  "simplify" that windows list.
- `wantsKeyboard: true` gives the panel OnDemand keyboard focus when open:
  Escape closes (handled in the base), everything else arrives via the
  `keyPressed(event)` signal. See SessionPanel (arrows/jk/enter + two-click
  arm for destructive actions) and NotifyPanel.
- Per-open refresh goes in the `opening()` signal handler, not
  `onVisibleChanged`.
- Standalone windows (Launcher, Clipboard, Wallpaper) manage themselves
  (`toggle()/show()/hide()` + own grab); PanelManager.toggleByName duck-types
  so they can still be registered and launched by name (Wallpaper is).

## Notifications

`services/Notifs.qml` hosts the NotificationServer — quickshell IS the
notification daemon. `NotificationPopups.qml` renders toasts (top-center,
mako-parity urgency colors/timeouts: low green 4s, normal blue 8s, critical
red sticky). `NotifyPanel.qml` is the bell history panel. DND survives config
reloads via PersistentProperties; history via `keepOnReload`.

## IPC surface (hyprland.conf binds)

```
qs ipc call launcher toggle          SUPER+SPACE / SUPER+D
qs ipc call panels toggle session    SUPER+X
qs ipc call panels toggle <name>     any anchored panel
qs ipc call notifs dismissAll        SUPER+PERIOD
qs ipc call notifs toggleDnd
qs ipc call clipboard toggle         SUPER+SHIFT+V (SUPER+V is togglefloating)
```

## Decisions

- **stew scripts stay intact.** They're a standalone CLI layer and a fallback
  if the shell changes. Quickshell either writes its own alternative (session,
  notifications, wallpaper grid) or thinly wraps stew (profiles, capture,
  win). Never slim a stew script when porting a feature here. `stew mux` and
  `stew run` are CLI/keybind-only — not launcher entries.
- Launcher entries: quickshell alternative → `run:` callback (tagged `qs`);
  otherwise `cmd:` shell string wrapping stew (tagged `stew`). See
  `services/Commands.qml` and `Launcher.activate()`.
- Battery uses UPower with an explicit device filter
  (`ready && isPresent && isLaptopBattery`) — **not** `UPower.displayDevice`,
  which can resolve to peripheral batteries (Logitech hidpp mouse). The widget
  hides itself on machines with no laptop battery (the desktop).
- Retired configs (waybar, mako) moved to `archive/`, packages kept in
  packages.txt until the replacement is proven — never delete.

## Gotchas

- **Deployment**: this repo dir is rsynced to `~/.config/quickshell` by
  `dot restore`; edits here do nothing until synced. rsync has no `--delete`,
  so after moving/renaming files, manually remove stale ones from the deployed
  dir (stale root-level .qml files shadow the subdirs).
- The DBus name `org.freedesktop.Notifications` is exclusive. Another daemon
  (mako, or a stray second `qs -p` test instance) silently steals it;
  quickshell retries when the name frees. Symptom: toasts stop appearing.
- Unit mismatches in UPower: `percentage` is 0–1, `healthPercentage` is 0–100.
- `Notification` objects are destroyed after close — popup/history delegates
  must drop refs on `onClosed` (see NotificationPopups).
- Layer-shell keyboard focus must be OnDemand, never Exclusive — Exclusive
  pins focus and HyprlandFocusGrab never clears on outside clicks.
- Panel's default property alias routes instance children into the content
  Column; a Column positions all visible Items, so panel-wide overlays need
  input handlers (see CalendarPanel's WheelHandler), not filling MouseAreas.
- Widgets that shell out follow the pattern: `Process` + `StdioCollector` +
  poll `Timer`, plus a short one-shot Timer after writes for optimistic
  refresh (Backlight, Capture).

## TODO ideas

- Window switcher panel (replace fuzzel `stew win` flow): Hyprland toplevels
  are already reactive via Quickshell.Hyprland; reuse Fuzzy + Launcher UI.
- Launcher run-mode (type a command, run it) — keyboard-cheap since the input
  UI exists; `stew run` stays regardless.
- Theme consolidation: Theme.qml as the single Catppuccin source generating
  hypr/colors.conf + fuzzel colors (currently duplicated).
- NotifyPanel: timestamps, app grouping, inline-reply support
  (`inlineReplySupported` exists in the server API).
- Clipboard picker: image thumbnails (decode to tmpfile), per-item delete
  (`cliphist delete`).
- Battery: low-battery notification via Notifs when crossing 15%.
- Desktop machine cutover still unverified: stale-file cleanup, battery widget
  hidden, cliphist + power-profiles-daemon install.
