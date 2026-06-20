---
name: acpd-tmux
description: "Control Tmux from inside your terminal using the ACPD daemon. Manage windows, split panes, and spawn other processes by sending JSON-RPC commands via curl to localhost:4040/rpc. Use this skill whenever you need to orchestrate parallel tasks, monitor servers, run tests in the background, or execute commands without blocking your main terminal."
---

# ACPD Tmux Controller Skill

You are an AI agent running inside a Tmux session that is connected to the ACPD (Agent Client Protocol Daemon). ACPD exposes a lightweight JSON-RPC 2.0 API on `http://127.0.0.1:4040/rpc` that allows you to control Tmux natively without relying on complex, raw `tmux` bash commands.

This means you can orchestrate your own workspace:
- Create new Tmux windows for separate subcontexts.
- Split panes to run servers or watch logs while continuing your work in the main pane.
- Create new background sessions for isolated environments.
- Clean up by killing panes, windows, or sessions you created.

## Core Concepts

You control Tmux by sending HTTP POST requests using `curl` to `http://127.0.0.1:4040/rpc`.
All requests must be valid JSON-RPC 2.0 payloads.

**Endpoints Available via RPC `method`:**
- `tmux.new_window`: Creates a new Tmux window (tab).
- `tmux.split_pane`: Splits the current or target pane.
- `tmux.new_session`: Creates a new detached background session.
- `tmux.kill_pane`: Kills a specific pane.
- `tmux.kill_window`: Kills a specific window.
- `tmux.kill_session`: Kills a specific session.

## Recipes

### 1. Split a Pane to Run a Server
When you need to start a development server but want to keep your current prompt free to answer the user:

```bash
curl -X POST http://127.0.0.1:4040/rpc \
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

### 2. Create a New Window for Monitoring or Tests
When you need to run a test suite or monitor logs that require a full screen:

```bash
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.new_window",
    "params": {
      "name": "Monitor",
      "command": "htop"
    },
    "id": 1
  }'
```

### 3. Create an Isolated Background Session
To start a long-running service (like a database or docker-compose) in a detached session so it doesn't clutter the user's workspace:

```bash
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.new_session",
    "params": {
      "name": "Database",
      "directory": "./db",
      "command": "docker-compose up"
    },
    "id": 1
  }'
```

### 4. Kill a Pane or Window
To destroy a target pane or window (you must provide the exact target name or ID, like `%1` or `@1`):

```bash
curl -X POST http://127.0.0.1:4040/rpc \
  -H "Content-Type: application/json" \
  -d '{
    "jsonrpc": "2.0",
    "method": "tmux.kill_pane",
    "params": {
      "target": "%1"
    },
    "id": 1
  }'
```

## Important Notes
- The daemon always runs on `http://127.0.0.1:4040/rpc`.
- The `command` parameter is executed natively by Tmux inside the new pane/window. You do not need to wrap it in bash quotes.
- Always prefer using `curl` to interact with ACPD over running raw `tmux split-window` commands, as ACPD may handle internal synchronization and theming.
- If you need to monitor the output of a background process, consider redirecting its output to a file and reading that file in your main pane.
