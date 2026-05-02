#!/usr/bin/env bash

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style"
unset _tmux_style

pane=$(tmux show -gv @opencode_last_bell 2>/dev/null)

if [ -z "$pane" ]; then
  tmux display-popup \
    -b rounded \
    -S "fg=$TMUX_POPUP_BORDER_COLOR" \
    -T " No OpenCode notification " \
    -w 38 -h 5 \
    "printf '\n  No OpenCode notification yet.\n'; sleep 2"
  exit 0
fi

sess=$(tmux display-message -t "$pane" -p '#S' 2>/dev/null)
win_idx=$(tmux display-message -t "$pane" -p '#I' 2>/dev/null)
win_name=$(tmux display-message -t "$pane" -p '#W' 2>/dev/null)

TITLE=" $sess › $win_name  │  prefix+q close"

# If current client is already on the same session, jump directly to the window.
current_sess=$(tmux display-message -p '#S' 2>/dev/null)
if [ "$current_sess" = "$sess" ]; then
  tmux select-window -t "$sess:$win_idx"
  tmux select-pane -t "$pane" 2>/dev/null
  exit 0
fi

tmux popup \
  -S "fg=$TMUX_POPUP_BORDER_COLOR" \
  -s "fg=$TMUX_POPUP_TEXT_COLOR" \
  -T "$TITLE" \
  -w "$TMUX_POPUP_WIDTH" \
  -h "$TMUX_POPUP_HEIGHT" \
  -b rounded \
  -E \
  "tmux set-option -t \"$sess\" status off >/dev/null 2>&1; tmux attach-session -t \"$sess:$win_idx\"; tmux set-option -t \"$sess\" status on >/dev/null 2>&1"
