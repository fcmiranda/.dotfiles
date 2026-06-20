#!/usr/bin/env bash
#
# agy-wrapper.sh
# 
# Wraps the Antigravity CLI to ensure Tmux state is cleared gracefully on exit.
# This prevents stale UI states in Tmux when the CLI is closed via /exit or Ctrl+C
# since the native hook sometimes fails to fire during abrupt process termination.

# Setup the trap if we are running inside Tmux
if [[ -n "$TMUX_PANE" ]]; then
  trap 'curl -s -X POST http://127.0.0.1:4040/api/status -H "Content-Type: application/json" -d "{\"pane_id\":\"$TMUX_PANE\",\"state\":\"closed\"}" > /dev/null' EXIT
fi

# Execute the actual CLI, passing all arguments transparently
command agy "$@"
