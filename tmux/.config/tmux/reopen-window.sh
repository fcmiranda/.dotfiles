#!/usr/bin/env bash
# reopen-window.sh — reopens the most recently closed Tmux window/tab with its file, path & session
set -euo pipefail

STATE_DIR="$HOME/.local/state/tmux"
STACK_FILE="$STATE_DIR/closed-windows.json"

if [ ! -f "$STACK_FILE" ] || [ ! -s "$STACK_FILE" ]; then
  tmux display-message -d 1500 "󰅙 No closed tabs to reopen"
  exit 0
fi

# Pop the top entry from the stack
TOP_ITEM=$(jq '.[0] // empty' "$STACK_FILE" 2>/dev/null || true)
if [ -z "$TOP_ITEM" ] || [ "$TOP_ITEM" = "null" ]; then
  tmux display-message -d 1500 "󰅙 No closed tabs to reopen"
  exit 0
fi

# Remove the popped entry from stack
jq '.[1:]' "$STACK_FILE" > "$STACK_FILE.tmp" 2>/dev/null && mv "$STACK_FILE.tmp" "$STACK_FILE"

# Extract fields
session=$(echo "$TOP_ITEM" | jq -r '.session // empty')
name=$(echo "$TOP_ITEM" | jq -r '.name // empty')
path=$(echo "$TOP_ITEM" | jq -r '.path // empty')
cmd=$(echo "$TOP_ITEM" | jq -r '.cmd // empty')
file=$(echo "$TOP_ITEM" | jq -r '.file // empty')

# Directory validation
if [ -z "$path" ] || [ ! -d "$path" ]; then
  path="$HOME"
fi

[ -z "$name" ] && name="restored"

current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)

# Resolve target session
if [ -n "$session" ] && tmux has-session -t "$session" 2>/dev/null; then
  target_session="$session"
elif [ -n "$current_session" ] && [ "$current_session" != "_popups" ]; then
  target_session="$current_session"
elif [ -n "$session" ]; then
  # Recreate session if it died
  tmux new-session -d -s "$session" -c "$path" 2>/dev/null || true
  target_session="$session"
else
  target_session="$(tmux display-message -p '#{session_name}')"
fi

# Create new window in target session
new_win=$(tmux new-window -P -F '#{window_id}' -t "${target_session}:" -c "$path" -n "$name")

# Launch active command or file if applicable
if [ -n "$cmd" ]; then
  tmux send-keys -t "$new_win" "$cmd" C-m
elif [ -n "$file" ]; then
  tmux send-keys -t "$new_win" "nvim $(printf '%q' "$file")" C-m
fi

# Switch focus to the newly restored window
tmux select-window -t "$new_win"
if [ "$target_session" != "$current_session" ]; then
  tmux switch-client -t "$target_session" 2>/dev/null || true
fi

# Auditory & visual feedback
label="$name"
if [ -n "$file" ]; then
  label="$(basename "$file")"
elif [ -n "$cmd" ]; then
  label="$cmd"
fi

tmux display-message -d 1500 "󰁯 Reopened tab: $label ($path)"

# Optional ACPD bell sound notification
curl -s -X POST http://localhost:4040/rpc -H "Content-Type: application/json" -d '{"jsonrpc":"2.0","method":"bell","params":{},"id":1}' >/dev/null 2>&1 || true
