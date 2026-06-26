#!/bin/bash
# Listens to lazygitrs SSE and injects prompts directly into the active agy tmux pane

echo "Starting lazygitrs SSE tmux bridge..."

# Use curl to hold an open connection to the SSE endpoint
while true; do
  curl -N -s http://127.0.0.1:47657/session-api/events | while read -r line; do
    if [[ "$line" == data:* ]]; then
      # Extract the JSON payload
      json="${line#data: }"
      
      # Use jq to safely extract the prompt
      prompt=$(echo "$json" | jq -r '.prompt')
      
      if [[ -n "$prompt" && "$prompt" != "null" ]]; then
        # Read the active agy pane ID saved by our hook
        if [[ -f "/tmp/agy-active-pane.txt" ]]; then
          pane=$(cat /tmp/agy-active-pane.txt)
          if [[ -n "$pane" ]]; then
            echo "Injecting prompt into tmux pane $pane..."
            # Send the raw prompt text followed by an Enter keystroke
            tmux send-keys -t "$pane" "$prompt" Enter
          fi
        else
          echo "Warning: No active agy pane found in /tmp/agy-active-pane.txt"
        fi
      fi
    fi
  done
  sleep 2
done
