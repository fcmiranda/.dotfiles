# Definitive Guide: Setting Up and Using AI-Jail and AI-Memory

This guide provides a step-by-step walkthrough of the initial setup, systemd background automation, dotfiles tracking (`stow`), and daily workflow for **ai-jail** and **ai-memory**.

---

## 1. Tool Overview

* **ai-jail**: Runs AI coding agents inside an isolated Linux sandbox (`bubblewrap` + `Landlock`). Prevents agents from reading or modifying files outside your project workspace or accessing sensitive system files.
* **ai-memory**: An MCP server and local SQLite database that records sessions, observations, context, and project wiki knowledge across AI coding agents.

---

## 2. Initial Setup Step-by-Step (One-Time Execution)

### Step 1: Initialize ai-memory Structure
Create directory layouts and default configuration file at `~/.local/share/ai-memory/config.toml`:
```bash
ai-memory init
```

### Step 2: Configure Systemd User Background Service
Create the service unit file at `~/.config/systemd/user/ai-memory.service`:

```ini
[Unit]
Description=ai-memory background daemon
After=network.target

[Service]
ExecStart=/home/fecavmi/.cargo/bin/ai-memory serve --transport http
Restart=on-failure
RestartSec=5s

[Install]
WantedBy=default.target
```

Reload daemons and enable the service to start automatically on login:
```bash
systemctl --user daemon-reload
systemctl --user enable --now ai-memory
```

Verify service health:
```bash
systemctl --user status ai-memory
ai-memory status
```

---

### Step 3: Track Configurations in Dotfiles (`stow-it`)
Adopt the systemd service file and the ai-memory configuration file into the `ai-memory` dotfiles package:

```bash
~/.dotfiles/main/utils/.local/bin/stow-it ~/.config/systemd/user/ai-memory.service ai-memory
~/.dotfiles/main/utils/.local/bin/stow-it ~/.local/share/ai-memory/config.toml ai-memory
```

Verify stowed packages:
```bash
./stow.sh -s
```

---

### Step 4: Register MCP Servers in Agents
Register ai-memory as an MCP server in your AI clients:

```bash
# For OpenCode
ai-memory install-mcp --client open-code --apply

# For Codex CLI
ai-memory install-mcp --client codex --apply
```

---

### Step 5: Install Lifecycle Hooks
Enable ai-memory to automatically capture session start, end, and context:

```bash
# For OpenCode
ai-memory install-hooks --agent opencode --apply

# For Codex
ai-memory install-hooks --agent codex --apply
```

---

### Step 6: Install Instructions and Skills in Project
Inside your project repository, inject ai-memory instructions and skills into `AGENTS.md` or `CLAUDE.md`:

```bash
ai-memory install-instructions
```

---

## 3. Daily Workflow (Correct Execution Order)

With the systemd service active, the `ai-memory` daemon is running persistently in the background.

### Option A: Run Agent with Sandbox + Memory (Recommended)
To launch an OpenCode session with both ai-jail and ai-memory:

```bash
ai-jail ai-memory run opencode --yolo
```

> **Note:** On your first run in a project, if ai-memory displays `Select [1]:`, type **`0`** and press **Enter** to start a new session.

To create a new named workstream directly without interactive prompts:
```bash
ai-jail ai-memory run --new my_session opencode --yolo
```

---

### Option B: Run Agent Directly in Sandbox (`ai-jail opencode --yolo`)
In direct execution, the agent **already has full access to all project history and knowledge** via the `ai-memory` plugin/MCP:

```bash
# OpenCode
ai-jail opencode --yolo

# Antigravity CLI (agy)
ai-jail agy

# Codex CLI
ai-jail codex --yolo
```

#### 🔍 What the Agent KNOWS in Direct Execution:
* ✅ **Project Rules & Knowledge:** Reads repository guidelines (`AGENTS.md` / `ai-memory` wiki).
* ✅ **History Search via MCP:** Freely queries the memory database by calling `memory_search` or `memory_read_page`.

#### 💡 The Only Difference in Managed Workstream (`ai-memory run`):
* **Direct Execution:** Starts with a clean prompt. The agent knows project rules/history, but **does not receive an automatic boot summary (*Handoff*)** saying: *"You stopped yesterday at file X on line Y"*.
* **Managed Workstream (`ai-memory run`):** Injects an automatic state transition summary (*Handoff*) into the boot prompt and enables switching between different AI agents (e.g. OpenCode -> Claude -> Codex) while sharing the exact same workstream.


---

## 4. How to Verify Sandbox Activation

There are 5 easy ways to confirm your AI agent is actively executing inside **ai-jail**:

1. **Verify System Hostname:**
   Running `hostname` inside the agent shell returns **`ai-sandbox`** instead of your machine's real hostname.
2. **Terminal Startup Banner:**
   Upon launch, ai-jail displays:
   ```text
   ▸ Jail Active: /path/to/project
   ▸ Landlock: fully enforced
   ```
3. **Sensitive File Access Restriction (Landlock Isolation):**
   Attempting to access restricted directories like `ls -la ~/.ssh` will be denied (`Permission denied` or empty/masked).
4. **Prompt `(jail)` Prefix:**
   The jailed shell environment sets `PS1` prefixed with `(jail) \w $ `.
5. **Inspect Active Sandbox Configuration:**
   From outside the sandbox, run `ai-jail status` to view active mounts and security rules.

---

## 5. How to Clear and Manage Memory (ai-memory)

There are 3 ways to delete or reset stored memory data:

1. **Clear CURRENT Project Only (Recommended):**
   Removes all wiki pages, sessions, and observations for the current repository/project:
   ```bash
   ai-memory purge-project --confirm
   ```
2. **Clear EVERYTHING (Global Reset):**
   Wipes the entire database, wiki files, and logs across **all** saved projects:
   ```bash
   ai-memory reset --confirm
   ```
3. **Delete a Specific Page:**
   Deletes a single note or wiki page by query/keyword search:
   ```bash
   ai-memory delete-page --query "page name or search query"
   ```

---

## 6. Native MCP Integration with Agents (`agy` / `antigravity-cli`)

Agents such as **`agy` (Google Antigravity CLI)** load `ai-memory` natively via the MCP protocol configured at `~/.gemini/antigravity-cli/mcp_config.json`.

When running:
```bash
ai-jail agy
```
`ai-jail` isolates the environment while `agy` automatically connects to the `ai-memory` HTTP server (port `49374`). This exposes all MCP tools (`memory_search`, `memory_read_page`, `memory_write_page`, etc.) transparently without needing to call the `ai-memory run` wrapper.

---

## 7. Quick Troubleshooting

* **Error `Connection refused (os error 111)`:**
  The systemd background service is stopped. Start it with:
  `systemctl --user start ai-memory`

* **Message `another launcher owns this workstream`:**
  Another process/terminal is waiting at the `Select [1]:` prompt. Respond to the open terminal prompt or force a new workstream using `--new <name>`.


