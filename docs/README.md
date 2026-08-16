# Dotfiles Documentation Index

Welcome to the central documentation index for this Arch Linux + Omarchy dotfiles setup.

---

## 📚 Categorized Documentation

### 🐚 1. Shell & Navigation (`docs/shell/`)
- [**Smart Tab Completion & Matchmaker**](shell/completion.md): Context-aware `<Tab>`, auto-spacing on aliases (`gco<Tab>`), dual backends (`Ctrl+N` vs `Ctrl+F`), and the [`ftb.toml`](../matchmaker/.config/matchmaker/presets/ftb.toml) preset with on-demand preview (`Ctrl+P`).
- [**Zsh Vi Mode & Custom Surrounds**](shell/vi-mode.md): `zsh-vi-mode` integration, dynamic Starship prompt sync (`ZVM_MODE`), and unified surround text objects (`ib`, `ab`, `iq`, `aq`).

### 🪟 2. Tmux & Multiplexer (`docs/tmux/`)
- [**AI Agent Status in Status Bar**](tmux/ai-status-bar.md): Real-time per-pane AI agent state pills, animated spinners, color alerts, and `acpd` daemon options.
- [**Clipboard & Scrollback Capture**](tmux/clipboard-and-scrollback.md): Click-and-hold drag-to-copy to system clipboard, and `Prefix + C-e` scrollback buffer export to Neovim with full ANSI color formatting.
- [**Tmux Activity Monitoring**](TMUX_ACTIVITY.md): Activity alert and notification behavior.

### 🖥️ 3. Desktop, Terminal & Hardware (`docs/desktop/`)
- [**System, Displays & Hardware**](desktop/system-and-hardware.md): Kanshi Wayland display hotplug profiles, Ghostty terminal enhancements (CSI u escapes, epoll, custom shaders), and battery charge thresholds / CPU power profiles.
- [**Nerd Fonts Configuration**](NERD_FONTS.md): Font glyph setup and symbol rendering.
- [**Hyprland Crash Recovery**](HYPRLAND_CRASH_FIX.md): Crash triage and stability fixes.

### 🎨 4. Theme & Design System (`docs/theme/`)
- [**System Theming Architecture**](SYSTEM_THEME.md): The Omarchy theme rendering pipeline, `colors.toml` template generation, overrides, and live reload hooks.

### ⚡ 5. Utilities & Commands
- [**Utils & Command Reference**](UTILS.md): Quick reference for repository scripts (`stow-it`, `killport`, `dotadd`, `wtr`, `battery-threshold`, `perf-toggle`, Hyprland refresh helpers).

---

## 🤖 AI Workflow & Agent Architecture
- [**TUI AI Workflows**](tui-ai-workflows.md): Interactive workflows and design patterns for agentic development.
- [**Autonomous Agent Examples**](autonomous-agent-examples.md) ([EN](autonomous-agent-examples-en.md)): Practical scenarios and agent configurations.
- [**AI Jail & Memory Architecture**](ai-jail-memory-guide-pt.md) ([EN](ai-jail-memory-guide-en.md)): Memory isolation and workspace jail documentation.
- [**AI Workflow Definitive Analysis**](ai-workflow-definitive-analysis-pt.md) ([EN](ai-workflow-definitive-analysis.md)): Deep dive into agent tool use and telemetry.
