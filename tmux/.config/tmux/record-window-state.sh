#!/usr/bin/env bash
# record-window-state.sh — tracks active & closed Tmux window states for instant tab reopening
set -euo pipefail

STATE_DIR="$HOME/.local/state/tmux"
mkdir -p "$STATE_DIR"
STACK_FILE="$STATE_DIR/closed-windows.json"
ACTIVE_FILE="$STATE_DIR/last-active-window.json"

inspect_pane() {
  local target="${1:-}"
  local pane_pid pane_path pane_session pane_win_name win_layout

  if [ -n "$target" ]; then
    pane_pid=$(tmux display-message -p -t "$target" '#{pane_pid}' 2>/dev/null || true)
    pane_path=$(tmux display-message -p -t "$target" '#{pane_current_path}' 2>/dev/null || true)
    pane_session=$(tmux display-message -p -t "$target" '#{session_name}' 2>/dev/null || true)
    pane_win_name=$(tmux display-message -p -t "$target" '#{window_name}' 2>/dev/null || true)
    win_layout=$(tmux display-message -p -t "$target" '#{window_layout}' 2>/dev/null || true)
  else
    pane_pid=$(tmux display-message -p '#{pane_pid}' 2>/dev/null || true)
    pane_path=$(tmux display-message -p '#{pane_current_path}' 2>/dev/null || true)
    pane_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || true)
    pane_win_name=$(tmux display-message -p '#{window_name}' 2>/dev/null || true)
    win_layout=$(tmux display-message -p '#{window_layout}' 2>/dev/null || true)
  fi

  # Ignore popup sessions
  if [ "$pane_session" = "_popups" ] || [ -z "$pane_pid" ]; then
    return 1
  fi

  local found_cmd=""
  local found_file=""
  local found_cwd=""

  # Traverse all descendant child processes
  local all_pids=()
  local queue=("$pane_pid")
  while [ ${#queue[@]} -gt 0 ]; do
    local curr="${queue[0]}"
    queue=("${queue[@]:1}")
    local kids
    kids=$(pgrep -P "$curr" 2>/dev/null || true)
    for k in $kids; do
      queue+=("$k")
      all_pids+=("$k")
    done
  done

  for (( i=${#all_pids[@]}-1; i>=0; i-- )); do
    local p="${all_pids[$i]}"
    [ ! -d "/proc/$p" ] && continue
    local pname
    pname=$(cat "/proc/$p/comm" 2>/dev/null || true)
    local raw_cmdline
    raw_cmdline=$(tr '\0' ' ' < "/proc/$p/cmdline" 2>/dev/null | sed 's/ *$//' || true)
    local cwd
    cwd=$(readlink "/proc/$p/cwd" 2>/dev/null || true)

    if [[ "$pname" =~ ^(nvim|vim)$ ]]; then
      local sock="/run/user/$UID/nvim.$p.0"
      if [ -S "$sock" ]; then
        local nfile
        nfile=$(nvim --server "$sock" --remote-expr "expand('%:p')" 2>/dev/null || true)
        if [ -n "$nfile" ] && [ -f "$nfile" ]; then
          found_file="$nfile"
          found_cmd="nvim $(printf '%q' "$nfile")"
          [ -n "$cwd" ] && found_cwd="$cwd"
          break
        fi
      fi

      local args
      args=$(tr '\0' '\n' < "/proc/$p/cmdline" 2>/dev/null || true)
      local file_arg=""
      while IFS= read -r arg; do
        [ -z "$arg" ] && continue
        [[ "$arg" == nvim* || "$arg" == vim* ]] && continue
        [[ "$arg" == -* ]] && continue
        file_arg="$arg"
      done <<< "$args"

      if [ -n "$file_arg" ]; then
        found_file="$file_arg"
        found_cmd="nvim $(printf '%q' "$file_arg")"
      else
        found_cmd="nvim"
      fi
      [ -n "$cwd" ] && found_cwd="$cwd"
      break
    fi

    if [[ "$pname" =~ ^(lazygit|lazygitrs|opencode|yazi|btop|htop|cargo|git|python|python3|node)$ ]]; then
      found_cmd="$raw_cmdline"
      [ -z "$found_cmd" ] && found_cmd="$pname"
      [ -n "$cwd" ] && found_cwd="$cwd"
      break
    fi
  done

  [ -n "$found_cwd" ] && pane_path="$found_cwd"
  [ -z "$pane_path" ] && pane_path="$HOME"

  jq -n \
    --arg session "$pane_session" \
    --arg name "$pane_win_name" \
    --arg path "$pane_path" \
    --arg cmd "$found_cmd" \
    --arg file "$found_file" \
    --arg layout "$win_layout" \
    --arg time "$(date +%s)" \
    '{session: $session, name: $name, path: $path, cmd: $cmd, file: $file, layout: $layout, time: ($time | tonumber)}'
}

push_entry() {
  local entry="$1"
  [ -z "$entry" ] && return 0

  if [ -f "$STACK_FILE" ] && [ -s "$STACK_FILE" ]; then
    jq --argjson item "$entry" '[$item] + .[:24]' "$STACK_FILE" > "$STACK_FILE.tmp" && mv "$STACK_FILE.tmp" "$STACK_FILE"
  else
    echo "[$entry]" > "$STACK_FILE"
  fi
}

case "${1:-}" in
  --track)
    entry=$(inspect_pane "" || true)
    if [ -n "$entry" ]; then
      echo "$entry" > "$ACTIVE_FILE"
    fi
    ;;
  --unlinked)
    if [ -f "$ACTIVE_FILE" ] && [ -s "$ACTIVE_FILE" ]; then
      now=$(date +%s)
      tracked_time=$(jq -r '.time // 0' "$ACTIVE_FILE" 2>/dev/null || echo 0)
      # If active window was tracked within last 60 seconds
      if [ $((now - tracked_time)) -le 60 ]; then
        last_closed_time=0
        if [ -f "$STACK_FILE" ] && [ -s "$STACK_FILE" ]; then
          last_closed_time=$(jq -r '.[0].time // 0' "$STACK_FILE" 2>/dev/null || echo 0)
        fi
        # Only push if it was not already pushed (within last 2s) by close-window.sh
        if [ $((now - last_closed_time)) -ge 2 ]; then
          entry=$(cat "$ACTIVE_FILE")
          push_entry "$entry"
        fi
      fi
    fi
    ;;
  --push)
    shift
    target="${1:-}"
    entry=$(inspect_pane "$target" || true)
    if [ -n "$entry" ]; then
      push_entry "$entry"
    fi
    ;;
  *)
    target="${1:-}"
    entry=$(inspect_pane "$target" || true)
    if [ -n "$entry" ]; then
      push_entry "$entry"
    fi
    ;;
esac
