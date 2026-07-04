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

## Notable features

### Click-and-hold to copy text inside tmux

Clicking and dragging (click-and-hold) the mouse over text inside a tmux pane selects it and
copies it to the system clipboard. **This is a tmux feature.** It is enabled by two pieces of
[`tmux/.config/tmux/tmux.conf`](tmux/.config/tmux/tmux.conf):

It is enabled by two pieces of [`tmux/.config/tmux/tmux.conf`](tmux/.config/tmux/tmux.conf):

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
[`ghostty/.config/ghostty/config`](ghostty/.config/ghostty/config): `control+insert` copies the
terminal selection to the clipboard and `shift+insert` pastes.

#### Requiring `xclip`

The binding shells out to `xclip`, so `xclip` must be installed (`pacman -S xclip`). Without it the
drag-to-copy will select text but won't populate the system clipboard.

## Useful references

- [AGENTS.md](AGENTS.md) — working model for agents editing this repo
- [git-worktree-guide.md](git-worktree-guide.md) / [GIT_WORKTREE_SETUP.md](GIT_WORKTREE_SETUP.md)
- [stow.sh](stow.sh)
- [.shell/install/README.md](.shell/install/README.md)
- [.commitlintrc.json](.commitlintrc.json) / [git/GC_SGC.md](git/GC_SGC.md) — commit conventions