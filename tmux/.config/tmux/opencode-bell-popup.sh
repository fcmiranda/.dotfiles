#!/usr/bin/env bash
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

TITLE=" $sess › $win_name  │  prefix+q close"

tmux popup \
  -S "fg=$BORDER_COLOR" \
  -s "fg=$TEXT_COLOR" \
  -T "$TITLE" \
  -w "$WIDTH" \
  -h "$HEIGHT" \
  -b rounded \
  -E \
  "tmux set-option -t \"$sess\" status off >/dev/null 2>&1; tmux attach-session -t \"$sess:$win_idx\"; tmux set-option -t \"$sess\" status on >/dev/null 2>&1"
