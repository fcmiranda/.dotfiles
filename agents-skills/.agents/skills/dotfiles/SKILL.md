---
name: dotfiles
description: >-
  REQUIRED for inspecting, modifying, managing, or expanding the ~/.dotfiles GNU Stow repository.
  Use whenever adding new stow packages, writing or updating package install scripts in .shell/install/,
  editing install.zsh or helpers.zsh, managing stow symlinks, auditing stow-lock.json, verifying worktree
  isolation (awt), adhering to docs governance (docs-lint.sh), syncing intelli-shell custom.commands, or
  maintaining dotfiles architecture and ergonomics. Triggers on: dotfiles, stow, stow.sh, install scripts,
  package management, symlink health, .shell/install/, intelli-shell sync, worktree safety.
---

# Dotfiles Master Engineer Skill

This skill equips you to safely manage, modify, extend, and audit `~/.dotfiles` — a GNU Stow-based dotfiles architecture with Git worktree orchestration on Arch Linux / Omarchy.

---

## 🏛️ 1. Repository Architecture & Stow Model

```text
~/.dotfiles/main/
├── stow.sh                              # Central GNU Stow orchestrator
├── stow-lock.json                       # Generated state tracking stowed files (DO NOT EDIT MANUALLY)
├── agents-skills/                       # Dedicated stow package for agent skills & Antigravity config
│   ├── .agents/skills/<name>/SKILL.md   # Shared skill definitions stowed to ~/.agents/skills/
│   └── .gemini/config/skills.json       # Registers ~/.agents/skills in Antigravity
├── .agents/skills/                      # Worktree-level skill symlinks for immediate IDE discovery
├── .shell/install/                      # Source of truth for bootstrap & software lifecycle
│   ├── install.zsh                      # Main entrypoint sourcing package & plugin installers
│   ├── helpers.zsh                      # pkg_install, pkg_is_installed, install_packages
│   ├── packages/<name>.zsh              # Per-package custom installer scripts (sourced)
│   └── plugins/<name>.zsh               # Plugin installers for Zsh/Tmux (sourced)
├── docs/                                # Canonical categorized documentation (English only)
└── <package>/                           # Each top-level directory is an isolated stow package
    └── .config/<app>/...                # Mirrored directory tree mapped directly to ~/.config/<app>/
```

### 1.1 Working Model & Worktree Safety
- **Top-Level Stow Packages:** Treat every top-level directory as a stow package unless it is `.bare`, `.git`, `.github`, `.shell`, `scripts`, or `docs`.
- **Mirrored Home Directory:** Files inside packages strictly mirror `$HOME`. Example: `nvim/.config/nvim/...` maps to `~/.config/nvim/...`.
- **Primary Worktree Exclusive:** The primary worktree (`~/.dotfiles/main`) is the ONLY worktree stowed to `$HOME`. Feature worktrees (managed via `awt`) are sandboxes and must NEVER be stowed.
- **Lockfile Integrity:** `stow-lock.json` is generated state. Never edit it by hand.

---

## 🛠️ 2. Package & Symlink Management (`stow.sh`)

```bash
# Preview symlink changes without applying (Dry run)
./stow.sh -n

# Inspect currently stowed packages from the lockfile
./stow.sh -s

# Stow a specific package
./stow.sh <package>

# Restow a package (refresh symlinks after adding new files or directories)
./stow.sh -r <package>

# Unstow a package (safely remove symlinks)
./stow.sh -d <package>

# Adopt existing target files into the repository
./stow.sh -a <package>
```

### Restow Protocol
Whenever you create or add a new file inside an existing package, you MUST run:
```bash
./stow.sh -r <package>
```
To verify that the live target in `$HOME` resolves correctly:
```bash
readlink -f ~/.config/<app>/<file>
```

---

## 📦 3. Package Installation Engine (`.shell/install`)

The file `.shell/install/install.zsh` is the definitive source of truth for software installation.

### 3.1 Standard Packages (pacman / AUR)
Append the package name directly to `install_packages` in `.shell/install/install.zsh`. `helpers.zsh` executes `pkg_install` using `yay` (falling back to `pacman`).

### 3.2 Custom Package Installers (`.shell/install/packages/<name>.zsh`)
When a package requires compiling from source, custom configuration, or non-AUR binaries:
1. Create `.shell/install/packages/<name>.zsh`.
2. Add `<name>` to `install_packages` in `install.zsh`.
3. **CRITICAL:** Custom installer scripts are **sourced**, not executed in a subshell.
   - Use `return` for early exits, **NEVER `exit`** (which would terminate the entire install process).
   - Place user binaries in `~/.local/bin/`.
   - Place GUI desktop entries in `~/.local/share/applications/`.
   - Print formatted progress with `print -P "%F{green}  ✓%f ..."`.

---

## 📜 4. Governance & Verification Protocols

### 4.1 Documentation Governance
- **Language:** ALL documentation, skill definitions, markdown files, and references MUST be written in **English**.
- **Living Documentation Principle:** Code and documentation must never diverge. When modifying keybindings, shell functions, or workflow tools, update canonical docs under `docs/` in the SAME commit.
- **Root Directory Cleanliness:** Never create loose markdown files in the repository root.
- **Verification:** Always execute `./scripts/docs-lint.sh` before completing tasks to verify markdown link integrity and root cleanliness.

### 4.2 IntelliShell Command Catalog Sync
Whenever creating, altering, or deprecating a CLI tool, alias, or script:
- Update `intelli-shell/.config/intelli-shell/custom.commands` in the SAME commit.
- Format placeholders using `{{param}}` and include completion helpers where applicable.

### 4.3 Ergonomics & Zero-Churn
- Consult `docs/architecture/terminal-ergonomics-and-ux-manifesto.md` and the `tui-ux-architect` skill before modifying keybindings or TUI components.
- Never alter consolidated muscle memory (e.g., `j + Enter`, `Ctrl+G`, `Tab`).
