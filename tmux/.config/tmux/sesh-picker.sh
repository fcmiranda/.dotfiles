#!/usr/bin/env sh
# sesh-picker-mm.sh - cross-session window picker using mm for sesh
# Replicates `sesh list` functionality with Matchmaker

REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || realpath "$0")

if [ "$1" = "--fullscreen" ]; then
  if ! [ -t 1 ]; then
    echo "[$(date)] exec tmux split-window -Z $REAL_SCRIPT --fullscreen" >> /tmp/sesh-picker-mm.log
    exec tmux split-window -Z "$REAL_SCRIPT" --fullscreen
  fi
elif [ -z "${TMUX_POPUP:-}" ]; then
  echo "[$(date)] exec tmux display-popup -b rounded -w 80% -E \"TMUX_POPUP=1 $REAL_SCRIPT\"" >> /tmp/sesh-picker-mm.log
  exec tmux display-popup -b rounded -w 80% -h 35% -y 30 -E "TMUX_POPUP=1 $REAL_SCRIPT"
fi

SCRIPT_DIR=$(dirname "$REAL_SCRIPT")

_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="${SCRIPT_DIR}/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style" 2>/dev/null || true
unset _tmux_style

echo "[$(date)] sesh list --icons | mm -o $SCRIPT_DIR/sesh-picker.toml --color \"${TMUX_COLOR_SPEC:-}\"" >> /tmp/sesh-picker-mm.log

sesh list --icons | grep -Ev '(_lazygitrs|[[:space:]]+[._])' | ~/.cargo/bin/mm \
  -o "$SCRIPT_DIR/sesh-picker.toml" \
  --color "${TMUX_COLOR_SPEC:-}" \
| (read chosen && [ -n "$chosen" ] && sesh connect "$chosen"); true
