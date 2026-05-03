#!/usr/bin/env sh
# window-picker-items.sh — emit the bfzf item list for window-picker.sh
# Called both at startup (piped to bfzf stdin) and periodically via -reload-cmd.
# Output format:
#   Group headers : #<ANSI session name>
#   Window rows   : @SPIN@SESSION<TAB>IDX<TAB>DISPLAY  (busy)
#                   SESSION<TAB>IDX<TAB>DISPLAY         (others)

# ── Theme palette (read live from tmux @options set by tmux-colors.conf) ─────
# Helper: read a tmux global option value.
_tget() { tmux show-option -gqv "$1" 2>/dev/null; }

# Convert a #RRGGBB hex color to an ANSI truecolor escape prefix (no reset).
# Usage: _hex_esc "#89b4fa"  →  '\033[38;2;137;180;250m'
_hex_esc() {
  _h="${1#\#}"
  _r=$(( 16#${_h%????} ))
  _g=$(( 16#${_h#??} )); _g=$(( _g >> 8 & 0xFF ))
  _b=$(( 16#${_h##????} ))
  printf '\\033[38;2;%d;%d;%dm' "$_r" "$_g" "$_b"
}

R='\033[0m'
BOLD='\033[1m'
# @SESSION_COLOR  → color4  (blue)       — session group header
# @ACCENT_COLOR   → accent  (blue)       — current-window marker / cursor mark
# @SEGMENT_BG     → color8  (surface1)   — dim marker / index
# @CURRENT_COLOR  → color14 (teal)       — idle AI state
# @PREFIX_COLOR   → color13 (mauve/pink) — question AI state
# @FG             → foreground           — window name text
# color11 (yellow) and color1 (red) not in @options: read colors.toml directly
_colors_toml="$HOME/.config/omarchy/current/theme/colors.toml"
_color11=$(grep '^color11' "$_colors_toml" 2>/dev/null | sed 's/.*= *"\(.*\)"/\1/')
_color1=$(grep '^color1 ' "$_colors_toml" 2>/dev/null | sed 's/.*= *"\(.*\)"/\1/')
[ -z "$_color11" ] && _color11="#f9e2af"  # catppuccin yellow fallback
[ -z "$_color1"  ] && _color1="#f38ba8"   # catppuccin red fallback

C_SESSION=$(printf '\033[1m'; _hex_esc "$(_tget @SESSION_COLOR)")
C_CURMARK=$(_hex_esc "$(_tget @ACCENT_COLOR)")
C_DIMMARK=$(_hex_esc "$(_tget @SEGMENT_BG)")
C_IDLE=$(_hex_esc "$(_tget @CURRENT_COLOR)")
C_QUESTION=$(_hex_esc "$(_tget @PREFIX_COLOR)")
C_RETRY=$(_hex_esc "$_color11")
C_PERM=$(_hex_esc "$_color1")
C_IDX=$(_hex_esc "$(_tget @SEGMENT_BG)")
C_NAME=$(_hex_esc "$(_tget @FG)")

unset -f _tget _hex_esc
unset _colors_toml _color11 _color1
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
        display="   ${mark} ${C_IDX}${idx}${R}  ${C_NAME}${name}${R} $(printf '\001')"
        printf '@SPIN@%s\t%s\t%b\n' "$session" "$idx" "$display"
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
