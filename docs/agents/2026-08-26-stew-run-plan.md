# stew-run: prefix modes, reliable notifications, argv input

**Status:** done
**Context:** [decisions doc](2026-08-26-stew-run-decisions.md) — every choice below
was settled there. Files: `bin/stew-run`, `bin/stew`, `README.md`.

## Problem

`bin/stew-run` has two behaviours: a leading `;` opens a terminal that stays open,
anything else runs and notifies its output. Three gaps: a command that fails notifies
nothing at all (`set -euo pipefail` aborts the script before `notify-send` is reached),
a command with no output notifies nothing either — so "did anything happen?" is
unanswerable — and long output is unreadable because QS `NotificationPopups` caps the
body at `maximumLineCount: 4` with elide. There is also no way to run a TUI in a
throwaway floating terminal, which is the most common thing wanted from a launcher.

## Decisions

- Three behaviours keyed by leading sigil: bare = run + notify, `;` = terminal that
  stays open, `:` = terminal that closes on success. No other sigils, no word aliases.
- `:` holds on nonzero exit with the same `[any key]` prompt `;` uses — a typo must not
  flash and vanish.
- Bare mode always notifies on completion, including empty output. Failures use
  `-u critical` and include the exit code.
- Output longer than 6 lines or 500 chars is promoted into a `less -R` terminal fed the
  **captured** output — never re-run the command. A long failure gets both the critical
  notification and the pager.
- A "still running (10s)" notification fires if a bare command hasn't finished by then;
  the completion notification replaces it in place (`notify-send -p` / `-r`).
- Command comes from `$1` with the prefix inside the string (`stew run ';pacman -Q'`);
  fuzzel prompts only when argv is empty.
- One window class and rule: `alacritty --class float-center`, hardcoded as today.
- No background/tracked-job mode, no history, no clipboard spill.

## Steps

- [x] In `bin/stew-run`, take the command from `${1:-}` and fall back to the existing
      `fuzzel --dmenu --prompt-only="$ "` call only when it is empty. Keep `zsh -ic` for
      every mode (aliases must resolve before the command is parsed).
- [x] Add the `:` branch to the `case` beside the existing `\;*` one: run
      `${cmd#:}` in the float terminal, and on nonzero exit hold with the same
      `echo; read -k1 '?[any key] '` tail the `;` branch uses. Success closes the window.
      *Deviation: the terminal command is now an array (`term=(alacritty --class
      float-center -e)`) instead of an unquoted string, so the hold tail can be shared
      between both branches without word-splitting surprises.*
- [x] Rework the bare branch so a nonzero exit cannot abort the script — capture status
      explicitly (e.g. `output=$(zsh -ic "$cmd" 2>&1) || status=$?`) rather than relying
      on `set -e`. This is the silent-failure fix; verify it before layering the rest on.
- [x] Notify on every completion of the bare branch: title `$ <cmd>`; body is the output,
      or a short confirmation (`exit 0`, elapsed seconds) when the output is empty.
      Nonzero exit adds `-u critical` and the exit code.
- [x] Promote long output: when the captured output exceeds 6 lines or 500 chars, write
      it to a `mktemp` file and open `less -R` on that file in the float terminal
      (`$term zsh -ic "less -R <file>"`). Remove the tmpfile once the terminal exits —
      `$term` runs in the foreground, so a `trap`-based cleanup is enough. A failing
      command still gets its critical notification in addition to the pager.
      *Deviations: the pager runs `less` directly (`alacritty -e less -R <file>`), no
      `zsh -ic` wrapper needed. And a long **success** still sends a one-line
      notification (`exit 0 · 12s — output in pager`) rather than none — otherwise a
      fired 10s hint would stay on screen with nothing to replace it, contradicting
      "always notify on completion".*
- [x] Add the 10s hint: start a background subshell that sleeps 10 then notifies
      "still running", kill it if the command finishes first, and pass its
      `notify-send -p` id to the completion notification via `-r` so the hint is
      replaced rather than duplicated. If the QS daemon's replace handling misbehaves
      (see `services/Notifs.qml` — `onNotification` stores arrivals by `n.id`), fall
      back to two independent notifications and note it in the decisions doc.
      *The fallback was not needed: `notify-send -p` returns real ids from the QS
      daemon, and the wiring is verified (`-r <id>` on the completion call).*
- [x] Add a usage/help path to `bin/stew-run` listing the three modes, matching the
      style of `bin/stew-notify`'s trailing `Usage:` case.
- [x] Update the `stew run` line in `README.md:49` to mention the prefixes (one line —
      e.g. `stew run # Command runner (; terminal, : TUI, bare notifies)`).
- [x] **Unplanned, required:** guard the fzf sourcing in `base/.zshrc` with `[[ -t 0 ]]`.
      `/usr/share/fzf/completion.zsh` and `key-bindings.zsh` save/restore shell options
      via `eval`, which fails with `(eval):1: can't change option: zle` when there is no
      terminal — so every bare-mode notification body was prefixed with two lines of
      noise, and `exit 0` confirmations consisted of nothing but noise. Root-caused
      rather than filtered in `stew-run`. The same edit was applied to the live
      `~/.zshrc` so the fix is active without waiting for a `dot restore`; fzf widgets
      still bind in a real terminal (verified in a pty).

## Verification

`~/bin/stew` is a symlink into this repo, so edits to `bin/stew-run` are live with no
`dot restore` needed.

- [x] `shellcheck bin/stew-run` — clean
- [x] `bin/stew run 'echo hi'` → notification body `hi`
- [x] `bin/stew run 'true'` → body `exit 0 · 0s` (empty-output case is no longer silent)
- [x] `bin/stew run 'nosuchcommand'` → `-u critical`, body has zsh's message plus
      `exit 127 · 1s` (the regression that motivated the change)
- [x] `bin/stew run 'pacman -Q'` → notification `exit 0 · 0s — output in pager` and
      `less -R` in a floating terminal; closing it removed `/tmp/stew-run.*`
- [x] `bin/stew run 'sleep 12; echo done'` → `-p` hint at 10s, completion sent with
      `-r <id>` at 12s (verified with a stubbed `notify-send`, then run for real)
- [x] `bin/stew run ':echo hi'` → floating terminal, closed itself, script exited 0
- [x] `bin/stew run ':nosuchcommand'` → floating terminal held; script exited only once
      the window was closed
- [x] `bin/stew run ';echo hi'` → terminal stayed open (unchanged behaviour)
- [x] `bin/stew run` with no arguments → fuzzel prompt opens, matching what
      `base/.config/hypr/hyprland.conf:171` and `hyprland.lua:171` invoke on `SUPER+R`
      (both pass no arguments; unchanged). Dismissing the prompt exits the script.

Notification bodies were inspected with a stubbed `notify-send` on `PATH`, since the
QS daemon gives no way to read back what it rendered. The one thing left to eyeball is
that the 10s hint visibly updates in place rather than stacking.

## Open questions

None. Three assumptions from the decisions doc, each reversible in a line: the pager
window closes when `less` quits; hint and completion notifications share an id;
alacritty stays hardcoded with no `$TERMINAL` indirection.

## Out of scope

- Background/tracked job mode, `stew run status`, and any QS bar widget for running jobs.
- Command history or completion in the fuzzel prompt — a real terminal covers that.
- QS launcher run-mode (still a TODO in `base/.config/quickshell/README.md`); it should
  call `stew run '<prefixed cmd>'` when built, not reimplement these modes.
- Per-mode window classes or geometry; `float-center` rules in
  `base/.config/hypr/hyprland.conf:265-267` stay as they are.
