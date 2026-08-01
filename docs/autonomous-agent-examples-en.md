# Autonomous AI Agent & Terminal Multiplexer Integration Guide

> **Scope**: Practical guide and real-world demonstrations of how `acpd` JSON-RPC methods (`tmux.list_sessions`, `tmux.list_windows`, `tmux.list_panes`, `tmux.capture_pane`, `tmux.send_keys`, `agentState/list`) empower AI coding agents to interact with terminal multiplexers as full-stack pair programming partners.
> **File**: [`/home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples-en.md`](file:///home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples-en.md)
> **Portuguese Version**: [`/home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples.md`](file:///home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples.md)

---

## 1. Architectural Overview & Comparison with `herdr`

### How `herdr` does it:
- `herdr` implements a native JSON-RPC Unix socket (`herdr.sock`) built directly inside its own Rust-based terminal emulator/multiplexer.
- It allows agents to list panes, send keystrokes, and capture output buffers from panes created inside `herdr`.

### Why the `acpd` + `tmux` architecture is superior:
1. **Full Ecosystem Preservation**: `herdr` requires abandoning `tmux` completely. With `acpd`, the same JSON-RPC control plane is layered on top of native `tmux`, retaining your entire toolset (`vim-tmux-navigator`, `tmux-resurrect`, `tmux-thumbs`, `sesh`, Matchmaker `mm` pickers, and Waybar widgets).
2. **Git Review Loop Integration**: `herdr` lacks a bi-directional code review annotation server (`lazygitrs`). The `acpd` stack integrates terminal-wide navigation with inline Git diff reviews.

---

## 2. Core Advantages of AI Agents with Terminal Multiplexers

1. **Zero Context Switching**: The developer never needs to leave the editor, manually select terminal text, or copy-paste compiler stack traces into the AI chat window.
2. **Non-Blocking Background Execution**: Heavy or long-running tasks (compilations, test suites, benchmark runs) execute in separate background windows/panes without blocking the user's primary prompt.
3. **Holistic System Perception**: The AI agent sees beyond static code files on disk—it observes running processes, live database logs, dev server outputs, and system metrics.
4. **End-to-End Autonomous Loop**: Enables a complete feedback loop: **Detect Error ➔ Edit File ➔ Recompile via Terminal ➔ Verify Test Output ➔ Notify User**.

---

## 3. Practical Real-World Use Cases & Demonstrations

### 🟢 Example 1: Full-Stack Error Diagnosis (Backend + Frontend + DB Logs)

#### 🎬 Scenario:
You are testing a web application frontend and receive a `500 Internal Server Error` on checkout.

#### 🤖 AI Action via RPC:
1. User prompt: *"The checkout button gave a 500 error. Find the root cause and fix it."*
2. AI calls `tmux.list_sessions` ➔ Discovers active sessions `webapp` (frontend), `api-server` (Rust backend), and `postgres` (database).
3. AI calls `tmux.list_windows` on `api-server` ➔ Finds window `server-logs`.
4. AI calls `tmux.capture_pane` on `server-logs` ➔ Reads live log output:
   ```text
   [ERROR] 2026-07-22 20:05:12 - Failed to execute query: connection pool exhausted (port 5432)
   ```
5. AI updates `max_connections` in `src/config.rs` and notifies the user with the exact diagnostic root cause.

---

### 🟢 Example 2: Conflict-Free Multi-Agent Orchestration (`agentState/list`)

#### 🎬 Scenario:
Two parallel AI agents are active in separate windows:
- **Agent A (OpenCode)** in window `ai-refactor`: Refactoring `auth.rs`.
- **Agent B (Antigravity)** in window `ai-docs`: Writing API documentation and integration tests.

#### 🤖 AI Action via RPC:
1. Agent B needs to run integration tests but must avoid file conflicts while Agent A is modifying code.
2. Agent B queries `agentState/list` via `acpd`:
   ```json
   {
     "jsonrpc": "2.0",
     "result": {
       "%1 (ai-refactor)": { "state": "working", "last_update": 1753224000 },
       "%4 (ai-docs)": { "state": "idle", "last_update": 1753224050 }
     },
     "id": 1
   }
   ```
3. Agent B detects `%1 (ai-refactor)` is `"working"` and waits for it to become `"idle"` before triggering test suites.

---

### 🟢 Example 3: Autonomous Background Test Execution

#### 🎬 Scenario:
You accepted a code refactoring suggestion.

#### 🤖 AI Action via RPC:
1. Upon writing code to disk, AI calls `tmux.list_windows` to check for an existing test runner window.
2. If none exists, AI calls `tmux.new_window` with `"name": "test-runner"`.
3. AI calls `tmux.send_keys` with `["cargo test\n"]` or `["npm test\n"]`.
4. AI polls `tmux.capture_pane` until execution completes and verifies zero test failures.

---

### 🟢 Example 4: "Shift Handoff" Workspace Report

#### 🎬 Scenario:
You left 3 background tasks running and went for a break. Upon returning, you want a full status report.

#### 🤖 AI Action via RPC:
User prompt in floating window (`Alt+o`): *"Workspace summary."*

1. AI queries batch RPC: `tmux.list_sessions` + `tmux.list_windows` + `agentState/list`.
2. AI outputs a structured workspace summary:
   ```text
   📊 WORKSPACE REPORT:
   ─────────────────────────────────────────────────────────────
   • Session 'dotfiles':
     - acpd daemon: 6/6 unit tests ok (127.0.0.1:4040).
   • Session 'webapp':
     - Window 'ai-refactor': Completed (Idle 5m ago).
     - Window 'ai-docs': Awaiting user permission.
     - Window 'vite': Dev server active at http://localhost:5173.
   ```

---

### 🟢 Example 5: Inter-Window Remote Key Injection & Interactive Execution

#### 🎬 Scenario:
You want the agent in window A to trigger an calculation, command, or prompt in window B.

#### 🤖 AI Action via RPC:
1. AI calls `tmux.send_keys` with target `@4` and keys `["quanto e 2+2?", "Enter"]`.
2. AI calls `tmux.capture_pane` on target `@4` to capture the output:
   ```text
   > quanto e 2+2?

     2 + 2 = 4
   ```

---

### 🟢 Example 6: Live Performance & Metric Monitoring

#### 🎬 Scenario:
You are running load benchmarks and want to monitor resource spikes.

#### 🤖 AI Action via RPC:
1. User prompt: *"Monitor API memory and CPU usage during load testing."*
2. AI locates `btop`/`htop` pane via `tmux.list_windows`.
3. AI polls `tmux.capture_pane` every 5 seconds to analyze CPU/RAM utilization trends and flags memory leaks.

---

## 4. `acpd` JSON-RPC 2.0 API Method Reference

| Method | Type | Parameters | Use Case |
|---|---|---|---|
| `agentState/update` | Mutation | `{pane_id, state, timestamp?}` | Notify daemon that AI started working or turned idle |
| `agentState/list` | Query | *None* | Multi-agent state inspection to prevent file conflicts |
| `tmux.list_sessions` | Inspection | *None* | List all active tmux sessions across system |
| `tmux.list_windows` | Inspection | `{target?}` | Discover test runners, log streams, dev servers, or editors |
| `tmux.list_panes` | Inspection | `{target?, all?}` | List active pane dimensions, CWDs, and commands |
| `tmux.capture_pane` | Inspection | `{target?, start_line?, end_line?, escape_sequences?}` | Read terminal scrollback buffer, compiler errors, or test outputs |
| `tmux.send_keys` | Control | `{target?, keys: [], literal?}` | Inject commands (`cargo test`, `npm run build`) or keystrokes |
| `tmux.select_window` | Navigation | `{target}` | Switch active focus to a specific window (`:0`, `@1`) |
| `tmux.select_pane` | Navigation | `{target}` | Switch active focus to a specific pane (`%6`) |
| `tmux.display_message` | Notification | `{message, target?}` | Display status bar message on Tmux status line |
| `tmux.ring_bell` | Notification | `{target?}` | Trigger visual/audible bell alert on a pane |
| `tmux.select_layout` | Layout | `{layout, target?}` | Apply pane layout preset (`tiled`, `even-horizontal`) |
| `tmux.split_pane` | Control | `{command?, target_pane?, vertical?}` | Create side-by-side terminal splits for dev tasks |
| `tmux.new_window` | Control | `{name?, target?, command?}` | Create dedicated background tabs for long-running processes |
| `tmux.kill_pane/window/session` | Teardown | `{target}` | Clean up completed background windows/panes |

---
*Document saved at: [`/home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples-en.md`](file:///home/fecavmi/.dotfiles/main/docs/autonomous-agent-examples-en.md)*
