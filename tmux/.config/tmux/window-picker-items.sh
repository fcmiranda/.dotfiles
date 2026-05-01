#!/usr/bin/env sh
# window-picker-items.sh — emit the bfzf item list for window-picker.sh
# Called both at startup (piped to bfzf stdin) and periodically via -reload-cmd.
# Output format:
#   Group headers : #<ANSI session name>
#   Window rows   : @SPIN@SESSION<TAB>IDX<TAB>DISPLAY  (busy)
#                   SESSION<TAB>IDX<TAB>DISPLAY         (others)

# ── Gruvbox Material ANSI palette ────────────────────────────────────────────
R='\033[0m'
BOLD='\033[1m'
C_SESSION='\033[1;38;2;125;174;163m'
C_CURMARK='\033[38;2;216;166;87m'
C_DIMMARK='\033[38;2;80;73;69m'
C_IDLE='\033[38;2;137;180;130m'
C_QUESTION='\033[38;2;125;174;163m'
C_RETRY='\033[38;2;231;138;78m'
C_PERM='\033[38;2;234;105;98m'
C_IDX='\033[38;2;146;131;116m'
C_NAME='\033[38;2;212;190;152m'
SPIN_PFX='@SPIN@'
# ─────────────────────────────────────────────────────────────────────────────

cur_session=$(tmux display-message -p '#S')
cur_window=$(tmux display-message -p '#I')

tmux list-sessions -F '#S' | while IFS= read -r session; do
  printf '#%b%b  %s%b\n' "$C_SESSION" "$BOLD" "$session" "$R"

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
        # \001 = SpinnerPlaceholder — bfzf animates it at that column position
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} $(printf '\001')"
        printf '%s%s\t%s\t%b\n' "$SPIN_PFX" "$session" "$idx" "$display"
        ;;
      idle)
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${C_IDLE}󱥂 ${R}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display"
        ;;
      question)
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${C_QUESTION}󱜻 ${R}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display"
        ;;
      retry)
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${C_RETRY}󰨄 ${R}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display"
        ;;
      permission)
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} ${C_PERM}󱅭 ${R}"
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display"
        ;;
      *)
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R}    "
        printf '%s\t%s\t%b\n' "$session" "$idx" "$display"
        ;;
    esac
  done
done
