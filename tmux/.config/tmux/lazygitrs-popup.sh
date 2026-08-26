#!/usr/bin/env bash
PROJECT_DIR="$1"

if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1; then
    tmux display-message "Not in a git repository"
    exit 0
fi

WINDOW_NAME="lzg-$(echo -n "$PROJECT_DIR" | md5sum | cut -d' ' -f1 | head -c 8)"
SESSION_NAME="_popups"


SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.local/state/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style" 2>/dev/null || true
unset _tmux_style

# Create session if it doesn't exist, otherwise add a window if needed
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -n "$WINDOW_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
    tmux set-option -t "$SESSION_NAME" status off 2>/dev/null || true
    tmux set-option -w -t "$SESSION_NAME" status off 2>/dev/null || true
else
    tmux set-option -t "$SESSION_NAME" status off 2>/dev/null || true
    tmux set-option -w -t "$SESSION_NAME" status off 2>/dev/null || true
    if ! tmux list-windows -t "$SESSION_NAME" -F '#W' 2>/dev/null | grep -q "^${WINDOW_NAME}$"; then
        tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
    fi
fi

AI_STATE=$(tmux display-message -p '#{@ai_agent_state_raw}')
if [ "$AI_STATE" = "busy" ] || [ "$AI_STATE" = "working" ]; then
    CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
    ORIG_SESS=$(tmux display-message -p '#{session_name}')

    tmux capture-pane -ep -t "$CURRENT_PANE" > /tmp/tmux-backdrop.ansi 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename off 2>/dev/null || true

    BACKDROP_PANE=$(tmux split-window -d -P -F '#{pane_id}' -t "$CURRENT_PANE" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null")
    tmux select-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux resize-pane -Z 2>/dev/null || true

    tmux display-popup \
      -S "fg=${TMUX_POPUP_BORDER_COLOR:-default}" \
      -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
      -b rounded \
      -d "$PROJECT_DIR" \
      -E \
      -w 90% -h 88% \
      "tmux attach-session -t \"$SESSION_NAME:$WINDOW_NAME\""

    tmux kill-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename on 2>/dev/null || true
    CURRENT_SESS=$(tmux display-message -p '#{session_name}')
    if [ "$CURRENT_SESS" = "$ORIG_SESS" ]; then
        tmux select-pane -t "$CURRENT_PANE" 2>/dev/null || true
    fi
else
    exec tmux display-popup \
      -S "fg=${TMUX_POPUP_BORDER_COLOR:-default}" \
      -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
      -b rounded \
      -d "$PROJECT_DIR" \
      -E \
      -w 90% -h 88% \
      "tmux attach-session -t \"$SESSION_NAME:$WINDOW_NAME\""
fi
