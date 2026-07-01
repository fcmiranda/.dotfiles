#!/bin/bash
# Listens to lazygitrs SSE and injects prompts directly into the active agy tmux pane

# Receives the workspace directory as the first argument, or uses current directory
WORKSPACE_DIR="${1:-$(pwd)}"
cd "$WORKSPACE_DIR" || exit 1

echo "Starting lazygitrs SSE tmux bridge for workspace: $WORKSPACE_DIR"

# Generate the same safe path identifier used by the hook to isolate sessions
SAFE_PATH=$(echo -n "$WORKSPACE_DIR" | sed 's/[^a-zA-Z0-9]/_/g')
PANE_FILE="/tmp/agy-active-pane-${SAFE_PATH}.txt"

# Ensure curl children are killed when this script dies
trap 'pkill -P $$' EXIT

# Use curl to hold an open connection to the SSE endpoint
while true; do
  PORT=$(cat .lazygitrs.port 2>/dev/null || echo 47657)
  curl -N -s "http://127.0.0.1:$PORT/session-api/events" | while read -r line; do
    echo "DEBUG LINE: $line" >> /tmp/sse-bridge.log
    if [[ "$line" == data:* ]]; then
      # Extract the JSON payload
      json="${line#data: }"
      
      # Use jq to safely extract the prompt
      prompt=$(echo "$json" | jq -r '.prompt')
      
      if [[ -n "$prompt" && "$prompt" != "null" ]]; then
        # Read the active agy pane ID saved for this specific workspace
        if [[ -f "$PANE_FILE" ]]; then
          pane=$(cat "$PANE_FILE")
          if [[ -n "$pane" ]]; then
            echo "Injecting prompt into tmux pane $pane..." >> /tmp/sse-bridge.log
            # Use tmux buffer to preserve exact multi-line formatting without shell mangling
            single_line_prompt=$(echo "$prompt" | tr "\n" " ")
            tmux send-keys -t "$pane" -l "$single_line_prompt"
            
            # Send Escape then Enter to trigger Alt+Enter (submit multi-line in prompt_toolkit)
            tmux send-keys -t "$pane" Enter
            echo "Injected successfully" >> /tmp/sse-bridge.log
          fi
        else
          echo "Warning: No active agy pane found in $PANE_FILE" >> /tmp/sse-bridge.log
        fi
      else
        echo "Failed to extract prompt from JSON: $json" >> /tmp/sse-bridge.log
      fi
    fi
  done
  echo "SSE connection dropped. Restarting in 2s..." >> /tmp/sse-bridge.log
  sleep 2
done
