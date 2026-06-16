#!/usr/bin/env sh
# sesh-picker-mm.sh - cross-session window picker using mm for sesh
# Replicates `sesh list` functionality with Matchmaker

if [ "$1" = "--fullscreen" ]; then
  if ! [ -t 1 ]; then
    exec tmux split-window -Z "$0" --fullscreen
  fi
elif [ -z "$TMUX_POPUP" ]; then
  exec tmux display-popup -b rounded -w 80% -h 70% -E "TMUX_POPUP=1 $0"
fi

SCRIPT_DIR=$(dirname "$0")

_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="${SCRIPT_DIR}/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style" 2>/dev/null || true
unset _tmux_style

sesh list --icons | ~/.cargo/bin/mm \
  -o "$SCRIPT_DIR/sesh-picker.toml" \
  results.spinner="${TMUX_SPINNER_NAME:-dot}" \
  --color "spinner:${TMUX_SPINNER_COLOR:-blue}" \
  --color "${TMUX_COLOR_SPEC:-}" \
  --nav \
  basic \
  no-filter \
  focus-on-start:picker \
| (read chosen && [ -n "$chosen" ] && sesh connect "$chosen"); true
