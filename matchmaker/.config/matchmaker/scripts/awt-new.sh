#!/usr/bin/env bash
# 100% Matchmaker Presets Worktree Creation Wizard

trap 'exit 0' INT

step=1
icon="🏷️"
prefix=""
slug=""
branch_name=""
bbase=""
OUTPUT_SLUG=""

prompt_for_branch_slug() {
    local prompt_msg="$1"
    local initial_val="$2"
    local buf="$initial_val"
    local key=""
    local rest=""
    OUTPUT_SLUG=""

    # Clear terminal screen to prevent ghost lines
    clear >/dev/tty 2>/dev/null || printf "\033[H\033[2J" >/dev/tty

    # Draw prompt on Line 1 and footer on Line 3, then restore cursor to Line 1
    printf "%b%s\n\n \033[36m[Enter]\033[0m \033[2mConfirm\033[0m  •  \033[33m[Esc / Empty]\033[0m \033[2mBack\033[0m\033[2A\r%b%s" \
        "$prompt_msg" "$buf" "$prompt_msg" "$buf" >/dev/tty

    while IFS= read -r -s -n 1 key </dev/tty; do
        # 1. ESC key pressed
        if [[ "$key" == $'\e' ]]; then
            read -r -s -n 2 -t 0.05 rest </dev/tty
            if [[ -z "$rest" ]]; then
                echo "" >/dev/tty
                return 1
            fi
            continue
        fi

        # 2. Enter key pressed (read returns empty string on newline)
        if [[ -z "$key" ]]; then
            echo "" >/dev/tty
            OUTPUT_SLUG="$buf"
            return 0
        fi

        # 3. Ctrl-C (0x03) or Ctrl-D (0x04)
        if [[ "$key" == $'\x03' || "$key" == $'\x04' ]]; then
            echo "" >/dev/tty
            exit 0
        fi

        # 4. Backspace (0x7F / 127 or 0x08 / \b)
        if [[ "$key" == $'\x7f' || "$key" == $'\b' || "$key" == $'\177' ]]; then
            if [[ ${#buf} -gt 0 ]]; then
                buf="${buf%?}"
                printf "\b \b" >/dev/tty
            fi
            continue
        fi

        # 5. Printable characters
        if [[ "$key" =~ [[:print:]] ]]; then
            buf+="$key"
            printf "%s" "$key" >/dev/tty
        fi
    done
}

while true; do
    case "$step" in
        1)
            # ── Step 1: Conventional Type Selection via Matchmaker Preset (`mm -o awt-type`) ──
            type_output=$(mm -o awt-type)

            # If Esc / canceled in Step 1 -> exit completely back to main awt list
            if [[ -z "$type_output" ]]; then
                exit 0
            fi

            IFS=$'\t' read -r icon prefix <<< "$type_output"
            step=2
            ;;

        2)
            # ── Step 2: Worktree Branch Slug Input with Type Icon & Footer ──
            if [[ -n "$prefix" ]]; then
                prompt_header=$(printf "%s \033[1;36mBranch Name (%s<name>):\033[0m " "$icon" "${prefix}")
            else
                prompt_header=$(printf "%s \033[1;36mBranch Name (<name>):\033[0m " "$icon")
            fi

            if ! prompt_for_branch_slug "$prompt_header" "$slug"; then
                # Instant Esc pressed -> go back to Step 1
                step=1
                continue
            fi

            # If user pressed enter with empty string -> go back to Step 1
            if [[ -z "$OUTPUT_SLUG" ]]; then
                step=1
                continue
            fi

            slug=$(echo "$OUTPUT_SLUG" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            branch_name="${prefix}${slug}"
            step=3
            ;;

        3)
            # ── Step 3: Base Branch Selection via Matchmaker Preset (`mm -o awt-base`) ──
            bbase=$(mm -o awt-base)

            # If Esc was pressed in Step 3 -> step back to Step 2 with previous slug preserved!
            if [[ -z "$bbase" ]]; then
                step=2
                continue
            fi

            step=4
            ;;

        4)
            # ── Step 4: Provision Worktree & Connect via Sesh ──
            repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
            branch_folder="${branch_name//\//-}"
            target_dir="$repo_root/../$branch_folder"

            printf "\n\033[1;32m✓ Creating worktree '%s' (base: %s)...\033[0m\n" "$branch_name" "$bbase"

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

            if command -v sesh >/dev/null 2>&1; then
                sesh connect "$target_dir"
            fi
            exit 0
            ;;
    esac
done
