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
      -w 80% -h 35% -y 34 \
      -E "TMUX_POPUP=1 $REAL_SCRIPT"

    tmux kill-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename on 2>/dev/null || true
    CURRENT_SESS=$(tmux display-message -p '#{session_name}')
    if [ "$CURRENT_SESS" = "$ORIG_SESS" ]; then
      tmux select-pane -t "$CURRENT_PANE" 2>/dev/null || true
    fi
    exit 0
  else
    exec tmux display-popup \
      -S "fg=${TMUX_POPUP_BORDER_COLOR:-default}" \
      -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
      -b rounded \
      -w 80% -h 35% -y 34 \
      -E "TMUX_POPUP=1 $REAL_SCRIPT"
  fi
fi

SCRIPT_DIR=$(dirname "$REAL_SCRIPT")

_tmux_style="$HOME/.local/state/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="${SCRIPT_DIR}/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style" 2>/dev/null || true
unset _tmux_style

MM_BIN="$HOME/.local/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$HOME/.cargo/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$(command -v mm 2>/dev/null || echo "mm")"

sesh list --icons | grep -Ev '(_lazygitrs|_popups|[[:space:]]+\.)' | "$MM_BIN" \
  -o "$SCRIPT_DIR/sesh-picker.toml" \
  --color "${TMUX_COLOR_SPEC:-}" \
| (read chosen && [ -n "$chosen" ] && sesh connect "$chosen"); true
