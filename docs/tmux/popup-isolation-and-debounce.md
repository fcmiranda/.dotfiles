# Tmux Popup Isolation, ACPD Debounce & Event-Driven Architecture

This document records the identified issues of visual flicker, rendering collisions in floating popups during active AI streaming, and the definitive architectural solutions implemented in `tmux` and the `acpd` daemon.

---

## 1. Root Cause Analysis

### 🔴 Issue A: Status Pill Flicker & Rapid State Bouncing
- **Cause:** During active AI executions (such as Antigravity / OpenCode), chained tasks emit rapid lifecycle events: `PostInvocation` (`idle`) followed immediately by `PreInvocation` (`working`) within 20ms to 100ms intervals on each file read, search, or executed command.
- **Visual Impact:** The window status tab and pill at the top of tmux rapidly flickered between yellow (`󰑮` working) and blue/teal (`󱥂` idle) multiple times per second during a single AI response turn.

### 🔴 Issue B: Popup Top Border & Search Input Disappearing
- **Cause:** Tmux's `display-popup` command renders a floating overlay directly over the active pane. While the AI agent outputs text, the background pane rapidly outputs dozens of lines of text and ANSI scroll escapes per second. In the tmux core engine, `server_client_draw_pane` redraws updated background cells directly to the terminal, clobbering and overwriting the popup's top frame.
- **Visual Impact:** The rounded top border (`╭─── Sesh ───╮`) and search input line (`⚡ ` / ` `) vanished while the agent streamed tokens, only reappearing after the agent concluded execution.

### 🔴 Issue C: Navigation Loss Upon Selecting a Session or Window
- **Cause:** Earlier popup wrapper scripts captured the prior active window/session and executed an unconditional `tmux switch-client -t "$ORIG_TARGET"` upon closing. This forced the client back to the invoking pane, discarding the user's new session/window selection.

### 🔴 Issue D: Useless Periodic Polling (`status-interval 1`)
- **Cause:** Tmux was waking up 60 times per minute to re-evaluate format strings and spawn shell format processes, even when the terminal and system were completely idle.

---

## 2. Architectural Solutions Implemented

```
┌─────────────────────────────────────────────────────────────────────────┐
│                          TARGET ARCHITECTURE                            │
├────────────────────────────────┬────────────────────────────────────────┤
│ Idle Agent / Static Terminal   │ Direct & Native Display Popup          │
│                                │ (Immediate popup without backdrop)     │
├────────────────────────────────┼────────────────────────────────────────┤
│ Active Streaming Agent         │ Frozen Transparent Snapshot Backdrop   │
│ (@ai_agent_state_raw = busy)   │ (tmux capture-pane -ep -> _popups)     │
├────────────────────────────────┼────────────────────────────────────────┤
│ Rapid AI Tool Transitions      │ 400ms Idle Debounce in ACPD            │
│ (Sequential tool calls)        │ (Cancels intermediate idle state flips)│
├────────────────────────────────┼────────────────────────────────────────┤
│ CPU & Battery Consumption      │ status-interval 0 (100% Event-Driven)  │
│                                │ (Reactive updates via ACPD IPC events) │
└────────────────────────────────┴────────────────────────────────────────┘
```

---

### 🛡️ 1. 400ms Debounce & Deduplication in ACPD
Inside the `acpd` daemon (`adapters.rs`):
- **400ms Debounce for `AgentState::Idle`:**
  ```rust
  // When state transitions to Idle, schedule a 400ms async cancellation window
  let task = tokio::spawn(async move {
      tokio::time::sleep(tokio::time::Duration::from_millis(400)).await;
      // Commit Idle only if no new tool call arrived during the window
      set_tmux_option(&pane_id, "@ai_agent_state", &t.icon).await;
      set_tmux_option(&pane_id, "@ai_agent_state_raw", "idle").await;
      refresh_tmux_client().await;
  });
  ```
- **Instant Cancellation:** Any incoming `Working` event immediately aborts the pending `Idle` task, keeping the spinner animating smoothly without flicker.
- **State Deduplication (`pane_states`):** Eliminates redundant tmux IPC writes when pane status remains unchanged.

---

### 🪄 2. Frozen Transparent Snapshot Backdrop
Inside the popup launcher scripts (`sesh-picker.sh`, `window-picker.sh`, `lazygitrs-popup.sh`):

```bash
AI_STATE=$(tmux show-options -pqv -t "$TARGET_PANE" @ai_agent_state_raw)
if [ "$AI_STATE" = "busy" ] || [ "$AI_STATE" = "working" ]; then
    CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
    ORIG_TARGET=$(tmux display-message -p '#{session_name}:#{window_index}')
    
    # 1. Capture a frozen visual snapshot of the buffer with ANSI colors (<1ms)
    tmux capture-pane -ep -t "$CURRENT_PANE" > /tmp/tmux-backdrop.ansi 2>/dev/null || true

    # 2. Render the snapshot into a static background pane in the dedicated _popups session
    if ! tmux list-windows -t "_popups" -F '#W' 2>/dev/null | grep -q "^backdrop$"; then
        tmux new-window -d -t "_popups" -n "backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    else
        tmux respawn-window -k -t "_popups:backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    fi

    # 3. Switch client to clean static backdrop and open popup
    tmux switch-client -t "_popups:backdrop" 2>/dev/null || true
    tmux display-popup -b rounded -T " Title " -w 80% -h 35% -y 34 -E "..."

    # 4. Intelligent restore: switch back only if the user cancelled (still inside _popups)
    CURRENT_SESS=$(tmux display-message -p '#{session_name}')
    if [ "$CURRENT_SESS" = "_popups" ]; then
        tmux switch-client -t "$ORIG_TARGET" 2>/dev/null || true
    fi
    exit 0
else
    # Clean/static terminal: invoke native popup directly without backdrop overhead
    exec tmux display-popup -b rounded -T " Title " -w 80% -h 35% -y 34 -E "..."
fi
```

---

### ⚡ 3. 100% Event-Driven Status Bar (`status-interval 0`)
In `tmux.conf`:
```tmux
# Event-driven status bar (zero background clock polling; driven exclusively by events and acpd)
set -g status-interval 0
```
- **Advantages:** 0.0% background idle CPU usage, zero shell fork overhead.
- **Spinner Animation:** Maintained at 12 FPS (83ms) by the `acpd` daemon via `refresh_tmux_client()` exclusively when an agent is actively running.

---

## 3. Related Files & Documentation

- `acpd/src/adapters.rs`: Implementation of the 400ms async debounce and state deduplication.
- [`tmux/.config/tmux/tmux.conf`](../../tmux/.config/tmux/tmux.conf): Configuration of `status-interval 0` and ergonomic popups.
- [`tmux/.config/tmux/sesh-picker.sh`](../../tmux/.config/tmux/sesh-picker.sh): Session picker with intelligent backdrop and navigation preservation.
- [`tmux/.config/tmux/window-picker.sh`](../../tmux/.config/tmux/window-picker.sh): Matchmaker window picker with intelligent backdrop.
- [`tmux/.config/tmux/lazygitrs-popup.sh`](../../tmux/.config/tmux/lazygitrs-popup.sh): Lazygitrs popup with smart `--commits` detection and backdrop handling.
- [`docs/tmux/ai-status-bar.md`](ai-status-bar.md): Comprehensive guide to AI agent status pills and state animations.
