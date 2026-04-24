---
name: dotfiles
description: >
  REQUIRED for any changes to ~/.dotfiles. Use when adding packages, writing
  package install scripts, editing install.zsh, modifying helpers.zsh, adding
  plugin scripts, managing stow packages, or editing any config file tracked
  in the dotfiles repo. Triggers: install scripts, package management, stow,
  symlinks, zsh config, shell plugins, tmux plugins, dotfiles structure.
---

# Dotfiles Skill

Manage the `~/.dotfiles` repository — a GNU Stow-based dotfiles setup on Arch Linux / Omarchy.

## Repository Layout

```
~/.dotfiles/
├── stow.sh                    # GNU Stow manager (run to stow/unstow packages)
├── stow-lock.json             # Tracks stowed packages and their symlinks
├── .shell/
│   └── install/
│       ├── install.zsh        # Main install entrypoint — lists all packages/plugins
│       ├── helpers.zsh        # pkg_install, pkg_is_installed, install_packages, install_plugins
│       ├── packages/          # Per-package custom install scripts (<name>.zsh)
│       └── plugins/           # Plugin install scripts (zsh-plugins.zsh, tmux-plugins.zsh)
├── <package>/                 # Each directory is a stow package
│   └── .config/<app>/        # Files mirrored to ~/.config/<app>/ via symlinks
│       ...
```

### Stow packages (directories in ~/.dotfiles/ that map to ~/)

Each top-level directory (except `.git`, `.github`, `.shell`, `scripts`) is a stow package.
Running `stow.sh` creates symlinks from `~/<path>` → `~/.dotfiles/<package>/<path>`.

Current stow packages:
`atuin`, `bat`, `duf`, `eza`, `fed`, `figlet`, `fonts`, `fzf`, `gh`, `ghostty`,
`git`, `hypr`, `kanshi`, `lolcat`, `mako`, `mise`, `nvim`, `omarchy`, `performance-battery-plan.md`,
`procs`, `sesh`, `starship`, `tmux`, `utils`, `vimium`, `walker`, `waybar`, `workflow.md`,
`xkb`, `yazi`, `zoxide`, `zsh`, `zsh-plugins`

## Install System

### `install.zsh` — entrypoint

Lists packages and plugins to install:

```zsh
install_packages \
    some-pkg \
    another-pkg \

install_plugins \
    zsh-plugins \
    tmux-plugins
```

**To add a new package:** append it to the `install_packages` list in `install.zsh`.

### `helpers.zsh` — core functions

| Function | Purpose |
|----------|---------|
| `pkg_install <pkg>` | Install via `yay` (preferred) or `pacman`. Skips gracefully on aarch64 arch-mismatch. |
| `pkg_is_installed <pkg>` | Returns 0 if binary in PATH or package in DB |
| `install_packages <...>` | Iterates list; runs `packages/<name>.zsh` if it exists, else `pkg_install` |
| `install_plugins <...>` | Iterates list; sources `plugins/<name>.zsh` |

### `packages/<name>.zsh` — custom install scripts

Create one when a package needs more than `pkg_install` (build from source, post-install config, etc.).

**Pattern:**

```zsh
#!/usr/bin/env zsh
set -euo pipefail

# Install deps
# Build/configure
# Place binary in ~/.local/bin/ or system path
# Create ~/.local/share/applications/<name>.desktop if it's a GUI app
# Print status with print -P "%F{green}  ✓%f ..."
```

- These scripts are **sourced** (not executed) by `install_packages`, so use `return` not `exit` for early exits.
- Use `print -P` for colored output matching the helper style.
- Check `pkg_is_installed` / `command -v` before reinstalling.
- Handle aarch64 if relevant (see `upscayl.zsh` for example).

### `plugins/<name>.zsh` — plugin install scripts

For zsh/tmux plugins. Also sourced by `install_plugins`.

## `stow.sh` — GNU Stow manager

```bash
./stow.sh                    # Sync: show unstowed packages, prompt to stow
./stow.sh <pkg>              # Stow a specific package
./stow.sh -a <pkg>           # Adopt existing files into repo
./stow.sh -d <pkg>           # Unstow (remove symlinks)
./stow.sh -r <pkg>           # Restow (refresh symlinks)
./stow.sh -n                 # Dry run
./stow.sh -s                 # Show stowed packages from lock file
```

`stow-lock.json` tracks every stowed package and its symlinks. Do not edit manually.

### Restow rule after file changes

When creating or updating files inside a stow package, always consider running:

```bash
./stow.sh -r <package>
```

Use this to refresh symlinks and ensure the live file in `~/` points to the updated dotfiles-managed path.

## Common Tasks

### Add a new package installable via pacman/AUR

1. Append the package name to `install_packages` in `install.zsh`.
2. No script needed — `helpers.zsh` will call `pkg_install` automatically.

### Add a package that requires a custom install (build from source, etc.)

1. Create `packages/<name>.zsh` with the build/install logic.
2. Append `<name>` to `install_packages` in `install.zsh`.
3. The `install_packages` function will detect the script and source it instead of calling `pkg_install`.

### Add a new dotfile/config to track

1. Create the directory structure inside the appropriate stow package:
   ```
   ~/.dotfiles/<package>/.config/<app>/config-file
   ```
2. Run `./stow.sh <package>` (or `./stow.sh -r <package>` if already stowed) to create/refresh the symlink.

### Add a new stow package

1. Create a new top-level directory in `~/.dotfiles/<new-package>/`.
2. Place files in it mirroring their `~/` paths (e.g., `.config/app/file`).
3. Run `./stow.sh <new-package>`.

## After Every Task — Commit and Push

After completing any change to `~/.dotfiles`, always commit and push:

```bash
cd ~/.dotfiles
git add -A
git commit -m "feat: <short description of what changed>"
git push
```

- Follow the existing commit style: `feat:`, `fix:`, `refactor:`, etc.
- One commit per logical task.
- Always push immediately after committing — the remote should stay in sync.

## Architecture Notes

- **Shell:** zsh throughout (scripts use `#!/usr/bin/env zsh`).
- **Package manager:** `yay` (AUR helper) preferred; falls back to `pacman`.
- **aarch64 awareness:** `pkg_install` silently skips packages unavailable for aarch64. Custom scripts should handle it explicitly when building from source.
- **No `exit` in sourced scripts:** use `return` inside `packages/*.zsh` and `plugins/*.zsh`.
- **Binary placement:** user-compiled binaries go in `~/.local/bin/`. That path is in `$PATH`.
- **Desktop entries:** GUI apps get a `.desktop` in `~/.local/share/applications/`.
