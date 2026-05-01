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
# Spinner prefix sentinel — lines starting with this are animated by bfzf.
# Must not appear in any other line content.
SPIN_PFX='@SPIN@'
# ─────────────────────────────────────────────────────────────────────────────

cur_session=$(tmux display-message -p '#S')
cur_window=$(tmux display-message -p '#I')

tmpfile=$(mktemp)

tmux list-sessions -F '#S' | while IFS= read -r session; do
  # ── Session header (bfzf group-prefix '#') ──────────────────────────────────
  printf '#%b%b  %s%b\n' "$C_SESSION" "$BOLD" "$session" "$R" >> "$tmpfile"

  # ── Windows in this session ────────────────────────────────────────────────
  # Format: SESSION<TAB>IDX<TAB>DISPLAY
  # bfzf --with-nth 3  shows only the DISPLAY column in the list.
  # Preview uses {1}=SESSION, {2}=IDX via tab-field expansion.
  tmux list-windows -t "$session" \
      -F '#{window_index}	#{window_name}	#{@opencode_state_raw}' \
    | while IFS='	' read -r idx name state; do

    if [ "$session" = "$cur_session" ] && [ "$idx" = "$cur_window" ]; then
      mark="${C_CURMARK}●${R}"
    else
      mark="${C_DIMMARK}·${R}"
    fi

    case "$state" in
      busy)
        # Embed \001 (SpinnerPlaceholder) at the si position (right of name),
        # matching where idle/question/etc icons appear. Restore the mark too.
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} $(printf '\001')"
        printf '%s%s\t%s\t%b\n' "$SPIN_PFX" "$session" "$idx" "$display" >> "$tmpfile"
        ;;
      idle)       si="${C_IDLE}󱥂 ${R}"
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${si}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display" >> "$tmpfile"
        ;;
      question)   si="${C_QUESTION}󱜻 ${R}"
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${si}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display" >> "$tmpfile"
        ;;
      retry)      si="${C_RETRY}󰨄 ${R}"
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${si}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display" >> "$tmpfile"
        ;;
      permission) si="${C_PERM}󱅭 ${R}"
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${si}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display" >> "$tmpfile"
        ;;
      *)
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R}    "
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display" >> "$tmpfile"
        ;;
    esac
  done

done

chosen=$(/home/fecavmi/go/bin/bfzf \
  -popup center,80%,55% \
  -group-prefix '#' \
  -spinner-prefix "$SPIN_PFX" \
  -with-nth 3 \
  -no-sort \
  -no-input \
  --height 90% \
  -header='↑↓ navigate  •  Enter switch  •  Esc cancel' \
  -cursor="▸ " \
  -no-info \
  -color="border:239,header:245,cursor:214,fg+:223" \
  -preview='
    sess={1}; idx={2}
    tmux capture-pane -ep -t "${sess}:${idx}" 2>/dev/null \
      || printf "  \033[38;2;146;131;116m(no preview)\033[0m\n"
  ' \
  -preview-position='right' \
  -preview-size=50 \
  < "$tmpfile")

rm -f "$tmpfile"
[ -z "$chosen" ] && exit 0

# Extract session and window index from tab-delimited fields
session=$(printf '%s' "$chosen" | cut -f1)
idx=$(printf '%s' "$chosen" | cut -f2)

[ -z "$idx" ] && exit 0

tmux switch-client -t "${session}:${idx}"
