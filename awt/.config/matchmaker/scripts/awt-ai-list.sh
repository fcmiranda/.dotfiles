#!/usr/bin/env bash
# awt-ai-list.sh - Formats AI conversations list for Matchmaker (`mm -o awt-ai`)

SCRIPT_DIR=$(dirname "$(readlink -f "$0" 2>/dev/null || realpath "$0")")
# shellcheck source=/dev/null
. "$SCRIPT_DIR/awt-ai-detect.sh" 2>/dev/null || true

cur_lines=()
other_lines=()

while IFS=$'\t' read -r is_cur ai_tool conv_id label resume_cmd; do
    [ -z "$ai_tool" ] && continue

    short_id="$conv_id"
    if [ ${#short_id} -gt 18 ]; then
        short_id="${short_id:0:8}..${short_id: -6}"
    fi
    [ -z "$short_id" ] && short_id="active"

    if [[ "$is_cur" -eq 1 ]]; then
        cur_lines+=( "$(printf "\033[1;35m󱐋 %s\033[0m \033[35m(%s)\033[0m\t\033[35mcurrent pane\033[0m\t\033[1;32mcontinue\033[0m\t%s" "$ai_tool" "$short_id" "$resume_cmd")" )
    else
        other_lines+=( "$(printf "\033[1;36m󱐋 %s\033[0m \033[36m(%s)\033[0m\t\033[2m%s\033[0m\t\033[1;32mcontinue\033[0m\t%s" "$ai_tool" "$short_id" "$label" "$resume_cmd")" )
    fi
done < <(awt_ai_detect_all)

# 1. Output Current Pane AI at Row 0
for line in "${cur_lines[@]}"; do
    echo -e "$line"
done

# 2. Output Other AI sessions in the same tmux session
for line in "${other_lines[@]}"; do
    echo -e "$line"
done

# 3. Always include Fresh Conversation option
printf "\033[1;33m󰓹 Fresh Conversation\033[0m\t\033[2mdefault startup\033[0m\t\033[33mstart new\033[0m\t__FRESH__\n"
