#!/usr/bin/env bash
# Matchmaker Agent Worktree Merge Handler: merges current branch into target branch with native Git
# Args: <selected_raw> <selected_path> <selected_session> <selected_base> [flags...]

selected_raw="$1"
selected_path="$2"
selected_session="$3"
selected_base="$4"
shift 4 2>/dev/null || true

# Parse flags
squash=0
no_commit=0
no_remove=0
no_tmux=0
no_rebase=0

for arg in "$@"; do
    case "$arg" in
        --squash) squash=1 ;;
        --no-squash) squash=0 ;;
        --no-commit) no_commit=1 ;;
        --no-remove) no_remove=1 ;;
        --no-tmux|--no-connect) no_tmux=1 ;;
        --no-rebase) no_rebase=1 ;;
    esac
done

# 1. Determine Current Worktree & Branch
current_wt=$(git rev-parse --show-toplevel 2>/dev/null)
current_branch=$(git rev-parse --abbrev-ref HEAD 2>/dev/null)
current_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)

selected_branch=$(echo "$selected_raw" | sed -E 's/^[^a-zA-Z0-9._/-]+//; s/[[:space:]].*//')

# 2. Determine Source and Target branches
if [[ "$selected_branch" == "$current_branch" || -z "$selected_branch" ]]; then
    target_branch=$(git -C "$current_wt" config "branch.${current_branch}.base" 2>/dev/null)
    target_branch="${target_branch:-main}"
else
    target_branch="$selected_branch"
fi
source_branch="$current_branch"

# Validation: cannot merge a branch into itself
if [[ "$source_branch" == "$target_branch" ]]; then
    printf "\n\033[1;31m󰅖 Cannot merge '%s' into itself!\033[0m\n" "$source_branch" >/dev/tty
    sleep 1.2
    exit 0
fi

# 3. Resolve Target Worktree Directory & Session
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

# 4. Auto-stash dirty state in current worktree
stashed=0
dirty_count=$(git -C "$current_wt" status --porcelain 2>/dev/null | wc -l)
if [[ "$dirty_count" -gt 0 ]]; then
    if git -C "$current_wt" stash push -u -m "awt-merge-autostash: $source_branch" >/dev/null 2>&1; then
        stashed=1
    fi
fi

# 5. Execute 100% Native Git Merge in Target Worktree
merge_success=0

if [[ -d "$target_wt" ]]; then
    if [[ $squash -eq 1 ]]; then
        if git -C "$target_wt" merge --squash "$source_branch" >/dev/null 2>&1; then
            if [[ $no_commit -eq 0 ]]; then
                git -C "$target_wt" commit -m "squash: merge $source_branch into $target_branch" >/dev/null 2>&1 || true
            fi
            merge_success=1
        fi
    elif [[ $no_commit -eq 1 ]]; then
        if git -C "$target_wt" merge --no-ff --no-commit "$source_branch" >/dev/null 2>&1; then
            merge_success=1
        fi
    else
        # Standard fast-forward or merge commit
        if git -C "$target_wt" merge --ff "$source_branch" >/dev/null 2>&1; then
            merge_success=1
        elif git -C "$target_wt" merge "$source_branch" -m "merge: $source_branch into $target_branch" >/dev/null 2>&1; then
            merge_success=1
        fi
    fi
fi

if [[ $merge_success -eq 1 ]]; then
    # Trigger post-merge lifecycle hook
    if [[ -x "$HOME/.config/matchmaker/hooks/post-merge.sh" && -d "$target_wt" ]]; then
        "$HOME/.config/matchmaker/hooks/post-merge.sh" "$target_wt" "$target_branch" "$source_branch" 2>/dev/null || true
    fi

    # Cleanup source worktree & branch unless --no-remove was specified
    if [[ $no_remove -eq 0 && "$current_wt" != "$target_wt" ]]; then
        git worktree remove -f "$current_wt" >/dev/null 2>&1 || true
        git branch -d "$source_branch" >/dev/null 2>&1 || git branch -D "$source_branch" >/dev/null 2>&1 || true
    fi

    # Switch Tmux session to target unless --no-tmux was specified
    if [[ $no_tmux -eq 0 ]]; then
        if command -v sesh >/dev/null 2>&1; then
            if tmux has-session -t "$target_session" >/dev/null 2>&1; then
                sesh connect "$target_session" >/dev/null 2>&1
            elif [[ -d "$target_wt" ]]; then
                sesh connect "$target_wt" >/dev/null 2>&1
            fi
        fi

        # Kill old Tmux session if we left it and removed it
        if [[ $no_remove -eq 0 && -n "$current_session" && "$current_session" != "$target_session" ]]; then
            tmux kill-session -t "$current_session" >/dev/null 2>&1 || true
        fi
    fi
    exit 0
else
    # Restore stash if merge failed
    if [[ $stashed -eq 1 ]]; then
        git -C "$current_wt" stash pop >/dev/null 2>&1 || true
    fi
    printf "\n\033[1;31m󰅖 Merge failed or has conflicts! Worktree kept intact for resolution.\033[0m\n" >/dev/tty
    sleep 2
    exit 1
fi
