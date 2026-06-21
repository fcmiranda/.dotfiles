# Open-Source Strategy: Agent Client Protocol (ACP) Ecosystem

## 1. Executive Summary
The goal is to transition the highly-coupled, personal dotfiles AI terminal state orchestration into a modular, plug-and-play open-source ecosystem. By decoupling the background daemon, the UI components, and the client hook SDKs, we create a standard for "Terminal AI State Management" that anyone can install via Cargo, TPM (Tmux Plugin Manager), and NPM.

## 2. Core Philosophy
- **Separation of Concerns:** The daemon (`acpd`) only knows about state and sinks (Output Adapters). It does not know about user dotfiles or specific shell environments.
- **Protocol First:** The HTTP REST (`/api/status`) and JSON-RPC (`/rpc`) APIs serve as the universal contract.
- **Zero-Config Defaults, Infinite Customization:** Sensible default colors and spinners out of the box, configurable via a centralized `TOML` file.

## 3. Architecture Overview

```mermaid
graph TD
    subgraph Clients ["Agent Hooks (The Publishers)"]
        A[OpenCode] -->|HTTP POST| D
        B[Antigravity] -->|HTTP POST| D
        C[Copilot CLI] -->|HTTP POST| D
    end

    subgraph Core ["ACP Daemon (The Broker)"]
        D((acpd :4040))
        D -->|TmuxAdapter| E
        D -->|WaybarAdapter| F
    end

    subgraph Sinks ["Terminal UI (The Subscribers)"]
        E[tmux-acp TPM Plugin]
        F[Waybar Custom Module]
        G[Matchmaker Window Picker]
        E <..> G
    end
```

## 4. Repository Breakdown

To successfully open-source the ecosystem, the code must be split into independent repositories.

### A. `fcmiranda/acpd` (The Broker)
The central Rust daemon.
- **Role:** Receives HTTP payloads, manages the state machine, renders active spinners into generic outputs.
- **Action Items:**
  - Remove all hardcoded paths (e.g., `~/.config/omarchy`). Use `$XDG_CONFIG_HOME/acpd/config.toml` as the primary configuration lookup.
  - Document the REST payload schema in a pristine `README.md`.
  - Setup GitHub Actions to publish pre-compiled binaries for Linux and macOS.

### B. `fcmiranda/tmux-acp` (The Visual Layer)
A standard Tmux Plugin Manager (TPM) repository.
- **Role:** Injects the AI states into the Tmux UI gracefully.
- **Structure:**
  - `tmux-acp.tmux`: The entrypoint. It reads `@ai_agent_state` and exposes standard formatter variables like `#{acp_status}` and `#{acp_spinner}`.
  - `scripts/bell-popup.sh`: The decoupled version of `ai-agent-bell-popup.sh`.
- **User Config:**
  ```tmux
  set -g @plugin 'fcmiranda/tmux-acp'
  set -g @acp-bell-key 'i'
  set -g status-right "#{acp_status} %H:%M"
  ```

### C. `fcmiranda/matchmaker-acp` (The TUI Extension)
A showcase of how to integrate ACP into modern TUI workflows.
- **Role:** Provides the `window-picker.sh` and `window-picker-items.sh` logic.
- **Structure:**
  - Ships with `window-picker.toml`.
  - The script dynamically reads the global tmux variables exposed by `tmux-acp` instead of hardcoded config parsing.

### D. `@acpd/client` (The SDKs)
Thin wrapper libraries for agent creators.
- **Role:** Allows any Node.js/Python CLI tool to report its state with zero boilerplate.
- **Structure (NPM):**
  ```typescript
  import { AgentStatus } from '@acpd/client';
  
  await AgentStatus.working({ paneId: process.env.TMUX_PANE });
  ```

## 5. Refactoring & Decoupling Checklist

- [ ] **Daemon Configuration:** Ensure `src/daemon.rs` creates default config directories (`~/.config/acpd`) if they don't exist.
- [ ] **Tmux Fallbacks:** In `TmuxAdapter`, ensure that if `tmux` commands fail (e.g., user is running detached), the daemon does not panic, but gracefully degrades.
- [ ] **Plugin Abstraction:** Port `ai-agent-bell-popup.sh` into `tmux-acp`, replacing hardcoded Omarchy colors with standard tmux styles (`#[fg=cyan]`) or variables provided by the plugin (`@acp_popup_border`).
- [ ] **Documentation:** Write a "Quick Start" guide showing how to wire a mock bash script to `acpd`.

## 6. Launch & Community Strategy
1. **The Core Release:** Publish `acpd` to crates.io and GitHub Releases.
2. **The Visual Demo:** Publish a high-quality GIF of the Tmux spinner, the Matchmaker integration, and the Waybar sync. Visuals drive TUI adoption.
3. **The "Why":** Write an engineering blog post or a GitHub Discussion about the fragmentation of AI tool statuses (Cursor vs Copilot vs Custom CLI) and how `acpd` unifies them into a single, beautiful terminal layer.
