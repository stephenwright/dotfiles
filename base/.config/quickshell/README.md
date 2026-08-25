# quickshell config

Bar, notification daemon, and panel/picker UI for Hyprland. Replaced waybar +
mako + most fuzzel dialogs (Aug 2026). Catppuccin Macchiato throughout.

## Layout

```
shell.qml     entry: one Bar per screen + global windows (Launcher,
              ClipboardPanel, WallpaperPanel, NotificationPopups)
services/     singletons only — the one dir with a hand-written qmldir.
              Theme, Commands (launcher tree), PanelManager, Notifs
              (notification daemon), Session (actions), Fuzzy (matcher),
              Caffeine (stay-awake state; toggle lives in DisplayPanel,
              Display glyph tints green while active)
lib/          shared components: Panel (base for anchored panels), keyboard-aware
              PanelButton/PanelToggle/PanelSlider, BarWidget, BarText, MeterRow,
              NetRow
bar/          Bar.qml + one file per widget
panels/       anchored panels (derive from lib/Panel) + managed centered panels
              (Launcher, Clipboard, Wallpaper) + passive NotificationPopups
```

Rules of thumb:

- Singletons live in `services/` and must be listed in `services/qmldir`
  (`singleton Name File.qml`). Other dirs need no qmldir; files import
  siblings' dirs relatively (`import "../lib"`).
- State + actions shared by ≥2 consumers go in a service singleton; bar
  widgets, panels, the launcher, and IPC keybinds all call the same function.
  One-off exec calls stay inline.

## How panels work

`Panel` means a managed interactive surface with keyboard focus. `lib/Panel.qml`
owns chrome and positioning for bar-anchored panels; Launcher, Clipboard, and
Wallpaper implement the same lifecycle directly. `services/PanelManager.qml`
is the sole lifecycle authority and keeps one managed panel open globally.

- Every panel registers by `panelName`; keybinds/scripts open them with
  `qs ipc call panels toggle <name>` (session, notifications, battery, …).
  PanelManager picks the instance on the focused monitor (panels are
  per-screen — each Bar instantiates its own).
- Managed surfaces expose `managedOpen()`/`managedClose()` for the manager and
  public `toggle()`/`close()` methods that delegate back to it. Visibility is
  changed only in the managed methods. Registration and bar-window
  registration must be paired with destruction-time unregister calls.
- Every managed surface uses OnDemand keyboard focus, focuses its initial
  control through `initialFocusItem` when opened, and has a window-level Escape
  shortcut. Tab and Shift+Tab use Qt's native focus chain.
- Each focus grab includes the open surface and every registered bar window.
  An application click outside that set closes the surface; bar widgets remain
  reachable in one click across monitors. Focus loss, pointer movement, and
  `focusedmon` events do not dismiss panels.
- Empty bar space and non-panel bar actions close the current surface. A
  primary panel-widget click toggles it, so the current widget closes and a
  different widget switches surfaces in one click.
- Normal and special workspace events (`workspace`, `workspacev2`,
  `activespecial`, `activespecialv2`) close the current surface.
- Per-open refresh goes in the `opening()` signal handler, not
  `onVisibleChanged`.
- Passive `PanelWindow` surfaces such as notification toasts, tooltips, and
  indicators stay outside PanelManager and do not take keyboard focus.

Interactive panel controls use `PanelButton`, `PanelToggle`, and `PanelSlider`.
Focus styling appears only after keyboard input and clears on pointer use.
Down follows Tab and Up follows Shift+Tab. Each option is a focus stop; grid
options also use Left/Right. Enter or Space activates the focused item.
Buttons and toggles activate with Enter or Space. Sliders use Left/Right,
Page Up and Page Down, Home, and End. Keep focus behavior local to controls—do
not add a keyboard-only panel subtype or panel-wide index management.
Wallpaper uses GridView's native arrow navigation and Enter/Space activation;
Launcher and Clipboard keep text-input-driven result navigation.

## Notifications

`services/Notifs.qml` hosts the NotificationServer — quickshell IS the
notification daemon. `NotificationPopups.qml` renders toasts (top-right,
mako-parity urgency colors/timeouts: low green 4s, normal blue 8s, critical
red sticky). `NotifyPanel.qml` is the bell panel: live notifications on top,
plus a collapsed history section of dismissed ones. Closed Notification
objects are destroyed, so history stores plain-data snapshots (no actions) —
capped at 100, per-item delete. Arrival times are tracked by notification id
(shown on live + history rows). The bell shows a red dot for notifications
arriving during DND (cleared on panel open or DND toggle). DND, history, and
arrival times survive config reloads via PersistentProperties (as JSON
strings — see gotchas); live notifications via `keepOnReload`.

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
- Capture UI lives in the Display panel (screenshots via hyprshot, recording
  via `stew capture`); the bar ⏺ appears only while recording, as a stop
  button. Audio/battery widgets are icon-only — exact numbers in their panels.
- Bluetooth uses the native Quickshell.Bluetooth module (connect/disconnect
  paired devices, adapter power). Pairing stays in bluetoothctl. Widget hides
  when no adapter (bluetooth.service must be running to see one).
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
- PersistentProperties: a `var` holding a JS object/array warns "JSValue
  can't be reassigned to another engine" on reload and can restore as
  undefined — persist JSON strings instead (Notifs historyJson/arrivalsJson).
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
  refresh (Display, Capture).

## TODO ideas

- Window switcher panel (replace fuzzel `stew win` flow): Hyprland toplevels
  are already reactive via Quickshell.Hyprland; reuse Fuzzy + Launcher UI.
- Launcher run-mode (type a command, run it) — keyboard-cheap since the input
  UI exists; `stew run` stays regardless.
- Theme consolidation: Theme.qml as the single Catppuccin source generating
  hypr/colors.conf + fuzzel colors (currently duplicated).
- NotifyPanel: app grouping.
- Clipboard picker: image thumbnails (decode to tmpfile), per-item delete
  (`cliphist delete`).
- Battery: low-battery notification via Notifs when crossing 15%.
- Desktop machine cutover still unverified: stale-file cleanup, battery widget
  hidden, cliphist + power-profiles-daemon install.
