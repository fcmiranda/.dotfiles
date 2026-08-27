#!/usr/bin/env bash
# Matchmaker Agent Worktree Lifecycle Hook: post-merge
# Args: <target_worktree_path> <target_branch> <source_branch>

target_wt="$1"
target_branch="$2"
source_branch="$3"

[ -d "$target_wt" ] || exit 0

repo_parent=$(basename "$(dirname "$target_wt")")

# 1. Auto-restow if merging into dotfiles main
if [[ "$repo_parent" == ".dotfiles" && ( "$target_branch" == "main" || "$target_branch" == "master" ) ]]; then
    if [[ -x "$target_wt/stow.sh" ]]; then
        (cd "$target_wt" && ./stow.sh -r 2>/dev/null || true)
    fi
fi

# 2. Project-level custom hooks (if defined in repository)
if [[ -x "$target_wt/.hooks/post-merge" ]]; then
    "$target_wt/.hooks/post-merge" "$target_wt" "$target_branch" "$source_branch"
elif [[ -x "$target_wt/.git/hooks/post-worktree-merge" ]]; then
    "$target_wt/.git/hooks/post-worktree-merge" "$target_wt" "$target_branch" "$source_branch"
fi
