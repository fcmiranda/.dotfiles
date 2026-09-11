#!/usr/bin/env sh
# scrollback-extract.sh — extrakto-style token copy/insert from tmux scrollback via mm.
# Invoke: prefix+y -> run-shell "scrollback-extract.sh '#{pane_id}'" (origin pane!).
# Wrapper opens a themed popup (sesh-picker pattern, golden 75%x60%); inside,
# the ORIGIN pane is captured explicitly, one token file per filter plus the
# full text (preview context) is precomputed, the all-list is piped to mm,
# and the clipboard tail runs detached so the popup closes on Enter.
set -u

SRC=/tmp/scrollback-extract-src.txt
TOK_ALL=/tmp/scrollback-extract-all.txt
TOK_URL=/tmp/scrollback-extract-url.txt
TOK_PATH=/tmp/scrollback-extract-path.txt
TOK_SHA=/tmp/scrollback-extract-sha.txt
LOG=/tmp/scrollback-mm.log

popup_cmd() {
  # $1 = border color; origin pane travels via ORIGIN_ARG.
  tmux display-popup \
    -S "fg=$1" \
    -s "fg=default" \
    -b rounded \
    -T " 󰅍 " \
    -w 75% -h 60% \
    -E "TMUX_POPUP=1 $0 '$ORIGIN_ARG' '$CWD_ARG'"
}

if [ -z "${TMUX_POPUP:-}" ]; then
  ORIGIN_ARG="${1:-}"
  CWD_ARG="${2:-}"
  GREEN=$(grep -E '^\s*green\s*=' "$HOME/.local/state/omarchy/current/theme/colors.toml" 2>/dev/null | sed -E 's/.*=\s*"([^"]+)".*/\1/')
  [ -n "$GREEN" ] || GREEN="#a6e3a1"
  # Issue B (docs/tmux/popup-isolation-and-debounce.md): a streaming background
  # pane redraws over the popup's top border. When an agent is busy, open over
  # a frozen snapshot backdrop instead (window-picker.sh pattern).
  AI_STATE=$(tmux display-message -p '#{@ai_agent_state_raw}' 2>/dev/null || true)
  if [ "$AI_STATE" = "busy" ] || [ "$AI_STATE" = "working" ]; then
    CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
    ORIG_SESS=$(tmux display-message -p '#{session_name}')
    tmux capture-pane -ep -t "$CURRENT_PANE" > /tmp/tmux-backdrop.ansi 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename off 2>/dev/null || true
    BACKDROP_PANE=$(tmux split-window -d -P -F '#{pane_id}' -t "$CURRENT_PANE" "cat /tmp/tmux-backdrop.ansi; tail -f /dev/null")
    tmux select-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux resize-pane -Z 2>/dev/null || true
    popup_cmd "$GREEN"
    tmux kill-pane -t "$BACKDROP_PANE" 2>/dev/null || true
    tmux set-option -w -t "$CURRENT_PANE" automatic-rename on 2>/dev/null || true
    CURRENT_SESS=$(tmux display-message -p '#{session_name}')
    if [ "$CURRENT_SESS" = "$ORIG_SESS" ]; then
      tmux select-pane -t "$CURRENT_PANE" 2>/dev/null || true
    fi
    exit 0
  else
    popup_cmd "$GREEN"
    exit 0
  fi
fi

[ -n "${TMUX:-}" ] || { echo "scrollback-extract: fora do tmux" >&2; exit 1; }
ORIGIN="${1:-}"
if [ -z "$ORIGIN" ]; then
  ORIGIN="$(tmux display-message -p -t '{last}' '#{pane_id}' 2>/dev/null || true)"
fi
export MM_ORIGIN_PANE="$ORIGIN"
export MM_ORIGIN_CWD="${2:-}"

MM_BIN="$HOME/.local/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$HOME/.cargo/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$(command -v mm 2>/dev/null || echo mm)"

P_URL='https?://[^[:space:]"'"'"'<>]+|git@[^[:space:]"'"'"'<>]+'
P_PATH='(~?/[A-Za-z0-9._~:/?#@!$&()*+,;=%-]+|\./[A-Za-z0-9._~:/?#@!$&()*+,;=%-]+)'
P_SHA='\b[0-9a-f]{7,40}\b|\b[0-9]{1,3}(\.[0-9]{1,3}){3}(:[0-9]+)?\b'
dedup_rev() { awk '!seen[$0]++ && length($0)>2 { lines[n++]=$0 } END { for (i=n-1;i>=0;i--) print lines[i] }'; }

if ! tmux capture-pane -pJS - -t "$ORIGIN" 2>/dev/null | sed '/^$/d' > "$SRC"; then
  tmux display-message "scrollback: capture-pane falhou ($ORIGIN)"
  exit 1
fi
grep -oE "$P_URL|$P_PATH|$P_SHA" "$SRC" | dedup_rev > "$TOK_ALL"
grep -oE "$P_URL" "$SRC" | dedup_rev > "$TOK_URL"
grep -oE "$P_PATH" "$SRC" | dedup_rev > "$TOK_PATH"
grep -oE "$P_SHA" "$SRC" | dedup_rev > "$TOK_SHA"

if [ ! -s "$TOK_ALL" ]; then
  tmux display-message "scrollback: nada extraível (URL/path/hash/IP)"
  exit 0
fi

# Items come from [start] command (file), never from a pipe: mm reads keyboard
# from stdin via crossterm, so stdin must stay on the tty or no key works.
chosen="$("$MM_BIN" -o scrollback)" || exit 0
[ -n "$chosen" ] || exit 0

# Clipboard + confirm run detached from the popup: the popup must close the
# instant Enter is pressed, even if wl-copy/display-message ever blocks, and
# the tail must survive popup teardown (ignore HUP, no tty stdin).
trap '' HUP
{
  echo "$(date '+%T') mm exited, copying $(printf '%s' "$chosen" | wc -c) bytes"
  if command -v wl-copy >/dev/null 2>&1; then
    printf '%s' "$chosen" | wl-copy
  elif command -v xclip >/dev/null 2>&1; then
    printf '%s' "$chosen" | xclip -in -selection clipboard
  else
    printf '%s' "$chosen" | tmux load-buffer -
  fi
  echo "$(date '+%T') clipboard rc=$?"
  tmux display-message "yanked: $chosen"
  echo "$(date '+%T') done"
} >>"$LOG" 2>&1 </dev/null &
exit 0
