# Tmux Popups, Golden Ratio Geometry & Visual Semiotics

## 1. Spatial Geometry: The Golden Ratio ($\phi \approx 1.618$)

Popups in this environment are engineered around human foveal vision ($2^\circ - 5^\circ$ central cone) and the Golden Ratio ($\phi = 1.618$):

```
+-----------------------------------------------------------------------+
|  Tmux Terminal Window (100% × 100%)                                   |
|                                                                       |
|         ╭── 󱂬 ───────────────────────────────────────────────╮         |
|         │  POPUP MODAL (75% width × 60% height)              │         |
|         │                                                    │         |
|         │  ┌─────────────────┬────────────────────────────┐  │         |
|         │  │ Candidate List  │ Preview Pane               │  │         |
|         │  │ (40% width)     │ (60% width)                │  │         |
|         │  │                 │                            │  │         |
|         │  └─────────────────┴────────────────────────────┘  │         |
|         ╰────────────────────────────────────────────────────╯         |
|                                                                       |
+-----------------------------------------------------------------------+
```

### Standard Popup Dimensions
- **Ephemeral Popups (Pickers, Navigation):** `75% × 60%` (Centered). Dismissible via single `Esc` tap.
- **Persistent Popups (Lazygitrs, Code Review):** `90% × 88%` (High visual real estate).
- **Reactive Popups (Agent Approvals, Alerts):** `80% × 75%`.

---

## 2. Dynamic Visual Semiotics (Omarchy Theme Color Sync)

Border colors and titles dynamically synchronize with the current Omarchy system theme (`~/.local/state/omarchy/current/theme/colors.toml`):

### 1. Ephemeral Layer (Transit & Selection < 5s)
- **Border Badge:** `╭── 󱂬 ──╮`
- **Semantic Color:** Mauve / Magenta (`#cba6f7` or dynamic)
- **Target Components:** Matchmaker jump picker, Sesh session switcher, Window switcher.
- **Exit Gesture:** `Esc` or `q` (0ms destruction).

### 2. Persistent Layer (High-Density Workspaces)
- **Border Badge:** `╭── 󰊢 ──╮`
- **Semantic Color:** Git Orange / Peach (`#fab387` or dynamic)
- **Target Components:** Lazygitrs popup, floating Neovim sandbox.
- **Exit Gesture:** `Esc` in Files view or `q`.

### 3. Reactive Layer (AI Agent Attention & Intervention)
- **Border Badge:** `╭── 󰮯 ──╮`
- **Semantic Color:** Alert Yellow (`#f9e2af` or dynamic)
- **Target Components:** AI agent approval prompts, interactive questionnaires.
- **Cycle Gesture:** `prefix + i` or `Esc`.

---

## 3. High-Fidelity ASCII / Unicode Wireframe Specification

```text
╭── 󱂬  Matchmaker Jump ────────────────────────────────────────────────────────╮
│ > git                                                              8 matches │
│──────────────────────────────────────────────────────────────────────────────│
│ 󱅤  main/                                    │ commit bb603d9 (HEAD)          │
│ 󱅤  feat-eval/                                │ Author: felipe                 │
│ 󱅤  pr-42/                                   │ Date:   Thu Sep 17 18:56:06    │
│    .bare/                                   │                                │
│    .git/                                    │ feat(stow): migrate agent      │
│    scripts/                                 │ skills into dedicated stow     │
│    docs/                                    │ package                        │
│                                             │                                │
│                                             │ - Move awt-orchestrator skill  │
│                                             │ - Symlink .agents/skills       │
╰── [l/Enter] Open  [h] Parent  [u] Undo  [f] Cycle Scope  [Esc] Close ────────╯
```

---

## 4. Auditory Telemetry via `acpd`

Visual popups can be accompanied or replaced by non-blocking auditory cues managed by the `acpd` daemon:
- PipeWire low-latency sound cues (<10ms).
- Signals completion of long builds, worktree merges, or agent task completions without stealing terminal focus.
