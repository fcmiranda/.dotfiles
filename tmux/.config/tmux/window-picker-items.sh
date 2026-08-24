#!/usr/bin/env bash
# window-picker-items.sh — emit the item list for window-picker.sh

# ── Theme palette (read live from tmux @options set by tmux-colors.conf) ─────
# Helper: read a tmux global option value.
_tget() { tmux show-option -gqv "$1" 2>/dev/null; }

# Convert a #RRGGBB hex color to an ANSI truecolor escape prefix (no reset).
# Usage: _hex_esc "#89b4fa"  →  '\033[38;2;137;180;250m'
_hex_esc() {
  local h="${1#\#}"
  if [[ ! "$h" =~ ^[0-9a-fA-F]{6}$ ]]; then
    h="89b4fa"
  fi
  local r=$(( 16#${h:0:2} ))
  local g=$(( 16#${h:2:2} ))
  local b=$(( 16#${h:4:2} ))
  printf '\033[38;2;%d;%d;%dm' "$r" "$g" "$b"
}

R='\033[0m'
BOLD='\033[1m'
# @SESSION_COLOR  → color4  (blue)       — session group header
# @CURRENT_COLOR  → color14 (teal)       — current-window marker / cursor mark / idle AI state
# @SEGMENT_BG     → color8  (surface1)   — dim marker / index
# @CURRENT_COLOR  → color14 (teal)       — idle AI state
# @PREFIX_COLOR   → color13 (mauve/pink) — question AI state
# @FG             → foreground           — window name text
# color11 (yellow) and color1 (red) not in @options: read colors.toml directly
_colors_toml="$HOME/.local/state/omarchy/current/theme/colors.toml"
_color11=$(grep '^color11' "$_colors_toml" 2>/dev/null | sed 's/.*= *"\(.*\)"/\1/')
_color1=$(grep '^color1 ' "$_colors_toml" 2>/dev/null | sed 's/.*= *"\(.*\)"/\1/')
[ -z "$_color11" ] && _color11="#f9e2af"  # catppuccin yellow fallback
[ -z "$_color1"  ] && _color1="#f38ba8"   # catppuccin red fallback

C_SESSION=$(printf '\033[1m'; _hex_esc "$(_tget @SESSION_COLOR)")
C_CURMARK=$(_hex_esc "$(_tget @CURRENT_COLOR)")
C_DIMMARK=$(_hex_esc "$(_tget @SEGMENT_BG)")
C_IDLE=$(_hex_esc "$(_tget @CURRENT_COLOR)")
C_QUESTION=$(_hex_esc "$(_tget @PREFIX_COLOR)")
C_BUSY=$(_hex_esc "$_color11")
C_PERM=$(_hex_esc "$_color1")
C_ERROR=$(_hex_esc "$_color1")
C_IDX=$(_hex_esc "$(_tget @SEGMENT_BG)")
C_NAME=$(_hex_esc "$(_tget @FG)")

unset -f _tget
unset _colors_toml _color11 _color1
# ─────────────────────────────────────────────────────────────────────────────

cur_session="${1:-${TMUX_ORIGIN_SESSION:-$(tmux display-message -p '#S')}}"
cur_window="${2:-${TMUX_ORIGIN_WINDOW:-$(tmux display-message -p '#I')}}"

tmux list-sessions -F '#S' | grep -Ev '^(_lazygitrs|_popups|\.)' | while IFS= read -r session; do
  printf '#  %s\n' "$session"

  tmux list-windows -t "$session" \
      -F '#{window_index}|#{window_name}|#{@ai_agent_state_raw}|#{@ai_agent_state}|#{@ai_agent_state_color}' \
    | while IFS='|' read -r idx name state state_icon state_color; do

    case "$name" in
      _lazygitrs*|_popups*|\.*) continue ;;
    esac

    if [ "$session" = "$cur_session" ] && [ "$idx" = "$cur_window" ]; then
      mark="${C_CURMARK}•${R}"
      c_cur_name="${BOLD}${C_CURMARK}"
    else
      mark="${C_DIMMARK}·${R}"
      c_cur_name="$C_NAME"
    fi

    # Determine state color
    c_st=""
    if [ -n "$state_color" ]; then
      c_st=$(_hex_esc "$state_color")
    fi

    case "$state" in
      busy|working)
        c_st=${c_st:-$C_BUSY}
        icon=${state_icon:-"󰑮"}
        title="$idx $name $icon"
        display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R} ${c_st}@SPIN@${R}      "
        printf '%s\t%s\t%s\t%s\t%b\n' "$title" "$idx" "$name" "$session" "$display"
        ;;
      idle)
        c_st=${c_st:-$C_IDLE}
        icon=${state_icon:-"󱥂"}
        title="$idx $name $icon"
        display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R} ${c_st}${icon}${R}      "
        printf '%s\t%s\t%s\t%s\t%b\n' "$title" "$idx" "$name" "$session" "$display"
        ;;
      question|awaiting_input)
        c_st=${c_st:-$C_QUESTION}
        icon=${state_icon:-"󱜻"}
        title="$idx $name $icon"
        display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R} ${c_st}${icon}${R}      "
        printf '%s\t%s\t%s\t%s\t%b\n' "$title" "$idx" "$name" "$session" "$display"
        ;;
      error)
        c_st=${c_st:-$C_ERROR}
        icon=${state_icon:-"󰨄"}
        title="$idx $name $icon"
        display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R} ${c_st}${icon}${R}      "
        printf '%s\t%s\t%s\t%s\t%b\n' "$title" "$idx" "$name" "$session" "$display"
        ;;
      permission)
        c_st=${c_st:-$C_PERM}
        icon=${state_icon:-"󱅭"}
        title="$idx $name $icon"
        display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R} ${c_st}${icon}${R}      "
        printf '%s\t%s\t%s\t%s\t%b\n' "$title" "$idx" "$name" "$session" "$display"
        ;;
      *)
        if [ -n "$state_icon" ]; then
          c_st=${c_st:-$C_IDLE}
          title="$idx $name $state_icon"
          display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R} ${c_st}${state_icon}${R}      "
        else
          title="$idx $name"
          display=" ${mark} ${C_IDX}${idx}${R}  ${c_cur_name}${name}${R}          "
        fi
        printf '%s\t%s\t%s\t%s\t%b\n' "$title" "$idx" "$name" "$session" "$display"
        ;;
    esac
  done
done
