# Utils & useful commands

This repo ships a small set of helpers in `utils/.local/bin/` (stowed to `~/.local/bin/`), plus a
much larger set provided by Omarchy under `~/.local/share/omarchy/bin/`. The most useful ones:

## Repo helpers (`~/.local/bin/`)

These come from the [`utils`](../utils) stow package.

| Command | Purpose |
|---------|---------|
| `stow-it <path> [package]` | Adopt an existing file or dir into the dotfiles repo and stow it. Resolves the real path, moves it under `~/.dotfiles/main/<package>/...`, and runs `stow.sh -a <package>`. |
| `battery-threshold [pct]` | Set hardware battery charge threshold (e.g., `80`) to extend battery lifespan (`battery` package). |
| `perf-toggle` | Toggle CPU energy performance profile between performance, balanced, and power-saver (`battery` package). |
| `battery-health` | Display battery health stats, current capacity, and cycle count (`battery` package). |
| `omarchy-style-waybar-position <top\|bottom\|left\|right>` | Move Waybar to a different screen edge. |
| `gpucheck [--fix] [--watch]` | NVIDIA / Intel GPU, driver, and energy-performance diagnostics. |
| `gpu-toggle` | Switch between NVIDIA dedicated and Intel integrated GPU via EnvyControl. Requires sudo and a reboot. |
| `killothers [--dry-run] [--force] [--signal SIGNAL]` | Kill processes owned by *other* users while preserving the current user's session. |
| `memtop [--kill] [--report] [--watch] [--top N]` | Interactive memory analyzer and process killer. |
| `git` | Thin wrapper around `/usr/bin/git` (unsets `LD_LIBRARY_PATH` before execving real git). |

## Zsh Shell Helpers

Defined in [`zsh/.zsh/utils/functions.zsh`](../zsh/.zsh/utils/functions.zsh):

| Command / Function | Purpose |
|-------------------|---------|
| `killport <port>` | Find and terminate any process or Docker container listening on specified TCP port (e.g. `killport 3000`). |
| `dotadd <package> [files...]` | Copy file(s) into `~/.dotfiles/main/<package>/` with correct stow structure and trigger restow automatically. |
| `wtr [old-name] <new-name>` | Rename a git worktree directory and its branch atomically. |

## Stow management

Run from `~/.dotfiles/main`:

```bash
./stow.sh                 # sync: show unstowed packages, prompt to stow
./stow.sh -s              # list currently stowed packages (from stow-lock.json)
./stow.sh -n              # dry run — report what would change
./stow.sh <pkg>           # stow a single package
./stow.sh -r <pkg>        # restow (refresh symlinks) a single package
./stow.sh -a <pkg>        # adopt existing files in $HOME into the repo
./stow.sh -d <pkg>        # unstow (remove symlinks)
```

`stow-lock.json` is generated state — never edit it manually.

## Refreshing Hyprland

After editing `~/.config/hypr/*.conf`, apply the change without restarting the session:

```bash
omarchy-refresh-hyprland       # overwrite ~/.config/hypr/* with Omarchy defaults, then reload
omarchy-restart-hyprctl        # just `hyprctl reload` — re-reads the existing config files
omarchy-refresh-config <rel>   # copy one file from ~/.local/share/omarchy/config/... to ~/.config/...
```

For a single edited file you can also just point `hyprctl` at it:

```bash
hyprctl reload
```

The `theme-set` hook (see [SYSTEM_THEME.md](SYSTEM_THEME.md)) already calls
`omarchy-restart-hyprctl` after a theme swap, so you don't need to do this manually on theme
changes.

## Restarting other components

Omarchy ships focused restart helpers — useful after editing a config or when something wedges:

```bash
omarchy-restart-waybar
omarchy-restart-mako
omarchy-restart-fuzzel
omarchy-restart-walker
omarchy-restart-terminal         # signals the running terminal emulator to reload
omarchy-restart-tmux             # reload tmux config across running sessions
omarchy-restart-hypridle
omarchy-restart-hyprlock
omarchy-restart-hyprsunset
omarchy-restart-swayosd
omarchy-restart-btop
omarchy-restart-opencode
omarchy-restart-pipewire
omarchy-restart-bluetooth
omarchy-restart-wifi
omarchy-restart-trackpad
omarchy-restart-xcompose
```

## Hyprland monitor / window helpers

```bash
omarchy-hyprland-monitor-focused
omarchy-hyprland-monitor-internal
omarchy-hyprland-monitor-scaling-cycle
omarchy-hyprland-monitor-watch
omarchy-hyprland-toggle                       # enable/disable Hyprland monitor handling
omarchy-hyprland-window-pop
omarchy-hyprland-window-gaps-toggle
omarchy-hyprland-window-single-square-aspect-toggle
omarchy-hyprland-workspace-layout-toggle
omarchy-hyprland-active-window-transparency-toggle
omarchy-hyprland-window-close-all
```

## Theme commands

See [SYSTEM_THEME.md](SYSTEM_THEME.md) for the full theme system. Quick reference:

```bash
omarchy-theme-list                # available themes
omarchy-theme-current             # active theme name
omarchy-theme-set <name>          # switch theme
omarchy-theme-refresh             # re-render current theme
omarchy-theme-bg-set <path>       # set wallpaper for current theme
omarchy-theme-bg-next             # next built-in wallpaper
```

## Hardware / system helpers

```bash
omarchy-cmd-screenshot            # screenshot utility
omarchy-cmd-screenrecord
omarchy-cmd-screensaver
omarchy-cmd-share
omarchy-cmd-audio-switch         # switch audio output device
omarchy-cmd-mic-mute             # mute mic (variant per hardware)
omarchy-brightness-display       # display brightness control
omarchy-brightness-keyboard       # keyboard backlight
omarchy-battery-status           # battery info / present / remaining / capacity
omarchy-hibernation-available / omarchy-hibernation-setup / omarchy-hibernation-remove
omarchy-font-list / omarchy-font-set / omarchy-font-current
omarchy-emoji-picker
```

Discover all of them with `ls ~/.local/share/omarchy/bin/` (248+ scripts) or run any command with
`-h` / `--help` for usage.

## Adding a new helper

1. Drop a script under `~/.dotfiles/main/utils/.local/bin/<name>` (or the right stow package for
   the file path).
2. Make it executable: `chmod +x utils/.local/bin/<name>`.
3. Run `./stow.sh -r utils` to refresh the symlink into `~/.local/bin/`.