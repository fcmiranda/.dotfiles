#!/usr/bin/env bash
# 100% Matchmaker Presets Worktree Creation Wizard

trap 'exit 0' INT

step=1
icon="󰓹"
prefix=""
slug=""
branch_name=""
bbase=""

MM_TUI_ARGS=()
if [ "$TMUX_POPUP" = "1" ]; then
    MM_TUI_ARGS=("tui.percentage=100" "tui.max=9999")
fi

while true; do
    case "$step" in
        1)
            # ── Step 1: Conventional Type Selection via Matchmaker Preset (`mm -o awt-type`) ──
            type_output=$(mm -o awt-type "${MM_TUI_ARGS[@]}")

            # If Esc / canceled in Step 1 -> exit completely back to main awt list
            if [[ -z "$type_output" ]]; then
                exit 0
            fi

            IFS=$'\t' read -r icon prefix <<< "$type_output"
            step=2
            ;;

        2)
            # ── Step 2: Worktree Branch Name via Matchmaker Prompt Box (`mm -o awt-prompt`) ──
            initial_val="${prefix}${slug}"
            prompt_str="${icon}"

            branch_input=$(mm -o awt-prompt prompt="$prompt_str" initial="$initial_val" "${MM_TUI_ARGS[@]}")

            # If user pressed Esc or cancelled -> go back to Step 1
            if [[ -z "$branch_input" ]]; then
                step=1
                continue
            fi

            branch_name=$(echo "$branch_input" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            slug="${branch_name#"${prefix}"}"
            step=3
            ;;

        3)
            # ── Step 3: Base Branch Selection via Matchmaker Preset (`mm -o awt-base`) ──
            bbase=$(mm -o awt-base "${MM_TUI_ARGS[@]}")

            # If Esc was pressed in Step 3 -> step back to Step 2 with previous slug preserved!
            if [[ -z "$bbase" ]]; then
                step=2
                continue
            fi

            step=4
            ;;

        4)
            # ── Step 4: Provision Worktree, Run Hooks & Connect via Sesh ──
            repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            branch_folder="${branch_name//\//-}"
            target_dir="$repo_root/../$branch_folder"

            printf "\n\033[1;32m󰄬 Creating worktree '%s' (base: %s)...\033[0m\n" "$branch_name" "$bbase"

            if command -v wt >/dev/null 2>&1; then
                wt switch --create "$branch_name" --base "$bbase"
            else
                git worktree add "$target_dir" -b "$branch_name" "$bbase"
            fi
            git -C "$target_dir" config "branch.${branch_name}.base" "$bbase" 2>/dev/null || true

            # Run post-create hook if present
            if [[ -x "$HOME/.config/matchmaker/hooks/post-create.sh" ]]; then
                "$HOME/.config/matchmaker/hooks/post-create.sh" "$target_dir" "$branch_name" "$bbase" 2>/dev/null || true
            fi

            # Connect via Sesh (creates session and switches Tmux client)
            if command -v sesh >/dev/null 2>&1; then
                sesh connect "$target_dir"
            fi
            exit 0
            ;;
    esac
done
