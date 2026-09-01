#!/usr/bin/env bash
# awt-ai-detect.sh - Extensible AI Conversation Discovery Driver for AWT
# Detects active AI sessions across Tmux panes (agy, opencode, claude, codex, etc.)

detect_agy_conv() {
    local pid="$1"
    local conv_id=""
    # 1. Inspect open file descriptors for conversation db
    conv_id=$(ls -l /proc/"$pid"/fd 2>/dev/null | grep 'antigravity-cli/conversations' | sed -E 's/.*conversations\/([a-f0-9-]+)\.db.*/\1/' | head -n 1)
    if [ -n "$conv_id" ]; then
        echo "$conv_id"
        return 0
    fi

    # 2. Inspect process cmdline
    local cmdline
    cmdline=$(cat /proc/"$pid"/cmdline 2>/dev/null | tr '\0' ' ')
    if [[ "$cmdline" =~ --conversation[[:space:]=]+([a-f0-9-]+) ]]; then
        echo "${BASH_REMATCH[1]}"
        return 0
    fi
    echo ""
}

detect_opencode_conv() {
    local pid="$1"
    local cmdline
    cmdline=$(cat /proc/"$pid"/cmdline 2>/dev/null | tr '\0' ' ')
    local conv_id=""
    if [[ "$cmdline" =~ -s[[:space:]]+([^[:space:]]+) ]] || [[ "$cmdline" =~ --session[[:space:]]+([^[:space:]]+) ]]; then
        conv_id="${BASH_REMATCH[1]}"
    fi
    if [ -z "$conv_id" ] && command -v opencode >/dev/null 2>&1; then
        conv_id=$(opencode session list --format json 2>/dev/null | python3 -c "import sys,json; data=json.load(sys.stdin); print(data[0]['id'] if data else '')" 2>/dev/null || true)
    fi
    echo "$conv_id"
}

detect_claude_conv() {
    local pid="$1"
    local cmdline
    cmdline=$(cat /proc/"$pid"/cmdline 2>/dev/null | tr '\0' ' ')
    local conv_id=""
    if [[ "$cmdline" =~ --resume[[:space:]]+([^[:space:]]+) ]]; then
        conv_id="${BASH_REMATCH[1]}"
    fi
    echo "$conv_id"
}

find_descendants() {
    local pid="$1"
    local children
    children=$(pgrep -P "$pid" 2>/dev/null)
    for c in $children; do
        echo "$c"
        find_descendants "$c"
    done
}

# Returns list of AI sessions:
# Format: is_cur_pane \t ai_name \t conv_id \t win_pane_label \t resume_cmd
awt_ai_detect_all() {
    local current_pane="${AWT_ORIGIN_PANE:-$(tmux display-message -p '#{pane_id}' 2>/dev/null || echo '')}"
    local current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null || echo "")

    [ -z "$current_session" ] && return 0

    local seen_pids=()

    while read -r pane_id win_idx pane_idx pane_pid win_name pane_title; do
        local is_cur=0
        [[ "$pane_id" == "$current_pane" ]] && is_cur=1

        local all_pids=("$pane_pid" $(find_descendants "$pane_pid"))

        for p in "${all_pids[@]}"; do
            [[ " ${seen_pids[*]} " =~ " $p " ]] && continue
            seen_pids+=("$p")

            local comm
            comm=$(cat /proc/"$p"/comm 2>/dev/null || true)
            local cmdline
            cmdline=$(cat /proc/"$p"/cmdline 2>/dev/null | tr '\0' ' ' || true)

            local ai_tool=""
            local conv_id=""
            local resume_cmd=""

            # Driver 1: Antigravity (agy)
            if [[ "$comm" == "agy-bin" || "$comm" == "agy" || "$cmdline" == *"agy"* || "$cmdline" == *"antigravity"* ]]; then
                if [[ "$cmdline" != *"grep"* && "$cmdline" != *"awt-ai"* ]]; then
                    conv_id=$(detect_agy_conv "$p")
                    if [ -n "$conv_id" ] || [[ "$comm" == "agy-bin" ]]; then
                        ai_tool="agy"
                        if [ -n "$conv_id" ]; then
                            resume_cmd="agy --conversation $conv_id"
                        else
                            resume_cmd="agy -c"
                        fi
                    fi
                fi
            # Driver 2: OpenCode
            elif [[ "$comm" == "opencode" || "$cmdline" == *"opencode"* ]]; then
                if [[ "$cmdline" != *"grep"* && "$cmdline" != *"awt-ai"* ]]; then
                    ai_tool="opencode"
                    conv_id=$(detect_opencode_conv "$p")
                    if [ -n "$conv_id" ]; then
                        resume_cmd="opencode -s $conv_id"
                    else
                        resume_cmd="opencode -c"
                    fi
                fi
            # Driver 3: Claude Code
            elif [[ "$comm" == "claude" || "$cmdline" == *"claude"* ]]; then
                if [[ "$cmdline" != *"grep"* && "$cmdline" != *"awt-ai"* ]]; then
                    ai_tool="claude"
                    conv_id=$(detect_claude_conv "$p")
                    if [ -n "$conv_id" ]; then
                        resume_cmd="claude --resume $conv_id"
                    else
                        resume_cmd="claude --resume"
                    fi
                fi
            fi

            if [ -n "$ai_tool" ]; then
                local label="win ${win_idx}.${pane_idx}"
                [ -n "$win_name" ] && label+=" (${win_name})"
                printf "%s\t%s\t%s\t%s\t%s\n" "$is_cur" "$ai_tool" "$conv_id" "$label" "$resume_cmd"
                break
            fi
        done
    done < <(tmux list-panes -s -F "#{pane_id} #{window_index} #{pane_index} #{pane_pid} #{window_name} #{pane_title}" 2>/dev/null)
}

# If executed directly:
if [[ "${BASH_SOURCE[0]}" == "${0}" ]]; then
    awt_ai_detect_all
fi
