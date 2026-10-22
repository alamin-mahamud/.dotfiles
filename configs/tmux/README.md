# tmux

Built for one workload: SSH into a jump host and drive many concurrent Claude
Code / agent sessions. `~/.tmux.conf` is a symlink to `tmux.conf` here, created
by `scripts/components/shell-env.sh:configure_tmux()`.

Prefix is **`C-Space`** — Ctrl under the pinky/palm edge, Space under the thumb,
so no single finger plays both halves of the chord the way it does for `C-a`.
`C-a` stays live as `prefix2`, so old muscle memory keeps working and a terminal
that refuses to transmit NUL (`0x00`) cannot lock you out. Verified free of
conflicts on this box: nothing in nvim, zsh, tmux or Claude Code binds it.

Double-tapping it — `C-Space C-Space` — opens the fuzzy jump, because nothing in
this stack consumes a literal `C-Space`, so the second tap is better spent than
on `send-prefix`. `prefix C-a` still passes one through if you ever need it.

The deeper fix for pinky strain is not in tmux at all: remap **Caps Lock to
Ctrl** on the machine you SSH *from*, so the pinky barely travels.

## The three things that matter

**Window labels are the agent's topic.** Claude Code writes its conversation
topic into the terminal title, so tmux sees it as `#{pane_title}`. The status
bar shows that instead of eleven windows all called `claude`. The topic
outranks a manual window name on purpose: a name set when the window was
opened goes stale the moment the conversation moves on. A window with no agent
in it keeps its name, or shows its directory.

**A glyph says whether the agent needs you.** Claude Code hooks stamp
`@agent_state` on their own pane through `scripts/tmux-agent-state`, so the bar
distinguishes the three states that matter with a dozen agents open:

| glyph | colour | state | what to do |
| ----- | ------ | ----- | ---------- |
| `●` | amber | blocked | it wants a permission, a plan approval or an answer — go now |
| `·` | dim | busy | working — leave it alone |
| `✓` | teal | done | finished its turn — your move |
| — | — | idle | nothing running, or not an agent pane |

Amber is the only colour in the window list that means *you*. That is why `*`
(unseen output) is dim: it fires on any output at all, so it cannot carry
attention.

**`prefix + Space`** opens a fuzzy picker over every window of every session,
**blocked agents first**, then most-recently-active, with a live preview of the
pane and the same state glyphs. That is the navigation tool once the window
count is high enough that the bar collapses idle windows to bare indices.

## Keys

| Key | Action |
| --- | --- |
| `C-Space C-Space` | fuzzy jump (double-tap the prefix) |
| `prefix Space` | fuzzy jump: all windows, all sessions, live preview (`ctrl-x` kills, `ctrl-r` refreshes) |
| `prefix g` | session picker |
| `prefix o` | throwaway shell popup in the current directory |
| `prefix T` | tools menu: lazygit · k9s · btop · shell, each in a popup |
| `prefix \|` / `prefix -` | split vertical / horizontal, inheriting cwd |
| `prefix c` | new window, inheriting cwd |
| `prefix h j k l` | select pane · `M-arrows` does it without the prefix |
| `prefix H J K L` | resize pane, repeatable |
| `prefix C-h` / `C-l` | previous / next window, repeatable |
| `prefix Enter` | zoom pane |
| `prefix Tab` | last window |
| `prefix b` | break pane into its own window |
| `prefix M` | join another pane into this window (`m` stays mark-pane) |
| `prefix /` | incremental search up the scrollback |
| `prefix x` / `X` / `Q` | kill pane / window / session, each with a confirm |
| `prefix C-s` / `C-r` | resurrect: save now / restore |
| `prefix r` | reload this file |
| `F12` | mute this tmux so keys reach the tmux you SSHed in from (nested) |

Copy mode is vi: `v` select, `V` line, `y` copy, `Y` to end of line.
Copies travel by OSC 52, so they land in the clipboard of the machine you SSHed
from — no X server involved.

## Status bar

Hairline mono on the terminal background, one teal accent.

```
 kahf  1 Failed openipmi and nvmf-aut…  2  3  4  5*  6  7  8  9      05:54  9w
```

- session chip turns **amber** while the prefix is live
- `*` after a window = unseen output from that window's agent (dim, not amber)
- current window is bright + underlined
- **label widths are computed, not fixed.** `#{=/N/…:}` takes a nested format
  as `N`, so the clip width is arithmetic over `#{window_width}`: the bar's
  chrome is subtracted, the rest is split between the idle windows, capped at
  28 and floored at 6. Below the floor the idle windows collapse to bare
  indices and `prefix + Space` is how you read the rest.
- `#{window_width}`, not `#{client_width}`: the latter is **empty** for a
  session with no attached client, and a negative clip width silently
  right-aligns the label instead of erroring.
- measured at 178 columns: 26 glyphs per idle label at 4 windows, 6 at 8
  windows, collapsed from 9 — and the whole bar fits at every count from 1 to
  14, with `PREFIX`, `ZOOM` and every activity flag shown.

## What this replaced

The previous config (commit `625bac9`, "tmux theme") was a Catppuccin Frappe
setup aimed at Warp, generated into `~/.tmux.conf` by a heredoc. Carried over
from it: the Warp `TERM`/clipboard branch, and the popup tooling, which bound
`f`/`g`/`p`/`k` to spf/lazygit/htop/k9s — `g` is the session picker here and
`spf` is not installed, so those sit behind `prefix + T` instead. Catppuccin,
the powerline separators and `tmux-prefix-highlight` are gone: the prefix
indicator is a colour change on the session chip, which needs no plugin.

## Plugins

Only three: `tpm`, `tmux-resurrect`, `tmux-continuum`. Sessions auto-save every
15 minutes **into `~/.local/share/tmux/resurrect`** (the XDG path resurrect
picks when `~/.tmux/resurrect` does not exist) and restore on server start.

Dropped on purpose:

- `tmux-sensible` — everything it sets is set explicitly in `tmux.conf`
- `tmux-copycat` — tmux has had incremental search built in since 2.4
- `tokyonight.nvim` — a Neovim plugin; tmux never read it
- `tmux-yank` — on a box with `DISPLAY=:99` (Xvfb) it prefers the X clipboard,
  so copies land in a headless X nobody can paste from. Native `set-clipboard`
  + OSC 52 reaches the real client instead.

- `tmux-fzf`, `tmux-thumbs`, `tmux-better-mouse-mode`, `catppuccin/tmux`,
  `tmux-prefix-highlight` — declared by the config this replaces. `tmux-thumbs`
  in particular never had its Rust binary built, so it was inert.

Orphan plugin directories from those configs are still on disk; `prefix + M-u`
(tpm clean) removes them.

## Gotchas discovered while building this

- The `terminal-features` flag for CSI u keys is **`extkeys`**. Writing
  `extended-keys` there is the *option* name; tmux accepts it silently and
  ignores it.
- `set -as terminal-features` genuinely appends, so an unguarded line grows the
  list by a copy on every reload. Hence the `%if` sentinel. Changing that list
  needs `tmux kill-server`, not a reload.
- `#{<=:13,5}` is **true** — tmux's comparison operators compare strings. Numeric
  tests need `#{e|-|:...}` plus a sign check.
- `tmux-continuum` prepends its save hook to `status-right` when it loads, so
  nothing after `run .../tpm` may set `status-right` or auto-save stops. It also
  skips installing the hook entirely if another tmux server is running.

## Agent state hooks

`scripts/tmux-agent-state <busy|blocked|done|unblock|clear>` stamps the calling
pane. It is wired from `~/.claude/settings.json` (that file is **not** tracked
here; a `.bak-<timestamp>` copy next to it is the rollback):

| event | matcher | action |
| ----- | ------- | ------ |
| `UserPromptSubmit` | — | `busy` |
| `Stop` | — | `done` |
| `PermissionRequest` | — | `blocked` |
| `Notification` | `permission_prompt\|elicitation_dialog` | `blocked` |
| `PreToolUse` | `AskUserQuestion\|ExitPlanMode` | `blocked` |
| `PostToolUse` | — | `unblock` |
| `SessionStart` / `SessionEnd` | — | `done` / `clear` |

Every hook is `async` with a 5 s timeout, so none of them can delay a turn.
Measured cost: **12 ms** per call, and `unblock` writes only on the one
transition that matters (a permission was just answered), not on every tool
call.

Three traps worth keeping written down:

- **A nested `claude -p` inherits `TMUX_PANE`** and fires its own
  `SessionStart`/`Stop`/`SessionEnd`, so a harness role or subagent CLI call
  would stamp `done` on a pane that is still working. Measured difference: a
  nested run has `CLAUDE_CODE_SESSION_ATTENDED=0` and
  `CLAUDE_CODE_ENTRYPOINT=sdk-cli`, the interactive session has `1` and `cli`.
  The script exits early unless `ATTENDED=1`.
- **`Notification`'s `idle_prompt` must not mean `blocked`** — it fires when a
  finished session sits waiting, i.e. after `Stop`, so every done pane would go
  amber on its own and the signal would be worthless.
- **A `#[fg=…]` produced inside a `#{E:@option}` expansion comes back as
  literal text.** All styling lives in the outer `window-status-*` format.
- A `UserPromptSubmit` hook's stdout is injected into the model's context, so
  the script is silent on every path and always exits 0.

Kill switch: delete the eight entries from `~/.claude/settings.json` (or restore
the `.bak`). The labels fall back to topic-only with no change to `tmux.conf`.
