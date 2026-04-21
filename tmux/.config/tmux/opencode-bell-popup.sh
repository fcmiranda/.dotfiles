#!/usr/bin/env bash
FLOAX_DIR="$HOME/.tmux/plugins/tmux-floax/scripts"

BORDER_COLOR="magenta"
TEXT_COLOR="blue"
WIDTH="90%"
HEIGHT="90%"

pane=$(tmux show -gv @opencode_last_bell 2>/dev/null)

if [ -z "$pane" ]; then
  tmux display-popup \
    -b rounded \
    -S "fg=$BORDER_COLOR" \
    -T " No OpenCode notification " \
    -w 38 -h 5 \
    "printf '\n  No OpenCode notification yet.\n'; sleep 2"
  exit 0
fi

sess=$(tmux display-message -t "$pane" -p '#S' 2>/dev/null)
win_idx=$(tmux display-message -t "$pane" -p '#I' 2>/dev/null)
win_name=$(tmux display-message -t "$pane" -p '#W' 2>/dev/null)

TITLE=" $sess › $win_name  │  C-M-s 󰘕  C-M-b 󰁌  C-M-f 󰊓  C-M-r 󰑓"

# Set FloaX-style resize bindings
tmux bind -n C-M-s run "$FLOAX_DIR/zoom-options.sh in"
tmux bind -n C-M-b run "$FLOAX_DIR/zoom-options.sh out"
tmux bind -n C-M-f run "$FLOAX_DIR/zoom-options.sh full"
tmux bind -n C-M-r run "$FLOAX_DIR/zoom-options.sh reset"
tmux bind -n C-M-e run "$FLOAX_DIR/embed.sh embed"
tmux bind -n C-M-d run "$FLOAX_DIR/zoom-options.sh lock"
tmux bind -n C-M-u run "$FLOAX_DIR/zoom-options.sh unlock"

# Hide status bar; restore + unbind resize keys on popup close
tmux set-option -t "$sess" status off
tmux set-hook -t "$sess" client-detached \
  "set-option status on ; unbind -n C-M-s ; unbind -n C-M-b ; unbind -n C-M-f ; unbind -n C-M-r ; unbind -n C-M-e ; unbind -n C-M-d ; unbind -n C-M-u ; set-hook -u client-detached"

tmux popup \
  -S "fg=$BORDER_COLOR" \
  -s "fg=$TEXT_COLOR" \
  -T "$TITLE" \
  -w "$WIDTH" \
  -h "$HEIGHT" \
  -b rounded \
  -E \
  "tmux attach-session -t '${sess}:${win_idx}'"
