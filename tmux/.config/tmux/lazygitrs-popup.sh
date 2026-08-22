#!/usr/bin/env bash
PROJECT_DIR="$1"

if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    tmux display-message "Not in a git repository"
    exit 0
fi

WINDOW_NAME="lzg-$(echo -n "$PROJECT_DIR" | md5sum | cut -d' ' -f1 | head -c 8)"
SESSION_NAME="_popups"


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style" 2>/dev/null || true
unset _tmux_style

# Create session if it doesn't exist, otherwise add a window if needed
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
else
    if ! tmux list-windows -t "$SESSION_NAME" -F '#W' 2>/dev/null | grep -q "^${WINDOW_NAME}$"; then
        tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
    fi
fi

AI_STATE=$(tmux display-message -p '#{@ai_agent_state_raw}')
if [ "$AI_STATE" = "busy" ] || [ "$AI_STATE" = "working" ]; then
    CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
    ORIG_SESS=$(tmux display-message -p '#{session_name}')
    ORIG_WIN_ID=$(tmux display-message -p '#{window_id}')
    ORIG_WIN_NAME=$(tmux display-message -p '#{window_name}')

    tmux capture-pane -ep -t "$CURRENT_PANE" > /tmp/tmux-backdrop.ansi 2>/dev/null || true

    BACKDROP_WIN=$(tmux new-window -d -P -F '#{window_id}' -t "$ORIG_SESS" -n "$ORIG_WIN_NAME" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null")
    tmux select-window -t "$BACKDROP_WIN" 2>/dev/null || true

    tmux display-popup \
      -S "fg=${TMUX_POPUP_BORDER_COLOR:-default}" \
      -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
      -b rounded \
      -T " lazygitrs " \
      -d "$PROJECT_DIR" \
      -E \
      -y 28 \
      -w "85%" \
      -h "45%" \
      "tmux attach-session -t \"$SESSION_NAME:$WINDOW_NAME\""

    CURRENT_SESS=$(tmux display-message -p '#{session_name}')
    if [ "$CURRENT_SESS" = "$ORIG_SESS" ]; then
        tmux select-window -t "$ORIG_WIN_ID" 2>/dev/null || true
    fi
    tmux kill-window -t "$BACKDROP_WIN" 2>/dev/null || true
else
    exec tmux display-popup \
      -S "fg=${TMUX_POPUP_BORDER_COLOR:-default}" \
      -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
      -b rounded \
      -T " lazygitrs " \
      -d "$PROJECT_DIR" \
      -E \
      -y 28 \
      -w "85%" \
      -h "45%" \
      "tmux attach-session -t \"$SESSION_NAME:$WINDOW_NAME\""
fi
