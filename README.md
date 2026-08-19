# .dotfiles

My personal dotfiles for Arch Linux + Omarchy, managed with [GNU Stow](https://www.gnu.org/software/stow/).

## Overview

Each top-level directory is a [Stow](https://www.gnu.org/software/stow/) package that mirrors the
home-directory layout. Running `stow.sh` symlinks the package contents into `$HOME`.

```
~/.dotfiles/<package>/.config/<app>/...   -->   ~/.config/<app>/...
```

## Quick start

```bash
git clone https://github.com/fcmiranda/.dotfiles.git ~/.dotfiles
cd ~/.dotfiles
./stow.sh            # sync: show unstowed packages and prompt to stow
./stow.sh -s         # show currently stowed packages
./stow.sh -r <pkg>   # restow a package (refresh symlinks)
./stow.sh -n         # dry run
```

Package and plugin installation is driven by `.shell/install/install.zsh`, with per-package
scripts in `.shell/install/packages/` and plugin scripts in `.shell/install/plugins/`. See
[.shell/install/README.md](.shell/install/README.md) for details.

## Stow packages

`atuin`, `bat`, `battery`, `bluetui`, `cargo`, `claude`, `duf`, `eza`, `fed`, `figlet`, `fonts`,
`fuzzel`, `fzf`, `gh`, `ghostty`, `git`, `herdr`, `hypr`, `kanshi`, `kitty`, `lazycommit`,
`lazygit`, `lazygitrs`, `lolcat`, `mako`, `matchmaker`, `mise`, `nvim`, `omarchy`, `opencode`,
`procs`, `sesh`, `starship`, `tmux`, `tuikit`, `utils`, `walker`, `waybar`, `yazi`, `zsh`,
`zsh-plugins`.

Non-stow directories: `.bare`, `.git`, `.github`, `.shell`, `scripts`.

## Tooling

- **Shell:** zsh
- **Terminal:** [Ghostty](https://ghostty.org/)
- **Multiplexer:** [tmux](https://github.com/tmux/tmux)
- **Editor:** Neovim
- **WM:** Hyprland (via Omarchy)
- **Package manager:** `yay` / `pacman`

## Docs

See the [**Documentation Index (`docs/README.md`)**](docs/README.md) for the complete sitemap:

- 🐚 [**Shell & Completion (`docs/shell/completion.md`)**](docs/shell/completion.md) — Smart Tab completion (`_smart_tab`), Matchmaker integration (`mm-ftb`), alias auto-spacing (`gco<Tab>`), dual backends, and on-demand preview (`Ctrl+P`).
- ⌨️ [**Zsh Vi Mode (`docs/shell/vi-mode.md`)**](docs/shell/vi-mode.md) — Modal editing, unified surround text objects (`ib`, `ab`, `iq`, `aq`), and live Starship prompt synchronization.
- 🪟 [**Tmux AI Status Bar (`docs/tmux/ai-status-bar.md`)**](docs/tmux/ai-status-bar.md) — Per-pane AI agent state pills, animated spinners, and `acpd` daemon hooks.
- 📋 [**Tmux Clipboard & Scrollback (`docs/tmux/clipboard-and-scrollback.md`)**](docs/tmux/clipboard-and-scrollback.md) — Click-and-hold drag-to-copy and scrollback capture to Neovim with full ANSI color formatting.
- 🖥️ [**System & Hardware (`docs/desktop/system-and-hardware.md`)**](docs/desktop/system-and-hardware.md) — Kanshi display hotplug profiles, Ghostty terminal enhancements, and battery threshold / CPU power profiles.
- 🎨 [**System Theme (`docs/SYSTEM_THEME.md`)**](docs/SYSTEM_THEME.md) — Omarchy theme rendering pipeline from `colors.toml`.
- ⚡ [**Utils & Command Reference (`docs/UTILS.md`)**](docs/UTILS.md) — Repository helpers (`stow-it`, `killport`, `dotadd`, `wtr`, `battery-threshold`, `perf-toggle`, refresh scripts).

## Useful references

- [AGENTS.md](AGENTS.md) — working model for agents editing this repo
- [git-worktree-guide.md](git-worktree-guide.md) / [GIT_WORKTREE_SETUP.md](GIT_WORKTREE_SETUP.md)
- [stow.sh](stow.sh)
- [.shell/install/README.md](.shell/install/README.md)
- [.commitlintrc.json](.commitlintrc.json) / [git/GC_SGC.md](git/GC_SGC.md) — commit conventions