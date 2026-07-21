# Features

Notable behaviors wired up in this dotfiles setup.

## Click-and-hold to copy text inside tmux

Clicking and dragging (click-and-hold) the mouse over text inside a tmux pane selects it and
copies it to the system clipboard. **This is a tmux feature.** It is enabled by two pieces of
[`tmux/.config/tmux/tmux.conf`](../tmux/.config/tmux/tmux.conf):

1. Mouse support is turned on globally:

    ```tmux
    set -g mouse on
    ```

    With `mouse on`, a click-drag inside a pane enters `copy-mode-vi` and starts a visual
    selection.

2. On mouse release (`MouseDragEnd1Pane`) the selection is piped to the system clipboard via
   `xclip`:

    ```tmux
    bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
    ```

The same `copy-pipe-and-cancel` binding is also bound to `y` so you can copy from the keyboard
while in copy mode:

```tmux
bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
```

While a selection is active, tmux signals it visually: the active pane border switches to the
`@COPY_COLOR` color (see `pane-active-border-style` in `tmux.conf`), and the status bar pill
recolors via `pane_in_mode`.

For Ghostty's own (terminal-level) clipboard bindings, see
[`ghostty/.config/ghostty/config`](../ghostty/.config/ghostty/config): `control+insert` copies the
terminal selection to the clipboard and `shift+insert` pastes.

### Requiring `xclip`

The binding shells out to `xclip`, so `xclip` must be installed (`pacman -S xclip`). Without it the
drag-to-copy will select text but won't populate the system clipboard.

## Per-pane AI agent status in the tmux status bar

The tmux status bar shows live state for AI agents running in each pane (opencode / copilot).
State is pushed into tmux options `@ai_agent_state`, `@copilot_state`, and `@ai_agent_bell` by
external scripts and surfaced in `window-status-format` / `window-status-current-format`. The
bell segment is cleared automatically a few seconds after it's set. See `tmux/.config/tmux/tmux.conf`
for the exact option wiring.

## Scrollback capture to Neovim

You can capture the full scrollback history of the current tmux pane (with ANSI colors preserved)
and open it directly in Neovim for searching, copying, or inspection.

### Keybinding (`Prefix + C-e`)

In [`tmux/.config/tmux/tmux.conf`](../tmux/.config/tmux/tmux.conf), pressing `Prefix` (`Ctrl+Space`) then `Ctrl+e` (`C-e`) captures the active pane's scrollback buffer:

```tmux
bind-key C-e run-shell "tmux capture-pane -epS - | grep -vE '|||' | sed '/^$/d' > /tmp/tmux_scrollback.ansi && tmux new-window 'nvim -c \"BaleiaColorize\" -c \"setlocal nomodified nomodifiable\" -c \"normal G\" /tmp/tmux_scrollback.ansi'"
```

How it works:
1. `tmux capture-pane -epS -` exports the full pane scrollback history, retaining ANSI color escape codes.
2. Filters out prompt icons (`grep -vE ...`) and empty lines (`sed '/^$/d'`), saving to `/tmp/tmux_scrollback.ansi`.
3. Spawns a new tmux window running Neovim, colorizing ANSI escape sequences with [`baleia.nvim`](../nvim/.config/nvim/lua/plugins/baleia.lua) via `:BaleiaColorize`, setting the buffer as read-only (`nomodified nomodifiable`), and jumping to the bottom (`G`).

### Shell alias (`scrollback`)

A zsh alias is provided in [`zsh/.zsh/utils/aliases.zsh`](../zsh/.zsh/utils/aliases.zsh):

```zsh
alias scrollback='tmux capture-pane -epS - > /tmp/tmux_scrollback.ansi && nvim -c "BaleiaColorize" -c "normal G" /tmp/tmux_scrollback.ansi'
```

Executing `scrollback` inside any terminal session dumps the pane history and opens it in Neovim with full ANSI color formatting.

### History limit & Vi mode

Tmux scrollback buffer behavior is configured in [`tmux/.config/tmux/tmux.conf`](../tmux/.config/tmux/tmux.conf):
- `set-option -g history-limit 10000`: Expands scrollback buffer to 10,000 lines per pane.
- `setw -g mode-keys vi`: Enables Vi navigation keybindings in copy mode.

## Theme-aware styling everywhere

Every visible component (Hyprland, waybar, fuzzel, walker, mako, ghostty, kitty, nvim, btop,
hyprlock, swayosd, chromium, obsidian, keyboard RGB) restyles when the Omarchy theme changes,
because their configs are rendered from `colors.toml` templates. See
[SYSTEM_THEME.md](SYSTEM_THEME.md) for the render pipeline.