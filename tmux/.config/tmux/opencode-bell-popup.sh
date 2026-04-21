#!/usr/bin/env bash
pane=$(tmux show -gv @opencode_last_bell 2>/dev/null)

if [ -z "$pane" ]; then
  printf "\n  No OpenCode notification yet\n\n  Press any key to dismiss...\n"
  read -n1 -s
  exit 0
fi

sess=$(tmux display-message -t "$pane" -p '#S' 2>/dev/null)
win_idx=$(tmux display-message -t "$pane" -p '#I' 2>/dev/null)

# Hide status bar while inside popup; restore when this client detaches
tmux set-option -t "$sess" status off
tmux set-hook -t "$sess" client-detached \
  "set-option status on ; set-hook -u client-detached"

exec tmux attach-session -t "${sess}:${win_idx}"
