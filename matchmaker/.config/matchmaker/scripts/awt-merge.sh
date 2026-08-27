#!/usr/bin/env bash
# Matchmaker Agent Worktree Merge Handler: merges current branch into target branch, cleans up worktree & tmux session

selected_raw="$1"
selected_path="$2"
selected_session="$3"
selected_base="$4"

# 1. Determine Current Worktree & Branch
current_wt=$(git rev-parse --show-toplevel 2>/dev/null)
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

selected_branch=$(echo "$selected_raw" | sed "s/^[ @^]*//; s/ .*//")

# 2. Determine Source and Target branches
# If the user selected the CURRENT branch, the target is its configured BASE branch (or main)
if [[ "$selected_branch" == "$current_branch" || -z "$selected_branch" ]]; then
    target_branch=$(git -C "$current_wt" config "branch.${current_branch}.base" 2>/dev/null)
    target_branch="${target_branch:-main}"
else
    # The user explicitly highlighted the TARGET branch in the list!
    target_branch="$selected_branch"
fi
source_branch="$current_branch"

# Validation: cannot merge a branch into itself
if [[ "$source_branch" == "$target_branch" ]]; then
    printf "\n\033[1;31m✖ Cannot merge '%s' into itself!\033[0m\n" "$source_branch" >/dev/tty
    sleep 1.5
    exit 0
fi

# 3. Action Box Confirmation via Matchmaker awt-confirm preset
confirm_cmd=$(printf "ACTION\tLABEL\nmerge\t🚀 Yes, Merge '%s' into '%s' (clean up worktree & switch session)\ncancel\t🛡️  No, Cancel\n" "$source_branch" "$target_branch")

confirm_choice=$(mm -o awt-confirm query.prompt="🔀 Merge '${source_branch}' into '${target_branch}'? > " start.command.command="$confirm_cmd")

if [[ "$confirm_choice" != "merge" ]]; then
    exit 0
fi

# 4. Resolve Target Worktree Directory & Session
repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
repo_parent=$(basename "$(dirname "$current_wt")")
target_clean="${target_branch//\//-}"
target_wt="$repo_root/../$target_clean"

if [[ ! -d "$target_wt" ]]; then
    if [[ -d "$repo_root/../$target_branch" ]]; then
        target_wt="$repo_root/../$target_branch"
    fi
fi

if [[ "$repo_parent" == ".dotfiles" ]]; then
    target_session="_dotfiles/$target_clean"
else
    target_session="${repo_parent}/${target_clean}"
fi

# 5. Execute Merge
printf "\n\033[1;36m🔀 Merging '%s' into '%s'...\033[0m\n" "$source_branch" "$target_branch" >/dev/tty

merge_success=0
if command -v wt >/dev/null 2>&1; then
    if wt merge "$target_branch" >/dev/null 2>&1; then
        merge_success=1
    fi
fi

if [[ $merge_success -eq 0 ]]; then
    # Fallback to native git merge in target worktree if exists
    if [[ -d "$target_wt" ]]; then
        if git -C "$target_wt" merge "$source_branch" >/dev/null 2>&1; then
            merge_success=1
        fi
    fi
fi

if [[ $merge_success -eq 1 ]]; then
    printf "\033[1;32m✓ Merge successful!\033[0m\n" >/dev/tty

    # Cleanup source worktree
    if command -v wt >/dev/null 2>&1; then
        wt remove "$current_wt" >/dev/null 2>&1 || git worktree remove -f "$current_wt" >/dev/null 2>&1
    else
        git worktree remove -f "$current_wt" >/dev/null 2>&1 || true
    fi
    git branch -d "$source_branch" >/dev/null 2>&1 || git branch -D "$source_branch" >/dev/null 2>&1 || true

    # Switch Tmux session to target
    if command -v sesh >/dev/null 2>&1; then
        if tmux has-session -t "$target_session" >/dev/null 2>&1; then
            sesh connect "$target_session" >/dev/null 2>&1
        elif [[ -d "$target_wt" ]]; then
            sesh connect "$target_wt" >/dev/null 2>&1
        fi
    fi

    # Kill old Tmux session
    if [[ -n "$current_session" ]]; then
        tmux kill-session -t "$current_session" >/dev/null 2>&1 || true
    fi
    exit 0
else
    printf "\n\033[1;31m✖ Merge failed or has conflicts! Worktree kept intact for resolution.\033[0m\n" >/dev/tty
    sleep 2
    exit 1
fi
