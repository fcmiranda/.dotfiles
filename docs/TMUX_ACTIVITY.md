# The Mystery of Tmux Tab Highlight (Window Activity Monitoring)

You might have noticed that when asking the AI a question using `agy` (Antigravity) while switched to another tab, the original `agy` tab highlighted (inverting the background color), whereas the same did not happen when using `oc` (OpenCode).

## Why Does This Happen?

This is neither a bug nor caused by our `acpd` daemon. It is a classic (and very useful) feature called **Tmux Window Activity Monitoring**.

### The Antigravity (`agy`) Case
Antigravity operates as a pure CLI tool. While processing a response or outputting a prompt (e.g., `"What would you like to do?"`), it sends standard text output (`stdout`) to the terminal screen.

When Tmux detects that a background tab has just received new text characters on screen, it identifies that the terminal in the background has updated and notifies you. Consequently, it inverts that tab's background color in the status bar to draw your attention.

### The OpenCode (`oc`) Case
OpenCode uses a TUI (Text User Interface) framework—similar to `htop`, `lazygit`, or `neovim`. Instead of outputting raw text lines, these applications actively manage screen drawing using alternate screen buffers and typically pause sending raw updates when waiting for user input. Because no continuous raw text is printed to standard terminal output, Tmux does not trigger the activity monitor.

## Configuration (Enable / Disable)

If you find this visual notification helpful, you can ensure it stays enabled. If you prefer not to have tabs highlight while the AI runs background commands, you can disable it.

This setting is located in your `~/.config/tmux/tmux.conf` file:

```tmux
# Window Activity Monitoring
setw -g monitor-activity on
set -g visual-activity off
```

- `setw -g monitor-activity on` -> Enables tab highlighting (visual background highlight when `agy` responds or interacts).
- `setw -g monitor-activity off` -> Disables activity highlighting completely.
- `set -g visual-activity off` -> Prevents Tmux from displaying text messages at the bottom status line (e.g., `"Activity in window 0"`), keeping notifications strictly as silent tab highlighting.

> **To reload the configuration:**
> Press `Ctrl+Space` followed by `r` in Tmux to source `tmux.conf`.
