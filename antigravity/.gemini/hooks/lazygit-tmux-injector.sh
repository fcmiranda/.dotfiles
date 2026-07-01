#!/bin/bash

echo "$@" >> /tmp/tmux-injector.log
WORKSPACE_DIR="$1"
PROMPT="$2"

SAFE_PATH=$(echo -n "$WORKSPACE_DIR" | sed 's/[^a-zA-Z0-9]/_/g')
PANE_FILE="/tmp/agy-active-pane-${SAFE_PATH}.txt"

if [[ ! -f "$PANE_FILE" ]]; then exit 1; fi
PANE=$(cat "$PANE_FILE")
if [[ -z "$PANE" ]]; then exit 1; fi

# Staleness guard: if the tracked pane no longer runs agy/node, the agy
# session died and the pane was reused (e.g. by a shell). Refuse to
# inject there — it would type the prompt into the wrong window.
PANE_CMD=$(tmux list-panes -a -F '#{pane_id} #{pane_current_command}' 2>/dev/null | grep "^${PANE} " | cut -d' ' -f2-)
if [[ -n "$PANE_CMD" && "$PANE_CMD" != "agy" && "$PANE_CMD" != "node" && "$PANE_CMD" != "bash" && "$PANE_CMD" != "zsh" ]]; then
  echo "stale pane ($PANE_CMD) — refusing to inject" >> /tmp/tmux-injector.log
  exit 1
fi

# Primary path: bracketed paste preserves the multi-line structure of
# the prompt (markdown lists, code fences) in agy's input widget, which
# the A/B test confirmed does NOT trigger premature submit. Atomic, so
# no PTY buffer-tearing race (the original bug that motivated flattening).
if printf '%s' "$PROMPT" | tmux load-buffer - 2>/dev/null; then
  if tmux paste-buffer -t "$PANE" -p 2>/dev/null; then
    tmux send-keys -t "$PANE" Enter
    exit 0
  fi
fi

# Fallback: flatten to a single line and type it literally. Bulletproof
# on any tmux / target combo, at the cost of losing prompt structure.
SINGLE_LINE_PROMPT=$(echo "$PROMPT" | tr '\n' ' ')
tmux send-keys -t "$PANE" -l "$SINGLE_LINE_PROMPT"
tmux send-keys -t "$PANE" Enter
