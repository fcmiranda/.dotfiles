# System & Architecture Review

This is an elite, bleeding-edge zero-friction architecture. By unifying your AI control plane via a custom Rust daemon (`acpd`) with native IPC, adopting a strict zero-prefix keybinding philosophy, and leveraging modern Rust-based fuzzy finders (`mm` instead of standard `fzf`), you have effectively solved most typical developer friction points.

However, auditing your setup against the design philosophies of ThePrimeagen (relentless motion efficiency, zero latency, high signal-to-noise UI), TJ DeVries (native Neovim/Lua APIs, deep Telescope/picker extensibility), Folke Lemaitre (structured, unified UI surfaces, high-QoL micro-plugins), and Linkarzu (systematic tmux/neovim workspace orchestration and clean automation scripts) reveals a few lingering anti-patterns and concrete areas for optimization.

---

## 1. Audit: Friction Points, Cognitive Taxes & Shortcut Collisions

### A. The `<Tab>` Overload & State-Dependent Cognitive Tax

- **The Problem:** You have bound `<Tab>` to act differently depending on prompt state (empty line $\rightarrow$ `mm` + `zoxide` frecency jump; active text $\rightarrow$ `fzf-tab`). While conceptually clever, modal overloading on `<Tab>` introduces a subtle cognitive tax. If you accidentally hit space or enter a typo, pressing `<Tab>` triggers autocompletion instead of your directory jumper.
- **The Architectural Fix:** Decouple these intents. Keep `<Tab>` strictly for completion (`fzf-tab` or native shell completion). Use a dedicated, invariant zero-prefix binding for frecency directory jumps (e.g., `Alt+d` or `Ctrl+f`). An action’s trigger should never depend on whether the command line is dirty.

### B. Popup Stack Collisions (`Alt+s`, `Alt+o`, `Alt+g`)

- **The Problem:** You rely heavily on popups: `Alt+s` for sessions, `Alt+o` for your floating AI overlay, and `Alt+g` for `lazygitrs`. If you trigger `lazygitrs` or your AI overlay inside an existing Tmux popup—or trigger a Tmux popup over a Ghostty floating overlay—you risk input-capture traps and nested floating window z-index bugs.
- **The Architectural Fix:** Standardize your popup authority layer:
  - **Rule of Thumb:** If it is a global tool (session switching, AI overlay), Tmux must own the floating pane (`tmux display-popup -E ...`).
  - If it is a project-local context (Git review, file exploration), Neovim should own the floating window (`lazygit` via Neovim terminal buffers, or via `Snacks.nvim` terminal). Never spawn a Tmux popup from within an active Neovim floating terminal.

### C. Buffer-to-Tmux Session Leakage

- **The Problem:** You have `Alt+a` mapped to a semantic jump to a dedicated `ai` window, plus `Alt+i` to cycle through notifying AI agent panes. Moving out of Neovim to a separate Tmux window/pane for AI interaction breaks Neovim's register/buffer continuum. You lose direct visual-selection piping, LSP context injection, and instant buffer diffing without external clipboard gymnastics.
- **The Architectural Fix:** Treat external Tmux windows as background job runners only. Interactive AI code review and modification should live inside Neovim buffers or Neovim floating terminals so they can directly manipulate the AST and buffer history.

---

## 2. Emerging TUI Tools & Shell Patterns (2025/2026 Landscape)

### A. Replace Fragmented Neovim Utilities with `snacks.nvim` (Folke)

If you use LazyVim, Folke’s `snacks.nvim` has consolidated dozens of standalone QoL plugins into a single, high-performance Lua library.

- **Snacks Picker & Explorer:** Replaces older pickers with a unified, blazing-fast finder that natively supports frecency and LSP workspace symbols without blocking the UI thread.
- **Snacks Terminal:** Instead of managing `lazygitrs` via Tmux popups (`Alt+g`), invoke `Snacks.lazygit()` or open your AI control plane CLI via `Snacks.terminal.toggle()`. This keeps the AI/Git context inside Neovim, inheriting your active colorscheme and clipboard registers automatically.
- **Snacks Image:** Modern Kitty/Ghostty graphics protocol integration inside Neovim for rendering Markdown/LaTeX/diagrams natively.

### B. Ghostty Native Integration & OSC 7 / OSC 52

- **OSC 7 (Working Directory Reporting):** Ensure your Zsh prompt emits OSC 7 escape sequences. Ghostty uses this to instantly know the current working directory of the active shell. When you split panes or spawn a new Ghostty window, it inherits the directory at the compositor/terminal level with zero shell-startup lag.
- **OSC 52 (Clipboard Passthrough):** Ensure Tmux has `set -g set-clipboard on`. This allows your custom Rust daemon (`acpd`) and Neovim to push content directly to Arch Linux’s Wayland clipboard (`wl-copy`) over SSH or local Tmux sockets without requiring external X11/Wayland clipboard wrappers.

### C. Multiplexer Optimization: Tmux Control Mode vs. Native Automation

- **Linkarzu-Style Automation Scripts:** Implement background garbage collection for Tmux sessions. A common 2025/2026 pattern is using an automated daemon script that kills detached `sesh` workspaces after $X$ hours of inactivity, preventing your multiplexer tree from growing stale.
- **IPC Socket Merging:** Since `acpd` runs on `127.0.0.1:4040`, expose a Unix domain socket (`/run/user/1000/acpd.sock`) alongside TCP. Unix sockets eliminate loopback TCP overhead for local Tmux status-bar polling (`#()` scripts) and Neovim RPC clients.

---

## 3. Terminal/Shell Layer vs. Editor (LazyVim) Layer: Redundancy Audit

There is a natural tension between Tmux-centric workflows (ThePrimeagen) and Neovim-centric workflows (TJ DeVries / Folke). Here is where your layers overlap and how to prune unnecessary redundancy:

| Function | Your Current Handling | Recommended Authority | Architectural Justification |
| :--- | :--- | :--- | :--- |
| **Git Operations** | `Alt+g` (`lazygitrs` popup) AND `<leader>gs` (Neovim native diffs) | Neovim / Snacks (`Snacks.lazygit()` + `<leader>gs`) | Using Tmux to spawn Git popups over Neovim disconnects Git state from open buffers. Running Git tools inside Neovim allows auto-reloading buffers on commit/rebase. |
| **File / Project Navigation** | `sesh` + Matchmaker (`mm`) AND Neovim pickers | Split Responsibilities:<br>• `sesh` = Project switching<br>• Neovim = In-project file navigation | Do not use shell tools to jump between files inside an already-open Neovim project. Once inside a `sesh` workspace, Neovim's picker owns all file/buffer traversal. |
| **AI Control Plane (`acpd`)** | `Alt+a` / `Alt+o` / `Alt+i` (Tmux window/pane jumps) | Hybrid Approach:<br>• Tmux = Background execution/logs<br>• Neovim = Code generation & diff application | Do not write code in a separate Tmux window and copy-paste it into Neovim. Implement a lightweight Neovim Lua client for `acpd` that reads the JSON-RPC stream and renders virtual text or floating diffs directly in your active buffer. |

---

## 4. Concrete Action Plan & Configuration Upgrades

### 1. Hard-Wire OSC 7 in Zsh for Instant Ghostty Directory Sync

Add this to your `.zshrc` so Ghostty and Tmux always track your active path without parsing `pwd`:

```bash
# Emit OSC 7 working directory notification on directory change
function chpwd() {
  printf "\033]7;file://%s%s\033\\" "${HOSTNAME}" "${PWD}"
}
```

### 2. Refactor Git Review into Neovim via `snacks.nvim`

Remove your global Tmux `Alt+g` binding for `lazygitrs`. Instead, map `Alt+g` inside Neovim to invoke a terminal buffer. This prevents multiplexer popup collisions and preserves buffer focus:

```lua
-- In your LazyVim custom keymaps (lua/config/keymaps.lua)
vim.keymap.set("n", "<A-g>", function()
  require("snacks").lazygit()
end, { desc = "Toggle LazyGit (Snacks)" })
```

### 3. Replace Modal `<Tab>` Overloading with Dedicated Frecency Jumps

Remove the conditional `<Tab>` trap. Bind `<Tab>` purely to shell autocompletion (`fzf-tab`) and assign a fast, unconditional chord to your Matchmaker frecency jump:

```bash
# Remove conditional empty-prompt tab traps
# Bind Alt+d (or your preferred zero-prefix chord) strictly to Matchmaker directory jump
bindkey -s '\ed' 'cd "$(mm --zoxide)"\n'
```

### 4. Optimize Tmux Status Bar Polling for `acpd`

If your Tmux status line polls `acpd` on `127.0.0.1:4040`, ensure you use a persistent IPC script or Unix socket instead of spawning a new `curl`/`nc` process every second, which introduces fork-exec latency into Tmux's render loop.

To see a practical breakdown of modern Linux terminal configurations and how tools like Ghostty are being tuned for zero-latency developer environments, check out Ghostty Terminal Setup & Workflow Deep Dive. This walkthrough demonstrates real-world composability between GPU-accelerated terminal emulators, multiplexer sessions, and modern Neovim environments.