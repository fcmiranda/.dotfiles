#!/usr/bin/env bash
PROJECT_DIR="$1"
SESSION_NAME="lzg-$(echo -n "$PROJECT_DIR" | md5sum | cut -d' ' -f1 | head -c 8)"

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style" 2>/dev/null || true
unset _tmux_style

if ! tmux has-session -t "$SESSION_NAME" 2>/dev/null; then
    tmux new-session -d -s "$SESSION_NAME" -c "$PROJECT_DIR" '~/.cargo/bin/lazygitrs -d -c popup'
    tmux set-option -t "$SESSION_NAME" status off
fi

tmux display-popup \
  -S "fg=${TMUX_POPUP_BORDER_COLOR:-default}" \
  -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
  -b rounded \
  -T " lazygitrs " \
  -d "$PROJECT_DIR" \
  -E \
  -w "${TMUX_POPUP_WIDTH:-90%}" \
  -h "${TMUX_POPUP_HEIGHT:-90%}" \
  "tmux attach-session -t \"$SESSION_NAME\""
