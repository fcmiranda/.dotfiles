#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.local/state/omarchy/current/theme/tmux-style.sh"
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
  last_bell=$(tmux show-option -gv @ai_agent_last_bell 2>/dev/null)
  if [ -n "$last_bell" ] && tmux display-message -t "$last_bell" -p '#{pane_id}' >/dev/null 2>&1; then
    notifying_panes+=("$last_bell")
  fi
fi

# 3. Fallback: Check for panes currently in active working/busy state
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{@ai_agent_state_raw}' 2>/dev/null | awk '$2 ~ /^(working|busy)$/ {print $1}')
fi

# 4. Fallback: Check for any pane with a registered AI agent state (including idle / recently responded)
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{@ai_agent_state_raw}' 2>/dev/null | awk '$2 ~ /^(idle|working|busy|question|permission|error|awaiting_input)$/ {print $1}')
fi

# 5. Fallback: Search for any pane running agy, antigravity, or opencode (command or title)
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{pane_title}' 2>/dev/null | awk '$2 ~ /^(agy|antigravity|opencode)$/ || $3 ~ /^(agy|antigravity|opencode)$/ {print $1}')
fi

if [ "${#notifying_panes[@]}" -eq 0 ]; then
  tmux display-message -d 1500 " 󰮯 No active AI Agent notification."
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

TITLE=" $sess › $win_name ($((curr_idx + 1))/$total)  │  prefix+i cycle "

# If current client is already on the same session, jump directly to the window and show HUD.
current_sess=$(tmux display-message -p '#S' 2>/dev/null)
if [ "$current_sess" = "$sess" ]; then
  tmux select-window -t "$sess:$win_idx" 2>/dev/null || true
  tmux select-pane -t "$pane" 2>/dev/null || true
  tmux display-message -d 1500 " 󰮯 AI Agent: $sess › $win_name ($((curr_idx + 1))/$total)"
  exit 0
fi

POPUP_SESS="_popups"
if ! tmux has-session -t "$POPUP_SESS" 2>/dev/null; then
  tmux new-session -d -s "$POPUP_SESS" -n "_dummy"
fi

# Clean any existing linked window in _popups except the initial _dummy window (index 0)
for w in $(tmux list-windows -t "$POPUP_SESS" -F '#{window_id}:#{window_index}' 2>/dev/null); do
  w_id="${w%%:*}"
  w_idx="${w##*:}"
  if [ "$w_idx" != "0" ]; then
    tmux unlink-window -t "$w_id" 2>/dev/null || tmux kill-window -t "$w_id" 2>/dev/null || true
  fi
done

# Link target window to index 1 of _popups
tmux link-window -s "$sess:$win_idx" -t "$POPUP_SESS:1" 2>/dev/null || tmux link-window -a -s "$sess:$win_idx" -t "$POPUP_SESS:0" 2>/dev/null || true
tmux select-window -t "$POPUP_SESS:1" 2>/dev/null || true
tmux select-pane -t "$pane" 2>/dev/null || true
tmux set-option -t "$POPUP_SESS" status off 2>/dev/null || true

ALERT_POPUP_COLOR=$(grep -E '^\s*yellow\s*=' "$HOME/.local/state/omarchy/current/theme/colors.toml" 2>/dev/null | sed -E 's/.*=\s*"([^"]+)".*/\1/')
[ -z "$ALERT_POPUP_COLOR" ] && ALERT_POPUP_COLOR="${TMUX_POPUP_ALERT_BORDER_COLOR:-#f9e2af}"

tmux display-popup \
  -S "fg=$ALERT_POPUP_COLOR" \
  -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
  -T " 󰮯 " \
  -w "80%" \
  -h "75%" \
  -b rounded \
  -E \
  "tmux attach-session -t \"$POPUP_SESS:1\"; tmux unlink-window -t \"$POPUP_SESS:1\" >/dev/null 2>&1 || true"
