#!/usr/bin/env sh
# switch to the last session, ignoring the "popups" session
cur="$(tmux display-message -p '#S')"
next="$(tmux list-sessions -F '#{session_last_attached} #{session_name}' | sort -nr | sed 's/^[0-9]* *//' | awk -v cur="$cur" '$0 != "popups" && $0 != cur' | head -n 1)"
if [ -n "$next" ]; then
  tmux switch-client -t "$next"
else
  tmux display-message -d 1000 'Only one session'
fi
