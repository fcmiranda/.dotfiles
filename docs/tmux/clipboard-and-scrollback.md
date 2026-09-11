# Tmux Clipboard & Scrollback Capture

Notable clipboard, selection, and history buffer inspection behaviors wired into tmux.

---

## 1. Click-and-Hold to Copy Text Inside Tmux

Clicking and dragging (click-and-hold) the mouse over text inside a tmux pane selects it and copies it to the system clipboard.

Enabled in [`tmux/.config/tmux/tmux.conf`](../../tmux/.config/tmux/tmux.conf):

1. **Global Mouse Support**:
   ```tmux
   set -g mouse on
   ```
   With `mouse on`, a click-drag inside a pane enters `copy-mode-vi` and starts a visual selection.

2. **System Clipboard Pipe on Release (`MouseDragEnd1Pane`)**:
   ```tmux
   bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
   ```

3. **Keyboard Copy (`y`)**:
   ```tmux
   bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
   ```

While a selection is active, tmux signals it visually: the active pane border switches to the `@COPY_COLOR` color (see `pane-active-border-style` in `tmux.conf`), and the status bar pill recolors via `pane_in_mode`.

> **Note:** Requires `xclip` (`pacman -S xclip`).

---

## 2. Scrollback Capture to Neovim (`Prefix + C-e`)

You can capture the full scrollback history of the current tmux pane (with ANSI colors preserved) and open it directly in Neovim for searching, copying, or inspection.

### Keybinding (`Prefix + C-e`)

In [`tmux/.config/tmux/tmux.conf`](../../tmux/.config/tmux/tmux.conf), pressing `Prefix` (`Ctrl+Space`) then `Ctrl+e` (`C-e`) captures the active pane's scrollback buffer:

```tmux
bind-key C-e run-shell "~/.config/tmux/scrollback-view.sh"
```

**How it works:**
1. `tmux capture-pane -epJS -` exports (`-J` rejoins wrapped lines) the full pane scrollback history, retaining ANSI color escape codes.
2. Drops empty lines (`sed '/^$/d'`), saving to `/tmp/tmux_scrollback.ansi`. (The old prompt-glyph `grep -vE` stage was removed: its non-zero exit status aborted the `&&` chain and silently killed the binding.)
3. Spawns a new tmux window running Neovim, colorizing ANSI escape sequences with [`baleia.nvim`](../../nvim/.config/nvim/lua/plugins/baleia.lua) via `:BaleiaColorize` (guarded by `silent!`, so a missing/slow plugin can never break the binding), setting the buffer as read-only (`nomodified nomodifiable`), and jumping to the bottom (`G`). Failures are visible by design: a failed capture shows a `display-message` and logs to `/tmp/scrollback-view.err` (the old inline version died silently).

### Shell alias (`scrollback`)

A zsh alias is provided in [`zsh/.zsh/utils/aliases.zsh`](../../zsh/.zsh/utils/aliases.zsh):

```zsh
alias scrollback='tmux capture-pane -epS - > /tmp/tmux_scrollback.ansi && nvim -c "BaleiaColorize" -c "normal G" /tmp/tmux_scrollback.ansi'
```

### History Limit & Vi Mode

- `set-option -g history-limit 10000`: Expands scrollback buffer to 10,000 lines per pane.
- `setw -g mode-keys vi`: Enables Vi navigation keybindings in copy mode.


---

## 3. Token Extract to Clipboard (`Prefix + e` / `Prefix + y`)

Fuzzy copy/insert of structured tokens (URLs, paths, git hashes, IPs) from the full scrollback via `mm`, extrakto-style — no editor round-trip.

Bind ([`tmux.conf`](../../tmux/.config/tmux/tmux.conf)): `Prefix` then `e` (extract) or `y` (yank) runs [`scrollback-extract.sh`](../../tmux/.config/tmux/scrollback-extract.sh) with the origin pane id. The script opens a themed popup itself (rounded border in theme green, pure icon badge ` 󰅍 `, golden `75% x 60%`). When an agent is streaming (`@ai_agent_state_raw` = busy/working), it opens over a frozen snapshot backdrop instead, per Issue B in `popup-isolation-and-debounce.md`:

1. `tmux capture-pane -pJS - -t <origin>` exports the origin pane explicitly (never the popup), joining wrapped lines (`-J`) so split URLs survive; full text kept in `/tmp/scrollback-extract-src.txt`.
2. One token file per filter precomputed (`-all/-url/-path/-sha.txt`), deduped and recent-first.
3. `mm -o scrollback` ([preset](../../matchmaker/.config/matchmaker/presets/scrollback.toml): nav mode starting in filter, jump-style keymap) with items from `[start] command`. Keys: `Enter` copies, `Ctrl+V` inserts the current token directly into the origin pane (`MM_ORIGIN_PANE`), `Ctrl+E` (filter) / `e` (nav) opens a `path[:line[:col]]` token in `$EDITOR` via [`scrollback-open.sh`](../../tmux/.config/tmux/scrollback-open.sh), `Tab`/`Shift-Tab` cycle explicit filter modes (all→url→path→sha→all), `Space` multi-selects, `Esc` cascades filter→nav→quit, `Ctrl+P` / `P` cycles between 60% and 95% full-modal preview.
4. Copy tail runs detached (`trap '' HUP`, `&`) to `wl-copy` (fallback `xclip`, then tmux buffer) with a `tmux display-message` confirm, so the popup closes the instant `Enter` is pressed; stages are timestamped in `/tmp/scrollback-mm.log`. Covered by `tests/scrollback_extract.test.sh`.

Rule of thumb: `Prefix + E` / `Prefix + C-e` = **read** (long-form inspection in Neovim), `Prefix + e` = **extract** (one token to clipboard in ~3 keystrokes).

---

## 4. Workspace Files Peek (`Prefix + v` / `Prefix + V`)

Browse workspace files and AI-generated code in a popup via `mm -o files` — inspect files with syntax-highlighted previews, tree, and media without leaving the AI chat window.

Bind ([`tmux.conf`](../../tmux/.config/tmux/tmux.conf)):
- `Prefix + v`: Opens Golden Ratio popup (`75% × 60%`).
- `Prefix + V`: Opens expanded fullscreen modal (`95% × 90%`).

Architecture ([`dir-peek.sh`](../../tmux/.config/tmux/dir-peek.sh) and preset [`files.toml`](../../matchmaker/.config/matchmaker/presets/files.toml)):
1. **Themed Popup & Pure Icon Badge**: Uses theme blue/cyan border with pure icon badge ` 󰈞 `, with frozen backdrop protection when an agent streams.
2. **Dual-Layout Full-Modal Preview (`Ctrl+P` / `P`)**:
   - Layout 0: Standard Golden Ratio split (**40% list / 60% preview**).
   - Layout 1: Maximize preview (**95% width**) for deep code/markdown inspection without closing the modal.
3. **Origin Pane & AI Prompt Insertion (`Ctrl+V`)**:
   - `Enter`: Copies path(s) to system clipboard and closes modal.
   - `Ctrl+V`: Injects the path directly into the origin pane (`MM_ORIGIN_PANE`) — instant referencing into the active AI prompt.
   - `Ctrl+E` / `e`: Opens the selected file in `$EDITOR` (Neovim).
   - `l` / `h`: Drills down or navigates up directory levels seamlessly.
