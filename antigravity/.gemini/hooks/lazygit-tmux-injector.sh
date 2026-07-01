#!/bin/bash

echo "$@" > /tmp/tmux-injector.log
#!/bin/bash
WORKSPACE_DIR="$1"
PROMPT="$2"

SAFE_PATH=$(echo -n "$WORKSPACE_DIR" | sed 's/[^a-zA-Z0-9]/_/g')
PANE_FILE="/tmp/agy-active-pane-${SAFE_PATH}.txt"

if [[ ! -f "$PANE_FILE" ]]; then exit 1; fi
PANE=$(cat "$PANE_FILE")
if [[ -z "$PANE" ]]; then exit 1; fi

# Remove newlines to make it a single-line prompt!
SINGLE_LINE_PROMPT=$(echo "$PROMPT" | tr '\n' ' ')

# Type it literally (safe since it's a single line)
tmux send-keys -t "$PANE" -l "$SINGLE_LINE_PROMPT"

# Now just send a normal Enter!
tmux send-keys -t "$PANE" muxEnter
