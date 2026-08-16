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
bind-key C-e run-shell "tmux capture-pane -epS - | grep -vE '|||' | sed '/^$/d' > /tmp/tmux_scrollback.ansi && tmux new-window 'nvim -c \"BaleiaColorize\" -c \"setlocal nomodified nomodifiable\" -c \"normal G\" /tmp/tmux_scrollback.ansi'"
```

**How it works:**
1. `tmux capture-pane -epS -` exports the full pane scrollback history, retaining ANSI color escape codes.
2. Filters out prompt icons (`grep -vE ...`) and empty lines (`sed '/^$/d'`), saving to `/tmp/tmux_scrollback.ansi`.
3. Spawns a new tmux window running Neovim, colorizing ANSI escape sequences with [`baleia.nvim`](../../nvim/.config/nvim/lua/plugins/baleia.lua) via `:BaleiaColorize`, setting the buffer as read-only (`nomodified nomodifiable`), and jumping to the bottom (`G`).

### Shell alias (`scrollback`)

A zsh alias is provided in [`zsh/.zsh/utils/aliases.zsh`](../../zsh/.zsh/utils/aliases.zsh):

```zsh
alias scrollback='tmux capture-pane -epS - > /tmp/tmux_scrollback.ansi && nvim -c "BaleiaColorize" -c "normal G" /tmp/tmux_scrollback.ansi'
```

### History Limit & Vi Mode

- `set-option -g history-limit 10000`: Expands scrollback buffer to 10,000 lines per pane.
- `setw -g mode-keys vi`: Enables Vi navigation keybindings in copy mode.
