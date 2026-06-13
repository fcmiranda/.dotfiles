#!/usr/bin/env sh
# window-picker-mm.sh — cross-session window picker with OpenCode state using mm
# All sessions and their windows, grouped, with color-coded AI state and live preview.

if [ "$1" = "--fullscreen" ]; then
  if ! [ -t 1 ]; then
    exec tmux split-window -Z "$0" --fullscreen
  fi
elif [ -z "$TMUX_POPUP" ]; then
  exec tmux display-popup -b rounded -w 80% -h 55% -E "TMUX_POPUP=1 $0"
fi

SCRIPT_DIR=$(dirname "$0")
ITEMS_SCRIPT="${SCRIPT_DIR}/window-picker-items.sh"
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="${SCRIPT_DIR}/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style"
unset _tmux_style

"$ITEMS_SCRIPT" | ~/.cargo/bin/mm \
  -o "$SCRIPT_DIR/window-picker.toml" \
  "start.cmd=$ITEMS_SCRIPT" \
  results.spinner="$TMUX_SPINNER_NAME" \
  --color "spinner:$TMUX_SPINNER_COLOR" \
  --color "$TMUX_COLOR_SPEC" \
  --group-prefix '#' \
  --nav \
  basic \
  no-filter \
  focus-on-start:picker \
| (read chosen && [ -n "$chosen" ] && \
    session=$(printf '%s' "$chosen" | cut -f4) && \
    idx=$(printf '%s' "$chosen" | cut -f2) && \
    [ -n "$idx" ] && \
    tmux switch-client -t "${session}:${idx}"); true
