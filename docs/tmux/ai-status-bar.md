# Per-Pane AI Agent Status in Tmux Status Bar

The tmux status bar displays real-time, dynamic state for AI agents (Antigravity / OpenCode / Copilot) running in each pane.
State is pushed into tmux options `@ai_agent_state`, `@ai_agent_state_color`, `@ai_agent_state_raw`, `@copilot_state`, and `@ai_agent_bell` by the centralized `acpd` daemon (`127.0.0.1:4040`) and client hooks (`tmux-hook.mjs` / `hooker.ts`).

---

## 1. Dynamic Pill Layout & Color States (`window-status-current-format`)

The active window tab is rendered as a rounded pill (`` ... ``) whose background color changes dynamically based on the AI agent state (`@ai_agent_state_color`):

- 🟡 **Yellow (`#f9e2af` / `@COPY_COLOR`)**: Agent is actively working / executing tools (`busy` / `working`) with an animated spinner (`⠋`).
- 🟣 **Purple (`#cba6f7` / `@PREFIX_COLOR`)**: Agent has asked a question and is awaiting user input (`question` / `awaiting_input`) with the `󱜻` icon.
- 🔴 **Red (`#f38ba8`)**: Agent requires permission or encountered an execution error (`permission` / `error`) with the `󱅭` or `󰨄` icon.
- 🟢 **Cyan/Teal (`#94e2d5` / `@CURRENT_COLOR`)**: Agent is idle or normal terminal window without an active AI agent session.

Inside the active filled pill, the window title `#W` and state icon `@ai_agent_state` are forced to high-contrast dark text (`fg=#{@SESSION_ACTIVE_FG}`) for clean legibility on top of filled backgrounds.

---

## 2. Background Tab Notifications (`window-status-format`)

For inactive background tabs, `@ai_agent_state` is rendered in `#[fg=#{@ai_agent_state_color}]`. Status icons light up in their respective state colors (Yellow, Purple, Red) in the background so you can monitor agent progress and input requests across windows at a glance.

---

## 3. Orthogonal Tmux Options Pushed by `acpd`

- `@ai_agent_state`: Pure icon or animated spinner frame string without embedded ANSI color tags (e.g. `⠋`, `󱜻`, `󱅭`, `󰨄`).
- `@ai_agent_state_color`: Hex color string configured in `config.toml` (e.g. `#f9e2af`, `#cba6f7`, `#f38ba8`, `#94e2d5`).
- `@ai_agent_state_raw`: Raw state identifier string (`busy`, `working`, `question`, `awaiting_input`, `permission`, `error`, `idle`, `closed`).

See [`tmux/.config/tmux/tmux.conf`](../../tmux/.config/tmux/tmux.conf) and [`acpd/.config/acpd/config.toml`](../../acpd/.config/acpd/config.toml) for exact option wiring and theme definitions.
