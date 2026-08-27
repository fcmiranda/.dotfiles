# Dotfiles Documentation Index

Welcome to the central documentation index for this Arch Linux + Omarchy dotfiles setup.

---

## 📚 Categorized Documentation

### 🔬 0. Core Philosophy & Ergonomics Manifesto (`docs/architecture/`)
- [**Terminal Ergonomics & UX Architecture Manifesto**](architecture/terminal-ergonomics-and-ux-manifesto.md): Core HCI principles, KLM/GOMS ($H=0$), Doherty threshold (<100ms), pure icon badges, universal Omarchy theme color synchronization, and the Ergonomic Stability Rule.
- [**Workflow Keybindings & Ergonomic Reference Matrix**](architecture/workflow-keybindings-matrix.md): Complete multi-layer cheat-sheet and biomechanical audit of all global, Tmux, Zsh, and Lazygitrs shortcuts.

### 🐚 1. Shell & Navigation (`docs/shell/`)
- [**Smart Tab Completion & Matchmaker**](shell/completion.md): Context-aware `<Tab>`, auto-spacing on aliases (`gco<Tab>`), dual backends (`Ctrl+N` vs `Ctrl+F`), and the [`ftb.toml`](../matchmaker/.config/matchmaker/presets/ftb.toml) preset with on-demand preview (`Ctrl+P`).
- [**Zsh Vi Mode & Custom Surrounds**](shell/vi-mode.md): `zsh-vi-mode` integration, dynamic Starship prompt sync (`ZVM_MODE`), and unified surround text objects (`ib`, `ab`, `iq`, `aq`).

### 🪟 2. Tmux & Multiplexer (`docs/tmux/`)
- [**Popups Ergonomics, Biomechanics & Golden Ratio**](tmux/popups-ergonomics-and-golden-ratio.md): Golden Ratio ($\phi$) popup architecture, 60/40 column split, 1-touch Home Row navigation, and sub-100ms non-blocking HUDs.
- [**AI Agent Status in Status Bar**](tmux/ai-status-bar.md): Real-time per-pane AI agent state pills, animated spinners, color alerts, and `acpd` daemon options.
- [**Popup Isolation, Debounce & Event-Driven Architecture**](tmux/popup-isolation-and-debounce.md): Transparent frozen snapshot backdrops for rock-solid popups, 400ms idle debounce in ACPD, and 100% event-driven `status-interval 0`.
- [**Clipboard & Scrollback Capture**](tmux/clipboard-and-scrollback.md): Click-and-hold drag-to-copy to system clipboard, and `Prefix + C-e` scrollback buffer export to Neovim with full ANSI color formatting.
- [**Tmux Activity Monitoring**](TMUX_ACTIVITY.md): Activity alert and notification behavior.

### 🖥️ 3. Desktop, Terminal & Hardware (`docs/desktop/`)
- [**Hyprland Aesthetics vs. Performance Benchmark**](desktop/hyprland-aesthetics-and-performance.md): Deep-dive comparing Liquid Glass (`hyprglass`), Tokyo Night Solar Dawn (current), Catppuccin Pastel, Cyberpunk Neon, and OLED Zen with GPU/battery benchmarks on Apple Silicon M1 Pro.
- [**Dynamic Context-Aware Workspace Pills**](desktop/quickshell-workspace-pills.md): Reactive Quickshell workspace pills with real-time app icon rewriting and title-aware webapp detection (YouTube, GitHub, Google Photos, etc.).
- [**System, Displays & Hardware**](desktop/system-and-hardware.md): Kanshi Wayland display hotplug profiles, Ghostty terminal enhancements (CSI u escapes, epoll, custom shaders), and battery charge thresholds / CPU power profiles.
- [**Hyprland Animations Configuration**](desktop/hyprland-animations.md): Active animation rules, cubic Bézier curve presets, tree speeds, and override methods.
- [**Nerd Fonts Configuration**](NERD_FONTS.md): Font glyph setup and symbol rendering.
- [**Hyprland Crash Recovery**](HYPRLAND_CRASH_FIX.md): Crash triage and stability fixes.


### 🎨 4. Theme & Design System (`docs/theme/`)
- [**System Theming Architecture**](SYSTEM_THEME.md): The Omarchy theme rendering pipeline, `colors.toml` template generation, overrides, and live reload hooks.

### ⚡ 5. Utilities & Commands
- [**Utils & Command Reference**](UTILS.md): Quick reference for repository scripts (`stow-it`, `killport`, `dotadd`, `wtr`, `battery-threshold`, `perf-toggle`, Hyprland refresh helpers).

---

## 🧠 Smart Patterns & Architecture Roadmap
- [**Smart & Context-Aware Patterns Roadmap**](SMART_PATTERNS_ROADMAP.md): Comprehensive catalog of active event-driven intelligence and future roadmap (semantic breadcrumbs, workspace indicators, command alerts, scratchpads, and Neovim LSP sync).

## 🤖 AI Workflow & Agent Architecture
- [**Agent Worktree Manager & Multi-Agent Git Orchestrator (`GIT_WORKTREE_AGENTIC_WORKFLOW.md`)**](GIT_WORKTREE_AGENTIC_WORKFLOW.md): Complete guide to the AWT ecosystem, 4-layer architecture, conventional wizard, live previews, and automated lifecycle hooks.
- [**AWT Dotfiles Package Readme (`awt/README.md`)**](../awt/README.md): Dedicated package documentation, CLI command cheat sheet, and keybindings reference.
- [**TUI AI Workflows**](tui-ai-workflows.md): Interactive workflows and design patterns for agentic development.
- [**Autonomous Agent Examples**](autonomous-agent-examples.md) ([EN](autonomous-agent-examples-en.md)): Practical scenarios and agent configurations.
- [**AI Jail & Memory Architecture**](ai-jail-memory-guide-pt.md) ([EN](ai-jail-memory-guide-en.md)): Memory isolation and workspace jail documentation.
- [**AI Workflow Definitive Analysis**](ai-workflow-definitive-analysis-pt.md) ([EN](ai-workflow-definitive-analysis.md)): Deep dive into agent tool use and telemetry.
