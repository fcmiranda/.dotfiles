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

CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
ORIG_TARGET=$(tmux display-message -p '#{session_name}:#{window_index}')
tmux capture-pane -ep -t "$CURRENT_PANE" > /tmp/tmux-backdrop.ansi 2>/dev/null || true

# Create session if it doesn't exist, otherwise add a window if needed
if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -n "backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
    tmux set-option -t "$SESSION_NAME" status off
else
    if ! tmux list-windows -t "$SESSION_NAME" -F '#W' 2>/dev/null | grep -q "^backdrop$"; then
        tmux new-window -d -t "$SESSION_NAME" -n "backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    else
        tmux respawn-window -k -t "$SESSION_NAME:backdrop" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null"
    fi
    if ! tmux list-windows -t "$SESSION_NAME" -F '#W' 2>/dev/null | grep -q "^${WINDOW_NAME}$"; then
        tmux new-window -t "$SESSION_NAME" -n "$WINDOW_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
    fi
fi
tmux set-option -t "$SESSION_NAME" status off

tmux switch-client -t "$SESSION_NAME:backdrop" 2>/dev/null || true

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

tmux switch-client -t "$ORIG_TARGET" 2>/dev/null || true
