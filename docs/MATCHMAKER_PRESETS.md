# Matchmaker Presets Reference

Matchmaker (`mm`) uses TOML configuration presets located in `~/.config/matchmaker/presets/<name>.toml` to render specialized, purpose-built TUI interfaces invoked via `mm -o <name>`.

## Available Presets

| Preset | Invocation | Purpose | Key Actions |
| :--- | :--- | :--- | :--- |
| **jump** | `mm -o jump` | Frecency directory navigation with tree view and `nav_mode` (`h`/`l`). | `Enter`: `cd` to directory<br>`l`: Drill down into child directory<br>`h`: Jump to parent directory<br>`Alt+u`: Ancestor jump |
| **ftb** | `mm -o ftb` | Multi-column tab completion engine for ZSH `fzf-tab` with Nucleo fuzzy matching. | `Tab`: Select item<br>`Shift-Tab`: Previous item<br>`Ctrl+P`: Toggle preview |
| **wt** | `mm -o wt` | Interactive Git Worktree switcher integrated with `worktrunk`. Live preview of `git status -s` and recent commit log. | `Enter`: Selects and returns worktree path |
| **kill** | `mm -o kill` | Interactive TCP listening port & process terminator with live connection preview. | `Enter`: Send `SIGTERM` (15)<br>`Ctrl+X`: Force `SIGKILL` (-9) |
| **memory** | `mm -o memory` | Fast explorer for project rules, `AGENTS.md`, agent skills, and durable memory. | `Enter`: Open selected file |
| **sesh-picker** | `mm -o sesh-picker` | Tmux session picker grouped by status and Nerd Font icons. | `Enter`: Connect to session via `sesh connect` |
| **window-picker** | `mm -o window-picker` | Cross-session Tmux window picker with dynamic ACPD agent indicators and live previews. | `Enter`: Switch to selected window |
