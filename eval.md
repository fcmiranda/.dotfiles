# TUI AI Workflow Analysis & Optimization

This is a fascinating setup. You have essentially built a bespoke IDE out of composable CLI tools, deeply integrating an AI agent (`opencode`) into the core loop of your window manager and terminal multiplexer.

After deeply analyzing your `tui-ai-workflows.md`, your `tmux.conf`, your Hyprland bindings, and the brilliant `hooker.ts` integration, here is a comprehensive breakdown of your workflow, the hidden friction points, and a concrete plan to achieve true zero-friction, one-keymap access.

## 1. What is Exceptional (The Good)

Your current architecture solves problems that most developers haven't even realized they have yet.

*   **The State Machine (`hooker.ts`)**: This is the crown jewel of your setup. Instead of staring at a window waiting for an AI to finish, you've extracted the AI's state (busy, idle, question, permission) and piped it into the tmux status bar and desktop notifications. This transforms the AI from a synchronous blocking task into an asynchronous background worker.
*   **Reactive Navigation (`prefix+i`)**: Connecting the `hooker.ts` bell directly to a popup that attaches to the specific pane requiring attention is brilliant. It completely eliminates the "hunt for the notification" phase.
*   **Desktop-to-Session Unification (`Super+Shift+K`)**: Using Walker/Fuzzel to jump straight into a specific project's tmux session from the desktop layer drastically reduces context-switching latency.

## 2. The Friction Points ("The Thinking Trap")

Despite the power of your setup, it violates the "zero thinking" rule in a few subtle ways. If you have to look at the screen to decide which button to press, you have friction.

*   **Positional vs. Semantic Navigation (`Ctrl+2`)**: Right now, you jump to the AI using `Ctrl+2` (assuming it's the second window). But what if you opened `lazygit` first? What if the AI is window 3? You have to look at the status bar, parse the number, and press `Ctrl+N`. This requires thinking.
*   **The "Context Eclipse"**: When you switch to an AI window, your code disappears. If you want to ask "What does the function on line 42 do?", you have to memorize the context, switch to the AI window, ask the question, and switch back. This creates working-memory friction.
*   **The "Scratchpad" Problem**: Sometimes you don't want AI in the context of a project; you just want a global omniscient calculator/assistant. Right now, reaching a "blank" AI requires spawning a terminal, ensuring you aren't in a project session, and launching OpenCode.

## 3. Suggestions for "Zero Friction"

To get to a state where your fingers move faster than your conscious thought, we need to implement **Pattern-Based Keymaps**. Every interaction type should have exactly one dedicated shortcut that behaves predictably 100% of the time.

### A. The Contextual Overlay (The "Quick Question")

**Goal**: Ask the AI a question without losing sight of your code, instantly toggleable.
**Solution**: A native tmux popup bound to a modifier without a prefix.

*   **Keybind**: `Alt+o` (in any tmux session)
*   **Action**: Instantly drops down an 80% width/height popup running OpenCode in the current directory. Press `Alt+o` (or `Escape`) to dismiss it.
*   **Why it's zero friction**: It's a true toggle. You don't manage windows. You ask, you dismiss, your editor never moves.

**Tmux Config Addition:**
```tmux
# Alt+o toggles a floating AI popup
bind-key -n M-o display-popup -E -w 80% -h 80% -b rounded -T " OpenCode " "opencode"
```

### B. The Semantic Jump (The "Deep Work Window")

**Goal**: Go to the project's dedicated AI window without caring what number it is, creating it if it doesn't exist.
**Solution**: A script that searches for a window named `ai` or `opencode`.

*   **Keybind**: `Alt+a` (in any tmux session)
*   **Action**: If a window named `ai` exists, switch to it. If it doesn't, create it, name it `ai`, and launch `opencode`.
*   **Why it's zero friction**: Replaces `Ctrl+2`. You never have to look at your window list again. `Alt+a` always means "Project AI".

**Tmux Config Addition:**
```tmux
# Alt+a jumps to or creates the 'ai' window
bind-key -n M-a run-shell 'tmux select-window -t ai 2>/dev/null || tmux new-window -n ai "opencode"'
```

### C. The Sidebar Toggle (The "Pair Programming" Mode)

**Goal**: Side-by-side code and AI that can be summoned or banished with one keystroke.
**Solution**: A tmux script that smartly splits the current window.

*   **Keybind**: `prefix+o`
*   **Action**: Splits the window 30% vertically and runs OpenCode. If the sidebar is already open, it kills it.

**Tmux Config Addition:**
```tmux
# prefix+o toggles an AI sidebar
bind-key o run-shell 'pane_cnt=$(tmux list-panes | wc -l); if [ "$pane_cnt" -gt 1 ]; then tmux kill-pane -t :.+; else tmux split-window -h -l 35% "opencode"; fi'
```

### D. The Global Desktop Dropdown (The "Scratchpad")

**Goal**: Summon the AI from anywhere in the OS (browser, Spotify, empty desktop) in under 100ms.
**Solution**: A customized floating Ghostty window managed by Hyprland.

*   **Keybind**: `Super+A`
*   **Action**: A sleek, centered, semi-transparent terminal appears overlaying your entire screen, connected to a persistent tmux session named `global-ai`.

**Hyprland Config Additions:**
```conf
# In bindings.conf
bind = SUPER, A, exec, uwsm-app -- ghostty --class="global-ai" -e tmux new-session -A -s global-ai opencode

# In windowrules.conf (or similar)
windowrulev2 = float, class:^(global-ai)$
windowrulev2 = size 80% 80%, class:^(global-ai)$
windowrulev2 = center, class:^(global-ai)$
windowrulev2 = animation slide, class:^(global-ai)$
```

## 4. Sesh Standardization

To prevent window number guesswork on fresh project loads, you can standardise window creation via the `~/.config/sesh/sesh.toml` wildcard capability.

```toml
# Every new project loaded via sesh gets an editor and an AI window
[[wildcard]]
pattern = "~/*"
windows = ["ai"]

[[window]]
name = "ai"
startup_command = "opencode"
```

## Summary of the "Thinking-Free" End State

By adding those 4 snippets, your cognitive load drops to zero:

*   **Need AI over my code?** $\rightarrow$ `Alt+o`
*   **Need my AI project window?** $\rightarrow$ `Alt+a`
*   **Need AI side-by-side?** $\rightarrow$ `prefix+o`
*   **Need AI from the browser?** $\rightarrow$ `Super+A`
*   **Did AI finish while I was coding?** $\rightarrow$ `prefix+i`

There is no longer a need to check numbers, parse window lists, or spawn new terminals. Every scenario has an instantaneous, deterministic shortcut.