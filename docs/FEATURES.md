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

The tmux status bar displays real-time, dynamic state for AI agents (Antigravity / OpenCode / Copilot) running in each pane.
State is pushed into tmux options `@ai_agent_state`, `@ai_agent_state_color`, `@ai_agent_state_raw`, `@copilot_state`, and `@ai_agent_bell` by the centralized `acpd` daemon (`127.0.0.1:4040`) and client hooks (`tmux-hook.mjs` / `hooker.ts`).

### Dynamic Pill Layout & Color States (`window-status-current-format`)

The active window tab is rendered as a rounded pill (`` ... ``) whose background color changes dynamically based on the AI agent state (`@ai_agent_state_color`):

- 🟡 **Yellow (`#f9e2af` / `@COPY_COLOR`)**: Agent is actively working / executing tools (`busy` / `working`) with an animated spinner (`⠋`).
- 🟣 **Purple (`#cba6f7` / `@PREFIX_COLOR`)**: Agent has asked a question and is awaiting user input (`question` / `awaiting_input`) with the `󱜻` icon.
- 🔴 **Red (`#f38ba8`)**: Agent requires permission or encountered an execution error (`permission` / `error`) with the `󱅭` or `󰨄` icon.
- 🟢 **Cyan/Teal (`#94e2d5` / `@CURRENT_COLOR`)**: Agent is idle or normal terminal window without an active AI agent session.

Inside the active filled pill, the window title `#W` and state icon `@ai_agent_state` are forced to high-contrast dark text (`fg=#{@SESSION_ACTIVE_FG}`) for clean legibility on top of filled backgrounds.

### Background Tab Notifications (`window-status-format`)

For inactive background tabs, `@ai_agent_state` is rendered in `#[fg=#{@ai_agent_state_color}]`. Status icons light up in their respective state colors (Yellow, Purple, Red) in the background so you can monitor agent progress and input requests across windows at a glance.

### Three Orthogonal Tmux Options Pushed by `acpd`

- `@ai_agent_state`: Pure icon or animated spinner frame string without embedded ANSI color tags (e.g. `⠋`, `󱜻`, `󱅭`, `󰨄`).
- `@ai_agent_state_color`: Hex color string configured in `config.toml` (e.g. `#f9e2af`, `#cba6f7`, `#f38ba8`, `#94e2d5`).
- `@ai_agent_state_raw`: Raw state identifier string (`busy`, `working`, `question`, `awaiting_input`, `permission`, `error`, `idle`, `closed`).

See [`tmux/.config/tmux/tmux.conf`](../tmux/.config/tmux/tmux.conf) and [`acpd/.config/acpd/config.toml`](../acpd/.config/acpd/config.toml) for exact option wiring and theme definitions.

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

## Zsh Vi Mode (`vi-cmd-mode`), Custom Surrounds, and Starship Integration

Zsh is configured with `zsh-vi-mode` in [`zsh-plugins/.zsh/plugins/zsh-vi-mode.zsh`](../zsh-plugins/.zsh/plugins/zsh-vi-mode.zsh), bringing full Vi modal editing (`insert`, `vicmd`, `visual`, `replace`) to the command line along with custom surround text objects and dynamic Starship prompt synchronization.

### Starship Prompt Integration

- **Live Mode Tracking**: Exported shell variable `ZVM_MODE` tracks the active mode (`i` = insert, `n` = normal/cmd, `v`/`vl` = visual, `r` = replace).
- **Instant Prompt Refresh**: Switching modes (e.g. pressing `<Esc>` to enter `vi-cmd-mode` or `i` for insert mode) invokes `zvm_after_select_vi_mode()`, calling `zle reset-prompt` to instantly redraw the prompt indicator.
- **Starship Theme Presets**: Preset templates (see [`starship/.config/omarchy/themed-overrides/starship.toml.tpl`](../starship/.config/omarchy/themed-overrides/starship.toml.tpl)) evaluate `$ZVM_MODE` via custom module `when` rules (e.g. `case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac`) to render distinct colors and indicators per mode.

### Combined Surround Text Objects (`ib`, `ab`, `iq`, `aq`)

Custom ZLE widgets extend Vi mode with smart, unified surround text objects so you don't need to type specific bracket or quote characters:

- **Brackets (`ib` & `ab`)**:
  - `ib` (inside brackets): Automatically detects and targets the innermost enclosing brackets `(`, `[`, `{`, or `<`.
  - `ab` (around brackets): Targets the innermost enclosing brackets including the bracket characters themselves.
- **Quotes (`iq` & `aq`)**:
  - `iq` (inside quotes): Automatically detects and targets the innermost enclosing quotes `"`, `'`, or `` ` ``.
  - `aq` (around quotes): Targets the innermost enclosing quotes including the quote characters themselves.

#### Supported Operations in `vicmd` & `visual` Modes

| Keybinding | Mode | Action |
| --- | --- | --- |
| `vib` / `vab` | Visual | Visually select inside / around innermost brackets |
| `viq` / `vaq` | Visual | Visually select inside / around innermost quotes |
| `dib` / `dab` | Normal (`vicmd`) | Delete inside / around innermost brackets |
| `diq` / `daq` | Normal (`vicmd`) | Delete inside / around innermost quotes |
| `yib` / `yab` | Normal (`vicmd`) | Yank (copy) inside / around innermost brackets to clipboard |
| `yiq` / `yaq` | Normal (`vicmd`) | Yank (copy) inside / around innermost quotes to clipboard |
| `cib` / `cab` | Normal (`vicmd`) | Change inside / around innermost brackets (deletes & returns to Insert mode) |
| `ciq` / `caq` | Normal (`vicmd`) | Change inside / around innermost quotes (deletes & returns to Insert mode) |

### Keybindings & Initialization

- **Insert Mode Default**: Every new command prompt starts in Vi Insert mode (`_zvm_custom_zle_line_init`).
- **History Navigation**: `Ctrl+K` / `Ctrl+J` and Up/Down arrows perform prefix-aware history searches; `Ctrl+R` opens Atuin; `Ctrl+T` triggers the Matchmaker jump widget.

## Automatic Monitor Management via Kanshi

Display profiles and hotplug events are automatically handled by [`kanshi`](https://github.com/emersion/kanshi), a Wayland monitor daemon.

### How it Works

- **Autostart**: `kanshi` is launched on session start via [`hypr/.config/hypr/autostart.conf`](../hypr/.config/hypr/autostart.conf):
  ```ini
  exec-once = kanshi
  ```
- **Hotplug Detection**: `kanshi` listens to Wayland output events. When an external monitor (or Ultrawide display) is plugged in or disconnected, it automatically applies matching display profiles without restarting Hyprland.
- **Profile Layouts**: Managed in the [`kanshi`](../kanshi) package (target: `~/.config/kanshi/config`). Example profile configuration from [`kanshi/.config/kanshi/config.ultrawide`](../kanshi/.config/kanshi/config.ultrawide):

  ```kanshi
  # External Ultrawide connected: disable laptop screen, set HDMI resolution & reserved space
  profile {
      output "eDP-1" disable
      output "HDMI-A-1" mode 2560x1080 position 0,0
      exec hyprctl keyword monitor "HDMI-A-1,addreserved,-10,0,0,0"
  }

  # Standalone laptop: enable internal display
  profile {
      output "eDP-1" enable
  }
  ```

### Useful Commands

- Inspect active display output names & modes:
  ```bash
  hyprctl monitors
  ```
- Manually reload or restart kanshi daemon:
  ```bash
  killall kanshi && kanshi &
  ```

## Smart Tab Completion & Directory Jump (`_smart_tab`)

The shell tab completion behavior in [`zsh/.zsh/utils/binds.zsh`](../zsh/.zsh/utils/binds.zsh) is augmented with context-aware logic (`_smart_tab`):

- **Context-Aware Behaviors**:
  - **Empty Line (`<Tab>`)**: Directly opens `_jump_widget` (Matchmaker / Zoxide directory selection) for zero-friction directory jumping without pre-typing `j`.
  - **Active Command Line (`<Tab>` with text, e.g., `ls /path`)**: Executes standard Zsh completion (`expand-or-complete` / `fzf-tab`) without interrupting command argument completion.
  - **Shortcut (`h<Tab>`)**: Clears input and triggers `_zcd_widget` (Zoxide directory navigation).
- **Autosuggestions**: If ghost text is active, `<Tab>` accepts the suggestion immediately (`autosuggest-accept`).
- **Direct Hotkey (`Ctrl+T`)**: Unconditionally opens the Matchmaker jump picker interface at any prompt state.

## Ghostty Terminal Enhancements

Configurations in [`ghostty/.config/ghostty/config`](../ghostty/.config/ghostty/config) provide several advanced terminal features:

- **CSI u Key Escapes**: Maps `Ctrl+1` through `Ctrl+9` and `Ctrl+~` to explicit CSI u escape codes (e.g. `\x1b[49;5u`), ensuring terminal multiplexers like `tmux` reliably capture window navigation keybindings.
- **Hyprland Performance (`epoll`)**: Sets `async-backend = epoll` to eliminate event loop latency under Hyprland.
- **Custom Shaders**: Includes GPU GLSL shader effects (`cursor_frozen.glsl` / `cursor_blaze.glsl`) for custom visual cursor rendering.

## Battery Management & CPU Power Profiles

Hardware battery health and CPU energy management scripts shipped in the [`battery`](../battery) stow package (`battery/.local/bin/`):

- **Charging Thresholds (`battery-threshold`)**: Sets hardware battery charge limits (e.g. 80%) to minimize battery degradation when plugged in long-term.
- **CPU Performance Toggle (`perf-toggle`)**: Switches CPU energy-performance hints between `performance`, `balanced`, and `power-saver` modes on the fly.
- **Waybar Status (`perf-waybar`)**: Integrates live power state and battery condition into the Waybar status bar.

## Theme-aware styling everywhere

Every visible component (Hyprland, waybar, fuzzel, walker, mako, ghostty, kitty, nvim, btop,
hyprlock, swayosd, chromium, obsidian, keyboard RGB) restyles when the Omarchy theme changes,
because their configs are rendered from `colors.toml` templates. See
[SYSTEM_THEME.md](SYSTEM_THEME.md) for the render pipeline.