#!/usr/bin/env bash
# close-window.sh — saves current window/pane state and gracefully closes it
set -euo pipefail

SCRIPT_DIR="$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")"
RECORD_SCRIPT="${SCRIPT_DIR}/record-window-state.sh"

TARGET="${1:-}"

# Record state before closing
if [ -x "$RECORD_SCRIPT" ]; then
  "$RECORD_SCRIPT" --push "$TARGET" 2>/dev/null || true
fi

# Close the pane / window
if [ -n "$TARGET" ]; then
  tmux kill-pane -t "$TARGET" 2>/dev/null || tmux kill-window -t "$TARGET" 2>/dev/null || true
else
  tmux kill-pane 2>/dev/null || tmux kill-window 2>/dev/null || true
fi
