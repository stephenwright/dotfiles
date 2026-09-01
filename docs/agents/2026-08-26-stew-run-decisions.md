# stew-run modes — decisions

Grilling log for making `bin/stew-run` more useful. One line per settled decision.

## Round 1

- ~~**Mode syntax: words *and* sigils.** Both accepted for every mode.~~
  Superseded in Round 3 — sigils only, no word aliases.
- **Errors always notify, `-u critical`.** Today `set -euo pipefail` plus
  `output=$(...)` aborts the script on a nonzero exit, so failures notify
  nothing at all. Fix that and include the exit code.
- **Long output → held terminal with a pager, not a notification.** QS
  `NotificationPopups` caps the body at 4 lines and elides. Clipboard spill was
  explicitly rejected.
- **`stew-run` accepts the command as argv**; it prompts via fuzzel only when
  argv is empty. Lets hyprland binds and a future QS launcher run-mode reuse the
  modes instead of reimplementing terminal/notify handling. (`bin/stew:28`
  already forwards args that `stew-run` currently ignores.)
- **One window class, one rule.** `float-center` at 60%×60% is shared by every
  terminal mode; no per-mode class or geometry.

## Round 2

- **Sigils are `;` and `:` only.** `;` = terminal that stays open, `:` = terminal
  that closes on exit, bare = run and notify. No `$`, no `>`.
- **No progress ping while running** — notifying on completion (success or
  error) is enough.
- **Pager promotion pipes captured output**, never re-runs the command (side
  effects would fire twice). Threshold: >6 lines or >500 chars (chars revised to 350 in
  Round 4). Pager is
  `less -R`. Long errors get both the critical notification and the pager.
- **No command history.** ~~Round 1/2 explored an MRU history file fed to
  fuzzel as dmenu candidates~~ — dropped; a real terminal is the answer when
  more than a one-shot prompt is needed. fuzzel keeps `--prompt-only`.

## Round 3

- **Three behaviours, no more.** bare / `;` / `:`. No `&` background mode, no
  `term:`/`tui:` word aliases (supersedes Round 1).
- **Bare mode always notifies on completion**, even when output is empty, so
  silence is never ambiguous.
- **"Still running (10s)" notification** for bare mode, as a hint that
  something may be amiss (a command that never exits would otherwise leave no
  trace). Terminal modes are already visible, so they don't need it.
- **`:` holds on nonzero exit** with the same `[any key]` prompt `;` uses, and
  closes on success — a typo must not flash and vanish.
- **argv form: prefix inside the string.** `stew run ';pacman -Q'`; empty argv
  falls back to the fuzzel prompt. No separate mode argument.

## Round 4 (found during implementation)

- **A long *success* still gets a one-line notification** (`exit 0 · 12s — output in
  pager`), refining Round 2's "pager, not a notification". Without it, a fired 10s hint
  would have nothing to replace it and would sit on screen after the job finished.
- **fzf sourcing in `base/.zshrc` is guarded by `[[ -t 0 ]]`.** fzf's
  `completion.zsh`/`key-bindings.zsh` restore shell options through `eval`, which errors
  with `can't change option: zle` when there is no terminal — two lines of noise in
  front of every captured output. Fixed at the source instead of filtered in `stew-run`.

- **Promotion threshold and toast cap are aligned at 6 lines.**
  `NotificationPopups.qml` was capping the body at 4 wrapped lines while `stew-run`
  promoted at 6, so 5–6 line output showed elided; and 500 chars wraps to ~8 lines at
  the popup's 480px width. Raised the cap to 6 and lowered the char threshold to 350
  (~6 wrapped lines). Notification history stays the fallback for anything elided —
  `NotifyPanel` expands to 20 lines.

## Assumptions (unchallenged, cheap to reverse)

- The promoted pager window closes when `less` quits.
- The "still running" and completion notifications share a notification id, so
  the completion replaces the hint in place.
- Terminal stays hardcoded `alacritty --class float-center`; no `$TERMINAL`
  indirection.
