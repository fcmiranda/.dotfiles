# Smart & Context-Aware Patterns: Architecture & Roadmap

This document catalogs the **intelligent, context-aware, and event-driven patterns** designed for this Arch Linux + Hyprland + Omarchy + Quickshell + Tmux + Neovim ecosystem. It highlights both **implemented features** and the **future roadmap** for upcoming enhancements.

---

## 🎯 Design Philosophy

The core principle across this dotfiles setup is **Zero Polling, Maximum Context**:
1. **Event-Driven Reactivity**: Components update exclusively in response to compositor, multiplexer, or filesystem events (via IPC, Wayland protocols, inotify, and hooks) without background polling loops or heavy cron timers.
2. **Semantic Awareness**: Tools don't just display process names or numbers; they inspect real-time context (active browser tab, git branch, audio stream, LSP diagnostics, AI agent lifecycle).
3. **Seamless Micro-Interactions**: UI elements morph, highlight, and emit discrete ambient cues (sound, pills, subtle glow) matching user focus.

---

## 🟢 Implemented Features (Current Architecture)

```
┌─────────────────────────────────────────────────────────────────────────────┐
│                            ACTIVE SYSTEM PATTERNS                           │
├───────────────────────────────┬─────────────────────────────────────────────┤
│ 💊 Workspace Pills            │ Real-time title-aware app rewriting in bar │
│ 🤖 Tmux AI Agent Status       │ Per-pane lifecycle pills via ACPD daemon    │
│ 🐚 Smart Tab Completion       │ Context-aware completion & Matchmaker TUI   │
│ 🎨 Universal Dynamic Theming  │ Live palette sync from colors.toml pipeline │
│ 🖥️ Kanshi Display Profiles    │ Event-driven multi-monitor hotplug rules    │
│ ⌨️ Zsh Vi-Mode & Prompt Sync  │ Modal editing with live Starship prompt sync│
└───────────────────────────────┴─────────────────────────────────────────────┘
```

### 1. Dynamic Context-Aware Workspace Pills
* **Location**: [`omarchy/.config/omarchy/plugins/fecavmi.workspaces/Workspaces.qml`](../omarchy/.config/omarchy/plugins/fecavmi.workspaces/Workspaces.qml)
* **Doc**: [Dynamic Workspace Pills Guide](desktop/quickshell-workspace-pills.md)
* **How it works**: Uses Quickshell reactive property bindings over Hyprland IPC. When navigating tabs in Chrome/Firefox, it matches web signatures (`YouTube` ──► `󰗃`, `GitHub` ──► `󰊤`, `Google Photos` ──► `󰋩`, `ChatGPT` ──► `󰚩`, `WhatsApp` ──► `󰖣`) and application classes (`ghostty` ──► ``, `antigravity-ide` ──► `󰲇`, `spotify` ──► ``) inside adaptive capsule pills.

### 2. Tmux AI Agent Status & Event-Driven Popups
* **Location**: [`tmux/.config/tmux/`](../tmux/.config/tmux/), [`acpd/`](../acpd/)
* **Doc**: [Tmux AI Status Bar](tmux/ai-status-bar.md) & [Popup Isolation & Debounce](tmux/popup-isolation-and-debounce.md)
* **How it works**: The ACPD daemon intercepts agent lifecycle hooks (Claude, Antigravity, OpenCode). Status updates are broadcast with a 400ms debounce to tmux status pills (`status-interval 0`), rendering spinners (`󱚤 󰑮 Running...`), error alerts, and bell popups.

### 3. Smart Tab Completion & On-Demand Preview (`_smart_tab`)
* **Location**: [`zsh/.zsh/utils/binds.zsh`](../zsh/.zsh/utils/binds.zsh), [`matchmaker/.config/matchmaker/presets/ftb.toml`](../matchmaker/.config/matchmaker/presets/ftb.toml)
* **Doc**: [Shell Completion & Matchmaker](shell/completion.md)
* **How it works**: Analyzes cursor context on `<Tab>`: auto-spaces single-word aliases (e.g. `gco<Tab>` ──► `gco <Tab>`), opens fast native fzf menus for short paths, or triggers rich Matchmaker TUI pickers (`mm-ftb`) with `Ctrl+P` syntax-highlighted previews for files and directories.

### 4. Zsh Vi-Mode & Live Prompt Mode Sync
* **Location**: [`zsh/.zshrc`](../zsh/.zshrc), [`starship/.config/starship.toml`](../starship/.config/starship.toml)
* **Doc**: [Zsh Vi Mode Guide](shell/vi-mode.md)
* **How it works**: Hooks into `zsh-vi-mode` state changes, immediately exporting `ZVM_MODE` and triggering redraws so the Starship prompt pill transitions dynamically between INSERT (green), NORMAL (blue), and VISUAL (amber) modes.

### 5. Universal Theming Engine Pipeline
* **Location**: [`omarchy/.config/omarchy/theme-overrides/`](../omarchy/.config/omarchy/theme-overrides/), [`docs/SYSTEM_THEME.md`](SYSTEM_THEME.md)
* **How it works**: Evaluates a single `colors.toml` source of truth, compiling templates into Hyprland Lua colors, Quickshell `Color.qml` surface tokens, Ghostty themes, Starship palettes, and Neovim color schemes on the fly.

---

## 🚀 Future Roadmap & Backlog (To Be Implemented)

The following concepts represent high-leverage ideas scheduled for future implementation:

---

### 1. Top Bar & Quickshell Enhancements

#### 🔹 A. Semantic Breadcrumbs in `ActiveWindow.qml`
* **Concept**: Replace the generic window title with rich project breadcrumbs when focused on development tools.
* **Preview**:
  ```
  󰲇 Antigravity • [main*] .dotfiles • Workspaces.qml
   Ghostty • [feature/auth] api-server • cargo test (running)
  ```
* **Implementation Plan**:
  - Read window title exports from Neovim and Zsh hooks.
  - Parse active Git repository, branch, and relative file path.
  - Display interactive clickable breadcrumbs leading directly to the directory or file.

#### 🔹 B. Smart Per-Workspace Indicators (Audio, Builds & Bells)
* **Concept**: Add micro-badges to workspace pills when background activities occur:
  - **Audio Active (`󰕾`)**: Window in that workspace is streaming audio via Pipewire.
  - **Build / Task Complete (`󰄬` / `󰅚`)**: A terminal command or compilation finished in that workspace.
  - **Unread Notification (`󰂚`)**: Chat or communication app has unread activity.
* **Implementation Plan**:
  - Listen to Pipewire audio stream mappings (`node.name` / `application.process.id`).
  - Wire DBus desktop notification urgency hints into `HyprlandWorkspace` model.

#### 🔹 C. Adaptive Media Island Capsule
* **Concept**: When media is playing (Spotify, YouTube, MPV), the center bar transforms into an animated media capsule with song title scrolling, track duration ring, and mini spectrum visualizer.
* **Implementation Plan**:
  - Bind to `Quickshell.Services.Mpris` metadata (`playbackStatus`, `trackArtist`, `trackTitle`).
  - Add smooth slide-in / expand animation with mouseover playback controls (Play/Pause, Skip, Volume wheel).

---

### 2. Hyprland & Compositor Automation

#### 🔹 D. Declarative Workspace Auto-Routing Rules
* **Concept**: Automatically dispatch newly opened windows to structured semantic workspaces:
  - `Workspaces 1–3`: Editors, Terminals, and AI Workflows.
  - `Workspace 4`: Browsers and Documentation.
  - `Workspace 5`: Communication (Discord, Telegram, Slack).
  - `Workspace 0`: Background System & Audio Tools (Spotify, Wiremix, Bluetui, Btop).
* **Implementation Plan**:
  - Add declarative `windowrulev2` directives in `hypr/.config/hypr/looknfeel.lua` / `hyprland.lua`.
  - Include silent workspace assignments (`workspace 0 silent, class:(spotify)`).

#### 🔹 E. Slide-Down TUI Scratchpads with Auto-Dismiss
* **Concept**: Dedicated hotkeys (`SUPER + S` for Spotify/Music, `SUPER + G` for Lazygit, `SUPER + M` for Monitor/Btop) spawn floating slide-down windows that smoothly retract when focus is lost.
* **Implementation Plan**:
  - Leverage Hyprland Special Workspaces (`special:scratchpad`, `special:monitor`).
  - Define custom cubic Bézier transitions in `hypr/.config/hypr/animations.lua`.

---

### 3. Terminal, Shell & Developer Flow

#### 🔹 F. Long-Running Command Ambient Alerts (`preexec` / `precmd`)
* **Concept**: If any shell command runs for longer than 10 seconds (e.g. `cargo build`, `npm install`, `stow.sh`, `make`), Zsh emits a discrete ambient audio chime (via `ai-sound-notify`) and a desktop notification when it finishes if the terminal is in the background.
* **Preview**:
  ```
  🔔 Build Finished (took 28.4s) — Exit code: 0
  ```
* **Implementation Plan**:
  - Record epoch timestamp in Zsh `preexec()`.
  - Compare timestamp in `precmd()`; if `delta > 10` and window is not active, trigger `notify-send` and audio cue.

#### 🔹 G. Matchmaker Git Worktree & Session Switcher (`mm-wt`)
* **Concept**: A dedicated Matchmaker preset picker for Git worktrees and projects:
  - Lists bare repo worktrees with branch names, uncommitted change counts, and commit divergence (`ahead/behind`).
  - Interactive preview showing `git status --short` and recent commits.
  - Keybinding actions: `<Enter>` switch tmux session, `Ctrl+V` open in Neovim, `Ctrl+D` diff view.
* **Implementation Plan**:
  - Create `matchmaker/.config/matchmaker/presets/wt.toml`.
  - Script helper `utils/.local/bin/mm-wt` querying `git worktree list --porcelain`.

---

### 4. Neovim & Code Intelligence

#### 🔹 H. Real-Time LSP & Diagnostic Title Synchronization
* **Concept**: Neovim dynamically pushes file name, buffer modified status, and LSP diagnostic counts to the Hyprland window title:
  - Clean: `󍯯 nvim: Workspaces.qml [LSP: ✓ OK]`
  - Errors: `󍯯 nvim: bindings.lua [LSP: ✖ 2 • ⚠ 1]`
* **Implementation Plan**:
  - Add Neovim `DiagnosticChanged` and `BufEnter` autocommands setting `vim.opt.titlestring`.
  - Quickshell top bar instantly reflects diagnostics in the active window widget.

---

## 📌 Summary Reference Table

| Feature / Pattern | Subsystem | Status | Key Advantage |
| :--- | :--- | :---: | :--- |
| **Workspace App Icon Pills** | Quickshell / Hyprland | 🟢 Live | Real-time semantic webapp & app icon identification |
| **Tmux AI Status Bar** | Tmux / ACPD | 🟢 Live | Live agent lifecycle monitoring with debounced events |
| **Smart Tab & MM Preview** | Zsh / Matchmaker | 🟢 Live | Zero-friction contextual completion and instant preview |
| **Starship Modal Prompt Sync** | Zsh / Starship | 🟢 Live | Dynamic vi-mode visual indicator in terminal prompt |
| **Universal Theme Pipeline** | Omarchy / Multi | 🟢 Live | Single-point palette management across entire desktop |
| **Semantic Breadcrumbs** | Quickshell / ActiveWindow | 🚀 Roadmap | Project, git branch, and file context in top bar |
| **Workspace Activity Badges** | Quickshell / Pipewire | 🚀 Roadmap | Audio stream and background task indicators on pills |
| **Adaptive Media Island** | Quickshell / MPRIS | 🚀 Roadmap | Dynamic media playback capsule in center bar |
| **Semantic Workspace Routing**| Hyprland | 🚀 Roadmap | Automated window organization by application intent |
| **Slide-Down Scratchpads** | Hyprland / TUIs | 🚀 Roadmap | Fast dropdown utility access with auto-dismiss |
| **Long-Running Command Cues** | Zsh / Sounds | 🚀 Roadmap | Ambient notification when background tasks complete |
| **Matchmaker Worktree Picker** | Matchmaker / Git | 🚀 Roadmap | Lightning-fast worktree jumping with live git stats |
| **Neovim Live LSP Title Sync** | Neovim / Hyprland | 🚀 Roadmap | Instant code health feedback visible from top bar |
