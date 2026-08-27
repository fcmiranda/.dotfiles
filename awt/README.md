# 🌿 AWT — Agent Worktree Manager & Multi-Agent Git Orchestrator

> **Next-generation Git worktree manager powered by [Matchmaker (`mm`)](https://github.com/fcmiranda/matchmaker), [Sesh](https://github.com/joshmedeski/sesh), Tmux floating modals, and Autonomous AI Agent session isolation.**

---

## 🌟 Overview

**`awt` (Agent Worktree Manager)** bridges Git worktrees with terminal multiplexing and autonomous AI agent workflows. Instead of manually juggling directories, creating branches, and running multiple detached terminal tabs, `awt` organizes each worktree as an **isolated, first-class workspace container** with automated lifecycle hooks and real-time visual inspection.

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                            THE AWT ARCHITECTURE                             │
├───────────────────────────────┬─────────────────────────────────────────────┤
│ 1. Git Engine (.bare layout)  │ Sibling worktree directories (0 file locks) │
│ 2. Matchmaker TUI (Rust)      │ Nav Mode, Live 3-Tab Previews, Golden Ratio │
│ 3. Multiplexer (Tmux + Sesh)  │ Floating modal (Ctrl+Shift+G) & Sesh links  │
│ 4. Autonomous AI Agents (agy) │ 1 Agent per worktree, 0 context bleeding    │
│ 5. Lifecycle Automation       │ Automated .env replication, stash & hooks   │
└───────────────────────────────┴─────────────────────────────────────────────┘
```

---

## ✨ Key Features

### 1. 🪟 Global Floating Worktree Modal (`Ctrl + Shift + G`)
* **Zero-Prefix Chord**: Press `Ctrl + Shift + G` from **any window or application** in Tmux ($\text{KLM} = 140\text{ ms}$) to open a floating worktree dashboard.
* **Golden Ratio Geometry**: Sized precisely at $85\% \times 75\%$ with dynamic theme border colors inherited from Omarchy (`#e84d31`).
* **Instant Background Protection**: Protects active terminal panes and AI streams from redraw glitches while the modal is open.

### 2. 🧙 4-Step Conventional Commits Creation Wizard (`c` / `awt -c` / `awc`)
* **Step 1 — Conventional Type Selection**: Pick conventional prefixes with unified Nerd Font icons:
  ` feat`, ` fix`, `󰣪 refactor`, `󰓅 perf`, ` ci`, ` chore`, `󰧮 docs`, `󰙨 test`, `󰏖 build`, `󰓹 custom`.
* **Step 2 — In-Place Branch Prompt**: Fast Matchmaker prompt box with memory of previous inputs; press `Esc` to step back to Step 1 without losing context.
* **Step 3 — Base Branch Selector**: Dynamically highlights the currently selected/active branch at **Row 0** (` <branch> current base`), followed by ` main (default base)` and all other local branches. If branching off the current context, press **`Enter`** (1 stroke) to confirm immediately.
* **Step 4 — Automated Provisioning & Single-Execution Guard**: Creates the worktree, copies `.env` via `post-create.sh`, provisions a dedicated Tmux session via `sesh`, switches client, and dismisses the modal cleanly without duplicate startup commands.

### 3. 📊 Real-Time 3-Tab Live Previews (`p`)
Toggle instantly between 3 live preview panes in Nav Mode:
1. **Status & Recent Graph**: Porcelain status indicators (`+`, `*`, `?`) and recent commit DAG graph.
2. **Diff vs Base**: Full colorized diff against the merge-base of the target branch (`git diff <base>...HEAD`).
3. **Commit Statistics**: Detailed author, date, message, and line change stats for the latest commit.

### 4. 🛡️ Built-in Safety & Dirty State Protection
* **Smart Auto-Stash**: Automatically creates an internal safety stash before running `merge` (`m`) or `rebase` (`R`), popping it transparently once Git completes.
* **Clean Deletions**: Deleting a worktree (`d`) unmounts the directory, deletes the Git branch, terminates the associated Tmux session, and gracefully redirects the client to the last active workspace (`sesh last`).

---

## 🚀 Quick Start & Installation

### Requirements
* **Git** ($\ge 2.30$)
* **[Tmux](https://github.com/tmux/tmux)** ($\ge 3.2$)
* **[Matchmaker (`mm`)](https://github.com/fcmiranda/matchmaker)** (Rust picker engine)
* **[Sesh](https://github.com/joshmedeski/sesh)** (Smart terminal session manager)

### Installation via GNU Stow
Inside your `.dotfiles` directory:
```bash
cd ~/.dotfiles
./stow.sh -r awt
```

This symlinks all presets, scripts, hooks, and CLI executables into:
* `~/.local/bin/awt`, `~/.local/bin/awc`, `~/.local/bin/awp`, `~/.local/bin/awtc`
* `~/.config/matchmaker/presets/awt*.toml`
* `~/.config/matchmaker/scripts/awt*.sh`
* `~/.config/matchmaker/hooks/post-*.sh`
* `~/.config/tmux/awt-popup.sh`

---

## 💻 CLI Commands Reference

| Command | Shortcut / Alias | Description |
| :--- | :---: | :--- |
| `awt` | — | Open interactive Matchmaker TUI dashboard in current pane (30% height). |
| `awt popup` | **`awp`** / `Ctrl+Shift+G` | Open full floating AWT modal ($85\% \times 75\%$) in Tmux. |
| `awt -c` / `awt new` / `awt add` | **`awc`** | Launch the interactive 4-step Conventional Commits wizard. |
| `awt -c <branch> [base]` | — | Create new worktree and immediately attach/switch to its Tmux session. |
| `awt <branch>` / `awt switch <branch>` | — | Switch directly to the Tmux session for the specified worktree. |
| `awt rm <branch>` / `awt del <branch>` | — | Delete worktree directory, Git branch, and kill its Tmux session. |
| `awt rebase [base]` | — | Safely rebase current worktree onto base branch with auto-stash. |
| `awt merge [branch]` | — | Merge current worktree into base branch with lifecycle hooks. |
| `awt clone <repo> [dir]` | **`awtc`** | Clone repository in `.bare` layout and provision initial worktree. |
| `awt help` / `awt -h` | — | Display CLI help and usage options. |

---

## ⌨️ Interactive Dashboard Keybindings (Nav Mode)

When inside the interactive Matchmaker dashboard (`awt` / `awp`):

| Keybinding | Action | Description |
| :---: | :--- | :--- |
| **`Enter`** | **Connect / Switch** | Connect to or create the Tmux session for the selected worktree. |
| **`c`** / **`ctrl-n`** | **New Worktree** | Launch the 4-step Conventional Commits creation wizard. |
| **`m`** | **Merge Worktree** | Merge active branch into target base, execute hooks, and clean up. |
| **`R`** *(Shift+R)* | **Rebase on Base** | Safely auto-stash changes and rebase branch onto configured base. |
| **`r`** / **`ctrl-r`** | **Rename Branch** | Open prompt popover to rename branch in Git, folder, and Tmux. |
| **`d`** / **`ctrl-d`** | **Delete Worktree** | Confirm popover to delete worktree, kill session, and redirect. |
| **`p`** / **`ctrl-p`** | **Cycle Preview** | Toggle through Status, Diff vs Base, and Commit stats. |
| **`u`** / **`ctrl-u`** | **Fetch Remotes** | Run `git fetch --all --prune` on the selected worktree. |
| **`j`** / **`k`** | **Navigation** | Move selection down / up. |
| **`q`** / **`Esc`** | **Quit** | Close picker without performing actions. |

---

## 📁 Package File Layout

```text
~/.dotfiles/main/awt/
├── README.md                        # Documentation & quick start guide
├── .config/
│   ├── matchmaker/
│   │   ├── presets/
│   │   │   ├── awt.toml             # Main dashboard preset with 3 live previews
│   │   │   ├── awt-type.toml        # Step 1: Conventional types selection
│   │   │   ├── awt-prompt.toml      # Step 2: Dynamic branch name input box
│   │   │   └── awt-base.toml        # Step 3: Base branch selector
│   │   ├── scripts/
│   │   │   ├── awt-new.sh           # 4-step wizard orchestration script
│   │   │   ├── awt-delete.sh        # Worktree deletion & Tmux session teardown
│   │   │   ├── awt-merge.sh         # Merge handler with safety auto-stash
│   │   │   ├── awt-rebase.sh        # Rebase handler with safety auto-stash
│   │   │   └── awt-rename.sh        # Branch, folder, and session rename handler
│   │   └── hooks/
│   │       ├── post-create.sh       # .env copying & repo-level hook triggers
│   │       └── post-merge.sh        # Post-merge cleanup & rebuild triggers
│   └── tmux/
│       └── awt-popup.sh             # Floating modal wrapper with backdrop protection
└── .local/
    └── bin/
        ├── awt                      # Global executable CLI entrypoint
        ├── awc                      # Quick shortcut for 'awt -c'
        ├── awp                      # Quick shortcut for 'awt popup'
        └── awtc                     # Standalone .bare repository clone provisioner
```

---

## ⚖️ Comparison: `awt` vs Standard Tools

| Dimension | `wt` / Worktree CLI | `sesh` | `git-worktree.nvim` | **`awt` (Agent Worktree Manager)** |
| :--- | :---: | :---: | :---: | :---: |
| **Interface** | Plain text CLI | Fuzzy picker | Neovim buffer | **Matchmaker TUI + Floating Modal (`Ctrl+Shift+G`)** |
| **Multiplexer Lifecycle** | ❌ None | ✅ Sessions | ❌ None | ✅ **Full Tmux + Sesh Workspace Isolation** |
| **Conventional Wizard** | ❌ None | ❌ None | ❌ None | ✅ **4-Step Wizard (``, ``, `󰣪`, `󰓅`, ``)** |
| **Multi-Tab Live Previews** | ❌ None | ❌ None | ❌ None | ✅ **3 Live Previews (Status, Diff, Stats)** |
| **Lifecycle Hooks** | ❌ None | ❌ None | ❌ None | ✅ **Automatic `post-create` and `post-merge`** |
| **Dirty State Safety** | ⚠️ Aborts | ❌ None | ⚠️ Aborts | ✅ **Automatic Auto-Stash on Merge/Rebase** |
| **AI Agent Isolation** | ❌ None | ⚠️ Manual | ❌ None | ✅ **Native 1-Worktree / 1-Agent Contexts** |

---

## 🔗 Related Documentation
* [Agentic Worktree Master Guide (`docs/GIT_WORKTREE_AGENTIC_WORKFLOW.md`)](../docs/GIT_WORKTREE_AGENTIC_WORKFLOW.md)
* [Tmux Golden Ratio Popups (`docs/tmux/popups-ergonomics-and-golden-ratio.md`)](../docs/tmux/popups-ergonomics-and-golden-ratio.md)
* [Workflow Keybindings Matrix (`docs/architecture/workflow-keybindings-matrix.md`)](../docs/architecture/workflow-keybindings-matrix.md)
