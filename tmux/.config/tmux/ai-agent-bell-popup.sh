#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style"
unset _tmux_style

# Collect all panes that require attention or have AI agent activity
notifying_panes=()

# 1. First, search for panes in active attention/question/permission/error state
while IFS= read -r line; do
  [ -n "$line" ] && notifying_panes+=("$line")
done < <(tmux list-panes -a -F '#{pane_id} #{@ai_agent_state_raw}' 2>/dev/null | awk '$2 ~ /^(question|permission|error|awaiting_input)$/ {print $1}')

# 2. Fallback to @ai_agent_last_bell if no state-filtered panes found
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  last_bell=$(tmux show-gv @ai_agent_last_bell 2>/dev/null)
  if [ -n "$last_bell" ] && tmux display-message -t "$last_bell" -p '#{pane_id}' >/dev/null 2>&1; then
    notifying_panes+=("$last_bell")
  fi
fi

if [ "${#notifying_panes[@]}" -eq 0 ]; then
  tmux display-popup \
    -b rounded \
    -S "fg=$TMUX_POPUP_BORDER_COLOR" \
    -T " No OpenCode notification " \
    -w 38 -h 5 \
    "printf '\n  No OpenCode notification yet.\n'; sleep 2"
  exit 0
fi

# Ring Buffer Rotation: read and increment index in tmux global env
total=${#notifying_panes[@]}
curr_idx=$(tmux show-option -gv @ai_agent_bell_ring_idx 2>/dev/null || echo 0)
if ! [[ "$curr_idx" =~ ^[0-9]+$ ]] || [ "$curr_idx" -ge "$total" ]; then
  curr_idx=0
fi

pane="${notifying_panes[$curr_idx]}"

# Calculate next index for the next keypress
next_idx=$(( (curr_idx + 1) % total ))
tmux set-option -g @ai_agent_bell_ring_idx "$next_idx" 2>/dev/null

sess=$(tmux display-message -t "$pane" -p '#S' 2>/dev/null)
win_idx=$(tmux display-message -t "$pane" -p '#I' 2>/dev/null)
win_name=$(tmux display-message -t "$pane" -p '#W' 2>/dev/null)

TITLE=" $sess › $win_name ($((curr_idx + 1))/$total)  │  Alt+i cycle "

# If current client is already on the same session, jump directly to the window.
current_sess=$(tmux display-message -p '#S' 2>/dev/null)
if [ "$current_sess" = "$sess" ]; then
  tmux select-window -t "$sess:$win_idx"
  tmux select-pane -t "$pane" 2>/dev/null
  exit 0
fi

POPUP_SESS="_popups"
if ! tmux has-session -t "$POPUP_SESS" 2>/dev/null; then
  tmux new-session -d -s "$POPUP_SESS" -n "bell"
fi

tmux unlink-window -t "$POPUP_SESS:bell" 2>/dev/null || true
tmux link-window -s "$sess:$win_idx" -t "$POPUP_SESS:bell" 2>/dev/null || true
tmux set-option -t "$POPUP_SESS" status off 2>/dev/null || true

tmux popup \
  -S "fg=$TMUX_POPUP_BORDER_COLOR" \
  -s "fg=$TMUX_POPUP_TEXT_COLOR" \
  -T "$TITLE" \
  -w "$TMUX_POPUP_WIDTH" \
  -h "$TMUX_POPUP_HEIGHT" \
  -b rounded \
  -E \
  "tmux attach-session -t \"$POPUP_SESS:bell\"; tmux unlink-window -t \"$POPUP_SESS:bell\" >/dev/null 2>&1"
