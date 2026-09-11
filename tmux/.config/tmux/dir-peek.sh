#!/usr/bin/env sh
# dir-peek.sh — browse workspace/origin pane's cwd in a popup via mm -o files.
# Invoke: prefix+e (or prefix+C-e) -> run-shell "dir-peek.sh '#{pane_id}' '#{pane_current_path}'"
# Enter copies the selected path(s) to the clipboard;
# Ctrl+V inserts the path directly into the origin pane (AI prompt);
# Ctrl+P / P cycles preview between 60% Golden Ratio and 95% Full-Modal view;
# Ctrl+E / e opens in $EDITOR. Popup closes on accept; copy tail detached.
set -u

LOG=/tmp/dir-peek.log

if [ -z "${TMUX_POPUP:-}" ]; then
  # Parse arguments with backwards compatibility
  if [ -n "${1:-}" ] && [ "${1#%}" != "$1" ]; then
    ORIGIN_ARG="$1"
    CWD_ARG="${2:-$HOME}"
    FULLSCREEN_ARG="${3:-}"
  else
    ORIGIN_ARG=""
    CWD_ARG="${1:-$HOME}"
    FULLSCREEN_ARG="${2:-}"
  fi

  BLUE=$(grep -E '^\s*blue\s*=' "$HOME/.local/state/omarchy/current/theme/colors.toml" 2>/dev/null | sed -E 's/.*=\s*"([^"]+)".*/\1/')
  [ -n "$BLUE" ] || BLUE="#89b4fa"

  WIDTH="75%"
  HEIGHT="60%"
  if [ "$FULLSCREEN_ARG" = "--fullscreen" ]; then
    WIDTH="95%"
    HEIGHT="90%"
  fi

  popup_cmd() {
    tmux display-popup \
      -S "fg=$BLUE" \
      -s "fg=default" \
      -b rounded \
      -T " 󰈞 " \
      -w "$WIDTH" -h "$HEIGHT" \
      -E "TMUX_POPUP=1 $0 '$ORIGIN_ARG' '$CWD_ARG' '$FULLSCREEN_ARG'"
  }

  AI_STATE=$(tmux display-message -p '#{@ai_agent_state_raw}' 2>/dev/null || true)
  if [ "$AI_STATE" = "busy" ] || [ "$AI_STATE" = "working" ]; then
    CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
    ORIG_SESS=$(tmux display-message -p '#{session_name}')
    tmux capture-pane -ep -t "$CURRENT_PANE" > /tmp/tmux-backdrop.ansi 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename off 2>/dev/null || true
    BACKDROP_PANE=$(tmux split-window -d -P -F '#{pane_id}' -t "$CURRENT_PANE" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null")
    tmux select-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux resize-pane -Z 2>/dev/null || true
    popup_cmd
    tmux kill-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename on 2>/dev/null || true
    CURRENT_SESS=$(tmux display-message -p '#{session_name}')
    if [ "$CURRENT_SESS" = "$ORIG_SESS" ]; then
      tmux select-pane -t "$CURRENT_PANE" 2>/dev/null || true
    fi
    exit 0
  else
    popup_cmd
    exit 0
  fi
fi

[ -n "${TMUX:-}" ] || { echo "dir-peek: fora do tmux" >&2; exit 1; }
ORIGIN="${1:-}"
if [ -z "$ORIGIN" ]; then
  ORIGIN="$(tmux display-message -p -t '{last}' '#{pane_id}' 2>/dev/null || true)"
fi
CWD="${2:-$HOME}"
[ -d "$CWD" ] || { tmux display-message "dir-peek: sem diretório: $CWD"; exit 1; }

export MM_ORIGIN_PANE="$ORIGIN"
export MM_ORIGIN_CWD="$CWD"

MM_BIN="$HOME/.local/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$HOME/.cargo/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$(command -v mm 2>/dev/null || echo mm)"

# Prefer dedicated files preset (with 60%/95% layouts and ctrl-v insert), fallback to jump
if "$MM_BIN" --dump-config -o files >/dev/null 2>&1; then
  PRESET="files"
else
  PRESET="jump"
fi

chosen="$(cd "$CWD" && "$MM_BIN" -o "$PRESET")" || exit 0
[ -n "$chosen" ] || exit 0

trap '' HUP
{
  echo "$(date '+%T') mm files exited, copying paths"
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$chosen" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$chosen" | xclip -in -selection clipboard
  else
    printf '%s' "$chosen" | tmux load-buffer -
  fi
  n="$(printf '%s' "$chosen" | wc -l)"
  tmux display-message "copiado ($n): $(printf '%s' "$chosen" | head -n 1)"
} >>"$LOG" 2>&1 </dev/null &
exit 0
