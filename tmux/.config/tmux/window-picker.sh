#!/usr/bin/env sh
# window-picker.sh — cross-session window picker with OpenCode state
# All sessions and their windows, grouped, with color-coded AI state and live preview.

# ── Gruvbox Material ANSI palette ────────────────────────────────────────────
R='\033[0m'         # reset
BOLD='\033[1m'
C_SESSION='\033[1;38;2;125;174;163m'   # #7daea3  teal  — session header
C_CURMARK='\033[38;2;216;166;87m'      # #d8a657  gold  — current window dot
C_DIMMARK='\033[38;2;80;73;69m'        # #504945  dim   — inactive dot
C_BUSY='\033[38;2;216;166;87m'         # #d8a657  yellow
C_IDLE='\033[38;2;137;180;130m'        # #89b482  green
C_QUESTION='\033[38;2;125;174;163m'    # #7daea3  cyan
C_RETRY='\033[38;2;231;138;78m'        # #e78a4e  orange
C_PERM='\033[38;2;234;105;98m'         # #ea6962  red
C_IDX='\033[38;2;146;131;116m'         # #928374  mid-gray index
C_NAME='\033[38;2;212;190;152m'        # #d4be98  foreground name
C_SEP='\033[38;2;60;56;54m'            # #3c3836  dim separator rule
# ─────────────────────────────────────────────────────────────────────────────

cur_session=$(tmux display-message -p '#S')
cur_window=$(tmux display-message -p '#I')

tmpfile=$(mktemp)

tmux list-sessions -F '#S' | while IFS= read -r session; do
  # ── Session header ─────────────────────────────────────────────────────────
  # Fields: SESSION <TAB> (empty index) <TAB> display
  # We pad the session name into a full-width rule so it reads like a section title.
  header_display="${C_SESSION}${BOLD}  ${session}${R}"
  printf '%s\t\t%b\n' "$session" "$header_display" >> "$tmpfile"

  # ── Windows in this session ────────────────────────────────────────────────
  tmux list-windows -t "$session" \
      -F '#{window_index}	#{window_name}	#{@opencode_state_raw}' \
    | while IFS='	' read -r idx name state; do

    case "$state" in
      busy)       si="${C_BUSY}⣾ ${R}"  ;;
      idle)       si="${C_IDLE}󱥂 ${R}"  ;;
      question)   si="${C_QUESTION}󱜻 ${R}"  ;;
      retry)      si="${C_RETRY}󰨄 ${R}"  ;;
      permission) si="${C_PERM}󱅭 ${R}"   ;;
      *)          si="   "               ;;
    esac

    if [ "$session" = "$cur_session" ] && [ "$idx" = "$cur_window" ]; then
      mark="${C_CURMARK}●${R}"
    else
      mark="${C_DIMMARK}·${R}"
    fi

    display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${si}"
    printf '%s\t%s\t%b\n' "$session" "$idx" "$display" >> "$tmpfile"
  done

done

chosen=$(fzf \
  --ansi \
  --no-sort \
  --delimiter='	' \
  --with-nth=3 \
  --no-input \
  --pointer="▸ " \
  --no-separator \
  --no-scrollbar \
  --layout=reverse \
  --no-border \
  --padding="0,1" \
  --info=hidden \
  --color="bg+:#3c3836,border:#504945,label:#7daea3,pointer:#d8a657,hl:#d8a657,hl+:#d8a657,header:#928374,separator:#3c3836,gutter:#1d2021" \
  --bind='enter:transform([ -n "{2}" ] && echo "accept" || echo "down")' \
  --preview='
    sess={1}; idx={2}
    [ -z "$idx" ] && {
      printf "\n  \033[1;38;2;125;174;163m%s\033[0m\n\n" "$sess"
      tmux list-windows -t "$sess" -F "  #{window_index}  #{window_name}  #{@opencode_state_raw}" 2>/dev/null
      exit 0
    }
    tmux capture-pane -ep -t "${sess}:${idx}" 2>/dev/null || printf "  \033[38;2;146;131;116m(no preview)\033[0m\n"
  ' \
  --preview-window='right:50%:wrap:border-left' \
  < "$tmpfile")

rm -f "$tmpfile"
[ -z "$chosen" ] && exit 0

# Extract session and window index from tab-delimited fields
session=$(printf '%s' "$chosen" | cut -f1)
idx=$(printf '%s' "$chosen" | cut -f2)

# Skip header/separator lines (empty index)
[ -z "$idx" ] && exit 0

tmux switch-client -t "${session}:${idx}"
