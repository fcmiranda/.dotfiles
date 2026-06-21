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

# Extract the active spinner from acpd if available (acpd sets this on startup)
ACPD_SPINNER=$(tmux show-option -gv @ai_agent_spinner 2>/dev/null)
[ -n "$ACPD_SPINNER" ] && TMUX_SPINNER_NAME="$ACPD_SPINNER"

# Calculate the index of the current window for the initial selection
# We ignore group headers (lines starting with '#') and find the 0-based index of the row containing '•'
START_IDX=$("$ITEMS_SCRIPT" | awk '!/^#/ {n++} /•/ {print n-1; exit}')
[ -z "$START_IDX" ] && START_IDX=0

"$ITEMS_SCRIPT" | ~/.cargo/bin/mm \
  -o "$SCRIPT_DIR/window-picker.toml" \
  "start.cmd=$ITEMS_SCRIPT" \
  results.spinner="$TMUX_SPINNER_NAME" \
  binds.Synced="Pos($START_IDX)|||Unbind(Synced)" \
  --color "spinner:$TMUX_SPINNER_COLOR" \
  --color "$TMUX_COLOR_SPEC" \
  --group-prefix '#' \
| (read chosen && [ -n "$chosen" ] && \
    session=$(printf '%s' "$chosen" | cut -f4) && \
    idx=$(printf '%s' "$chosen" | cut -f2) && \
    [ -n "$idx" ] && \
    tmux switch-client -t "${session}:${idx}"); true
