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
`procs`, `sesh`, `starship`, `tmux`, `tuikit`, `utils`, `walker`, `waybar`, `yazi`, `zoxide`,
`zsh`, `zsh-plugins`.

Non-stow directories: `.bare`, `.git`, `.github`, `.shell`, `scripts`.

## Tooling

- **Shell:** zsh
- **Terminal:** [Ghostty](https://ghostty.org/)
- **Multiplexer:** [tmux](https://github.com/tmux/tmux)
- **Editor:** Neovim
- **WM:** Hyprland (via Omarchy)
- **Package manager:** `yay` / `pacman`

## Docs

- [docs/SYSTEM_THEME.md](docs/SYSTEM_THEME.md) — how the Omarchy theme system renders per-app
  configs from `colors.toml`, and how this repo extends it via overrides + the `theme-set` hook.
- [docs/FEATURES.md](docs/FEATURES.md) — notable behaviors, including click-and-hold copy inside
  tmux, scrollback capture to Neovim, Zsh Vi mode (`vi-cmd-mode`) with custom surrounds & Starship integration, Kanshi monitor management, smart Tab completion (`_smart_tab`), Ghostty CSI u sequence forwarding & epoll optimizations, and battery / power profile management.
- [docs/UTILS.md](docs/UTILS.md) — useful commands shipped here and by Omarchy, including `killport`, `dotadd`, `wtr`, `battery-threshold`, `perf-toggle`, Hyprland refresh helpers, and component restart scripts.

## Useful references

- [AGENTS.md](AGENTS.md) — working model for agents editing this repo
- [git-worktree-guide.md](git-worktree-guide.md) / [GIT_WORKTREE_SETUP.md](GIT_WORKTREE_SETUP.md)
- [stow.sh](stow.sh)
- [.shell/install/README.md](.shell/install/README.md)
- [.commitlintrc.json](.commitlintrc.json) / [git/GC_SGC.md](git/GC_SGC.md) — commit conventions