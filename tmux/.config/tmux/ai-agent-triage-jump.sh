#!/usr/bin/env bash
# ai-agent-triage-jump.sh - Direct, zero-modal focus jump to next AI agent requiring attention
# Cycles through panes in question/permission/error/working state across all Tmux sessions.

set -euo pipefail

# Collect all candidate panes requiring attention
notifying_panes=()

# 1. Primary: Query acpd daemon RPC (http://127.0.0.1:4040/rpc) for real-time agent states
acpd_token=""
for token_path in "/run/user/$UID/acpd/token" "/run/user/$(id -u 2>/dev/null)/acpd/token" "/run/user/1001/acpd/token"; do
  if [ -f "$token_path" ]; then
    acpd_token=$(cat "$token_path" 2>/dev/null || true)
    [ -n "$acpd_token" ] && break
  fi
done

if [ -n "$acpd_token" ] && command -v curl >/dev/null 2>&1 && command -v jq >/dev/null 2>&1; then
  acpd_res=$(curl -s -m 0.25 -X POST http://127.0.0.1:4040/rpc \
    -H "Authorization: Bearer $acpd_token" \
    -H "Content-Type: application/json" \
    -d '{"jsonrpc":"2.0","method":"agentState/list","id":1}' 2>/dev/null || true)

  if [ -n "$acpd_res" ]; then
    # Urgent: permission, awaiting_input, question, error
    while IFS= read -r p; do
      if [[ -n "$p" && "$p" =~ ^%[0-9]+$ ]] && tmux display-message -t "$p" -p '#{pane_id}' >/dev/null 2>&1; then
        notifying_panes+=("$p")
      fi
    done < <(echo "$acpd_res" | jq -r '
      .result // {} | to_entries |
      map(select(.value.state as $s | ["permission", "awaiting_input", "question", "error"] | index($s))) |
      sort_by(-.value.last_timestamp) |
      .[].key
    ' 2>/dev/null || true)

    # Active: working, busy (if no urgent panes found)
    if [ "${#notifying_panes[@]}" -eq 0 ]; then
      while IFS= read -r p; do
        if [[ -n "$p" && "$p" =~ ^%[0-9]+$ ]] && tmux display-message -t "$p" -p '#{pane_id}' >/dev/null 2>&1; then
          notifying_panes+=("$p")
        fi
      done < <(echo "$acpd_res" | jq -r '
        .result // {} | to_entries |
        map(select(.value.state as $s | ["working", "busy"] | index($s))) |
        sort_by(-.value.last_timestamp) |
        .[].key
      ' 2>/dev/null || true)
    fi
  fi
fi

# 2. Tmux Native Fallback: Panes in active question, permission, error, or awaiting_input state
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{@ai_agent_state_raw}' 2>/dev/null | awk '$2 ~ /^(question|permission|error|awaiting_input)$/ {print $1}')
fi

# 3. Fallback: Check @ai_agent_last_bell
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  last_bell=$(tmux show-option -gv @ai_agent_last_bell 2>/dev/null || echo "")
  if [ -n "$last_bell" ] && tmux display-message -t "$last_bell" -p '#{pane_id}' >/dev/null 2>&1; then
    notifying_panes+=("$last_bell")
  fi
fi

# 4. Fallback: Panes currently in active working or busy state
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{@ai_agent_state_raw}' 2>/dev/null | awk '$2 ~ /^(working|busy)$/ {print $1}')
fi

# 5. Fallback: Any registered AI agent pane
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{@ai_agent_state_raw}' 2>/dev/null | awk '$2 ~ /^(idle|working|busy|question|permission|error|awaiting_input)$/ {print $1}')
fi

# 6. Fallback: Search for any pane running agy, antigravity, or opencode CLI
if [ "${#notifying_panes[@]}" -eq 0 ]; then
  while IFS= read -r line; do
    [ -n "$line" ] && notifying_panes+=("$line")
  done < <(tmux list-panes -a -F '#{pane_id} #{pane_current_command} #{pane_title}' 2>/dev/null | awk '$2 ~ /^(agy|antigravity|opencode)$/ || $3 ~ /^(agy|antigravity|opencode)$/ {print $1}')
fi

if [ "${#notifying_panes[@]}" -eq 0 ]; then
  tmux display-message -d 1500 " 󰮯 No active AI Agent sessions found."
  exit 0
fi

total=${#notifying_panes[@]}
curr_idx=$(tmux show-option -gv @ai_agent_triage_ring_idx 2>/dev/null || echo 0)
if ! [[ "$curr_idx" =~ ^[0-9]+$ ]] || [ "$curr_idx" -ge "$total" ]; then
  curr_idx=0
fi

target_pane="${notifying_panes[$curr_idx]}"

# Advance ring index for the next call
next_idx=$(( (curr_idx + 1) % total ))
tmux set-option -g @ai_agent_triage_ring_idx "$next_idx" 2>/dev/null

target_sess=$(tmux display-message -t "$target_pane" -p '#S' 2>/dev/null)
target_win=$(tmux display-message -t "$target_pane" -p '#I' 2>/dev/null)
target_win_name=$(tmux display-message -t "$target_pane" -p '#W' 2>/dev/null)
target_state=$(tmux show-option -p -t "$target_pane" -v @ai_agent_state_raw 2>/dev/null || echo "active")

# Direct focus switch without intermediate popups
current_sess=$(tmux display-message -p '#S' 2>/dev/null || echo "")

if [ "$current_sess" != "$target_sess" ]; then
  tmux switch-client -t "$target_sess" 2>/dev/null || true
fi

tmux select-window -t "$target_sess:$target_win" 2>/dev/null || true
tmux select-pane -t "$target_pane" 2>/dev/null || true

# Audible cue if available (PipeWire pw-play with PulseAudio paplay fallback)
sound_file=""
case "$target_state" in
  question|awaiting_input) sound_file="$HOME/.local/share/sounds/ai/02-gentle-ping.wav" ;;
  permission) sound_file="$HOME/.local/share/sounds/ai/06-cyber-pulse.wav" ;;
  error) sound_file="$HOME/.local/share/sounds/ai/10-arcade-blip.wav" ;;
  *) sound_file="$HOME/.local/share/sounds/ai/04-subtle-bell.wav" ;;
esac
if [ -n "$sound_file" ] && [ -f "$sound_file" ]; then
  if command -v pw-play >/dev/null 2>&1; then
    pw-play "$sound_file" >/dev/null 2>&1 &
  elif command -v paplay >/dev/null 2>&1; then
    paplay "$sound_file" >/dev/null 2>&1 &
  fi
fi

# HUD feedback
tmux display-message -d 2000 " 󰮯 AI Triage: $target_sess › $target_win_name ($((curr_idx + 1))/$total) [${target_state}]"
