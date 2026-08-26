#!/usr/bin/env bash
# 100% Native Matchmaker & Readline Worktree Creation Wizard (Zero external deps)

trap 'exit 0' INT

# Enable Esc key to abort read -e in Readline
bind '"\e": abort' 2>/dev/null

selected_raw="$1"
selected_branch=$(echo "$selected_raw" | sed "s/^[ @^]*//; s/ .*//")

step=1
prefix=""
slug=""
branch_name=""
bbase=""

while true; do
    case "$step" in
        1)
            # ── Step 1: Conventional Type Selection via Matchmaker (mm) ──
            type_choice=$(printf "feat\t(new feature)\nfix\t(bug fix)\nrefactor\t(code restructuring)\nperf\t(performance optimization)\nchore\t(maintenance / config)\ndocs\t(documentation)\ntest\t(test suites)\nbuild\t(dependencies / build)\ncustom\t(no prefix / freeform)\n" | \
                mm columns.split="\t" start.output_template="{1}" query.prompt="Type [Esc: Cancel] > " tui.percentage=35 results.icons=false --status-inline)

            # If Esc / canceled in Step 1 -> exit completely back to main awt list
            if [[ -z "$type_choice" ]]; then
                exit 0
            fi

            case "$type_choice" in
                *"feat"*)     prefix="feat/" ;;
                *"fix"*)      prefix="fix/" ;;
                *"refactor"*) prefix="refactor/" ;;
                *"perf"*)     prefix="perf/" ;;
                *"chore"*)    prefix="chore/" ;;
                *"docs"*)     prefix="docs/" ;;
                *"test"*)     prefix="test/" ;;
                *"build"*)    prefix="build/" ;;
                *)            prefix="" ;;
            esac
            step=2
            ;;

        2)
            # ── Step 2: Worktree Branch Slug Input via Readline (Esc/Enter) ──
            echo ""
            prompt_header=$(printf "\033[1;36m🏷️  Branch Name (%s<name>)\033[0m \033[2m[Esc / Empty: Back]\033[0m: " "${prefix}")

            read -e -i "$slug" -p "$prompt_header" user_slug </dev/tty
            read_status=$?

            # If Esc was pressed (read_status != 0) or user gave empty string -> step back to Step 1
            if [[ $read_status -ne 0 || -z "$user_slug" || "$user_slug" == $'\e'* ]]; then
                step=1
                continue
            fi

            slug=$(echo "$user_slug" | tr ' ' '-' | tr '[:upper:]' '[:lower:]')
            branch_name="${prefix}${slug}"
            step=3
            ;;

        3)
            # ── Step 3: Base Branch Selection via Matchmaker (mm) ──
            base_list="main\t(default base)\n"
            if [[ "$selected_branch" != "main" && -n "$selected_branch" ]]; then
                base_list+="${selected_branch}\t(selected item)\n"
            fi
            all_branches=$(git branch --format="%(refname:short)" 2>/dev/null | grep -vE "^(main|${selected_branch:-main})$")
            if [[ -n "$all_branches" ]]; then
                while IFS= read -r b; do
                    [[ -n "$b" ]] && base_list+="${b}\t(local branch)\n"
                done <<< "$all_branches"
            fi

            bbase=$(printf "%b" "$base_list" | \
                mm columns.split="\t" start.output_template="{1}" query.prompt="Base for ${branch_name} [Esc: Back] > " tui.percentage=40 results.icons=false --status-inline)

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

            if command -v sesh >/dev/null 2>&1; then
                sesh connect "$target_dir"
            fi
            exit 0
            ;;
    esac
done
