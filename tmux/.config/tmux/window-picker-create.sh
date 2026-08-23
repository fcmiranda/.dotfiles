#!/usr/bin/env sh
# window-picker-create.sh — helper script to create a new window in window-picker

RAW_INPUT=$(cat)
session=""

if [ -n "$RAW_INPUT" ]; then
  session=$(printf '%s' "$RAW_INPUT" | head -n1 | cut -f4)
fi

if [ -z "$session" ]; then
  session="${TMUX_ORIGIN_SESSION:-$(tmux display-message -p '#S')}"
fi

tmux new-window -t "${session}:" 2>/dev/null || true
