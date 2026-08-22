#!/usr/bin/env sh
# window-picker.sh — cross-session window picker with OpenCode state using mm
# All sessions and their windows, grouped, with color-coded AI state and live preview.

REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || realpath "$0")

if [ "$1" = "--fullscreen" ]; then
  if ! [ -t 1 ]; then
    exec tmux split-window -Z "$REAL_SCRIPT" --fullscreen
  fi
elif [ -z "${TMUX_POPUP:-}" ]; then
  ORIG_SESS=$(tmux display-message -p '#{session_name}')
  ORIG_WIN=$(tmux display-message -p '#{window_index}')
  export TMUX_ORIGIN_SESSION="$ORIG_SESS"
  export TMUX_ORIGIN_WINDOW="$ORIG_WIN"

  AI_STATE=$(tmux display-message -p '#{@ai_agent_state_raw}')
  if [ "$AI_STATE" = "busy" ] || [ "$AI_STATE" = "working" ]; then
    CURRENT_PANE=$(tmux display-message -p '#{pane_id}')

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
      -E "TMUX_POPUP=1 TMUX_ORIGIN_SESSION='$ORIG_SESS' TMUX_ORIGIN_WINDOW='$ORIG_WIN' $REAL_SCRIPT"

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
      -E "TMUX_POPUP=1 TMUX_ORIGIN_SESSION='$ORIG_SESS' TMUX_ORIGIN_WINDOW='$ORIG_WIN' $REAL_SCRIPT"
  fi
fi

SCRIPT_DIR=$(dirname "$REAL_SCRIPT")
ITEMS_SCRIPT="${SCRIPT_DIR}/window-picker-items.sh"
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="${SCRIPT_DIR}/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style"
unset _tmux_style

# Extract the active spinner from acpd if available (tmux option or acpd config)
ACPD_SPINNER=$(tmux show-option -gqv @ai_agent_spinner 2>/dev/null)
[ -z "$ACPD_SPINNER" ] && ACPD_SPINNER=$(grep -E '^\s*active_spinner\s*=' "$HOME/.config/acpd/config.toml" 2>/dev/null | sed -E 's/.*=\s*"([^"]+)".*/\1/')
[ -n "$ACPD_SPINNER" ] && TMUX_SPINNER_NAME="$ACPD_SPINNER"

# Calculate the index of the current window for the initial selection
# We ignore group headers (lines starting with '#') and find the 0-based index of the row containing '•'
ORIG_SESS="${TMUX_ORIGIN_SESSION:-$(tmux display-message -p '#S')}"
ORIG_WIN="${TMUX_ORIGIN_WINDOW:-$(tmux display-message -p '#I')}"

START_IDX=$("$ITEMS_SCRIPT" "$ORIG_SESS" "$ORIG_WIN" | awk '!/^#/ {n++} /•/ {print n-1; exit}')
[ -z "$START_IDX" ] && START_IDX=0
MM_BIN="$HOME/.local/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$HOME/.cargo/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$(command -v mm 2>/dev/null || echo "mm")"

chosen=$("$ITEMS_SCRIPT" "$ORIG_SESS" "$ORIG_WIN" | "$MM_BIN" \
  -o "$SCRIPT_DIR/window-picker.toml" \
  "start.cmd=$ITEMS_SCRIPT $ORIG_SESS $ORIG_WIN" \
  results.spinner="$TMUX_SPINNER_NAME" \
  --pos "$START_IDX" \
  --color "spinner:$TMUX_SPINNER_COLOR" \
  --color "$TMUX_COLOR_SPEC" \
  --group-prefix '#')

if [ -n "$chosen" ]; then
  session=$(printf '%s' "$chosen" | head -n1 | cut -f4)
  idx=$(printf '%s' "$chosen" | head -n1 | cut -f2)
  if [ -n "$session" ] && [ -n "$idx" ]; then
    tmux switch-client -t "${session}:${idx}" 2>/dev/null || true
  fi
fi

exit 0
