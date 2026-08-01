---
name: acpd-tmux
description: "Control Tmux from inside your terminal using the ACPD daemon. Manage windows, split panes, select windows/panes, display status messages, ring bells, apply layouts, capture outputs, and inject keystrokes via JSON-RPC POST requests to localhost:4040/rpc. Use this skill whenever you need to orchestrate parallel tasks, monitor servers, run tests in background, or switch focus across panes/windows."
---

# ACPD Tmux Controller Skill

You are an AI agent running inside a Tmux session connected to the ACPD (Agent Client Protocol Daemon). ACPD exposes a lightweight JSON-RPC 2.0 API on `http://127.0.0.1:4040/rpc` that allows you to control Tmux natively without relying on complex, raw `tmux` bash commands.

This means you can orchestrate your workspace:
- Create and switch focus between Tmux windows and panes.
- Display status messages and trigger visual/audible bells.
- Apply preset pane layouts (`tiled`, `even-horizontal`, etc.).
- Split panes to run servers or watch logs while continuing work in the main pane.
- Capture terminal scrollback buffers and send keystrokes/commands.
- Clean up by killing panes, windows, or sessions.

## Core Concepts

You control Tmux by sending HTTP POST requests using `curl` to `http://127.0.0.1:4040/rpc`.
All requests must be valid JSON-RPC 2.0 payloads with the Bearer token header from `/run/user/$UID/acpd/token`.

**Endpoints Available via RPC `method`:**
- `tmux.new_window`: Creates a new Tmux window (tab).
- `tmux.select_window`: Changes focus to a specific window (`target`: `:0`, `@1`, etc.).
- `tmux.select_pane`: Changes focus to a specific pane (`target`: `%1`, etc.).
- `tmux.display_message`: Displays a status line message on Tmux (`message`, optional `target`).
- `tmux.ring_bell`: Triggers a visual/audible bell alert on a pane (`target`: `%0`).
- `tmux.select_layout`: Applies a layout preset to a window/pane (`layout`: `tiled`, `even-horizontal`, etc.).
- `tmux.split_pane`: Splits the current or target pane.
- `tmux.capture_pane`: Reads scrollback text from a pane.
- `tmux.send_keys`: Injects keystrokes or commands into a target pane.
- `tmux.list_windows`: Lists all windows in the current or target session.
- `tmux.list_panes`: Lists active panes with dimensions, paths, and active state.
- `tmux.list_sessions`: Lists active tmux sessions.
- `tmux.new_session`: Creates a new detached background session.
- `tmux.kill_pane`: Kills a specific pane.
- `tmux.kill_window`: Kills a specific window.
- `tmux.kill_session`: Kills a specific session.

## Recipes

### 1. Select a Window or Pane
To bring focus to a specific window or pane (e.g. window index `:0` or pane `%6`):

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.select_window",
    "params": {
      "target": ":0"
    },
    "id": 1
  }'
```

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.select_pane",
    "params": {
      "target": "%6"
    },
    "id": 1
  }'
```

### 2. Display Status Message on Tmux
To display a temporary banner message on the Tmux status bar:

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.display_message",
    "params": {
      "message": "Background task finished successfully!"
    },
    "id": 1
  }'
```

### 3. Ring Pane Bell (Alert)
To trigger a bell alert on a target pane:

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.ring_bell",
    "params": {
      "target": "%6"
    },
    "id": 1
  }'
```

### 4. Apply Pane Layout Preset
To reorganize panes into a preset layout (e.g. `tiled`, `even-horizontal`, `even-vertical`, `main-horizontal`):

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.select_layout",
    "params": {
      "target": "%6",
      "layout": "tiled"
    },
    "id": 1
  }'
```

### 5. Split a Pane to Run a Server
When starting a dev server while keeping prompt free:

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.split_pane",
    "params": {
      "vertical": true,
      "command": "npm run dev"
    },
    "id": 1
  }'
```

### 6. Send Keystrokes or Commands
To inject commands into a target pane:

```bash
TOKEN=$(cat /run/user/$UID/acpd/token 2>/dev/null || cat /run/user/1001/acpd/token)
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Authorization: Bearer $TOKEN" \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.send_keys",
    "params": {
      "target": "%6",
      "keys": ["cargo test", "Enter"]
    },
    "id": 1
  }'
```

## Important Notes
- The daemon always runs on `http://127.0.0.1:4040/rpc`.
- Local requests require the Bearer token stored in `/run/user/$UID/acpd/token`.
- Always prefer using `curl` to interact with ACPD over raw `tmux` shell calls for consistent IPC authorization and state synchronization.
