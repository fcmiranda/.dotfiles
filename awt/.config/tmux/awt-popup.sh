#!/usr/bin/env bash
# awt-popup.sh - Floating Worktree Manager Modal with dynamic Omarchy palette
trap 'exit 0' HUP INT TERM

REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || realpath "$0")
PROJECT_DIR="${1:-$PWD}"

if [ -z "${TMUX_POPUP:-}" ]; then
    if ! git -C "$PROJECT_DIR" rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git -C "$PROJECT_DIR" rev-parse --is-bare-repository >/dev/null 2>&1; then
        tmux display-message "Not in a git repository"
        exit 0
    fi

    SCRIPT_DIR=$(dirname "$REAL_SCRIPT")
    _tmux_style="$HOME/.local/state/omarchy/current/theme/tmux-style.sh"
    [ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
    # shellcheck source=/dev/null
    . "$_tmux_style" 2>/dev/null || true
    unset _tmux_style

    AWT_POPUP_COLOR=$(grep -E '^\s*orange\s*=' "$HOME/.local/state/omarchy/current/theme/colors.toml" 2>/dev/null | sed -E 's/.*=\s*"([^"]+)".*/\1/')
    [ -z "$AWT_POPUP_COLOR" ] && AWT_POPUP_COLOR="#e84d31"

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
          -S "fg=$AWT_POPUP_COLOR" \
          -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
          -b rounded \
          -T "  " \
          -d "$PROJECT_DIR" \
          -E \
          -w 85% -h 75% \
          "TMUX_POPUP=1 AWT_ORIGIN_PANE='$CURRENT_PANE' '$REAL_SCRIPT' '$PROJECT_DIR' || true" || true

        tmux kill-pane -t "$BACKDROP_PANE" 2>/dev/null || true
        tmux set-option -w -t "$CURRENT_PANE" automatic-rename on 2>/dev/null || true
        CURRENT_SESS=$(tmux display-message -p '#{session_name}')
        if [ "$CURRENT_SESS" = "$ORIG_SESS" ]; then
            tmux select-pane -t "$CURRENT_PANE" 2>/dev/null || true
        fi
    else
        CURRENT_PANE=$(tmux display-message -p '#{pane_id}')
        exec tmux display-popup \
          -S "fg=$AWT_POPUP_COLOR" \
          -s "fg=${TMUX_POPUP_TEXT_COLOR:-default}" \
          -b rounded \
          -T "  " \
          -d "$PROJECT_DIR" \
          -E \
          -w 85% -h 75% \
          "TMUX_POPUP=1 AWT_ORIGIN_PANE='$CURRENT_PANE' '$REAL_SCRIPT' '$PROJECT_DIR' || true" || true
    fi
    exit 0
fi

# Inside the popup modal:
MM_BIN="$HOME/.local/bin/mm"
[ -x "$MM_BIN" ] || MM_BIN="$(command -v mm 2>/dev/null || echo "mm")"

output=$("$MM_BIN" -o awt tui.percentage=100 tui.max=9999)
[ -z "$output" ] && exit 0

# If awt-new.sh already provisioned and connected to the session, exit immediately to prevent double execution
if [ -f "/tmp/awt_new_created_${USER:-user}" ]; then
    rm -f "/tmp/awt_new_created_${USER:-user}" 2>/dev/null || true
    exit 0
fi

IFS=$'\t' read -r session target <<< "$output"
cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")

if [ -n "$session" ] && [ "$cur_session" != "$session" ]; then
    if command -v sesh >/dev/null 2>&1; then
        if tmux has-session -t "$session" 2>/dev/null; then
            exec sesh connect "$session"
        else
            exec sesh connect "$target"
        fi
    fi
fi

exit 0
