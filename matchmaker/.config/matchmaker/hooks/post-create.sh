#!/usr/bin/env bash
# Matchmaker Agent Worktree Lifecycle Hook: post-create
# Args: <worktree_path> <branch_name> <base_branch>

wt_path="$1"
branch_name="$2"
base_branch="$3"

[ -d "$wt_path" ] || exit 0

repo_root=$(git -C "$wt_path" rev-parse --show-toplevel 2>/dev/null || pwd)

# 1. Environment files propagation (.env.example or .env)
if [[ -f "$repo_root/../main/.env" && ! -f "$wt_path/.env" ]]; then
    cp "$repo_root/../main/.env" "$wt_path/.env" 2>/dev/null || true
elif [[ -f "$repo_root/../main/.env.example" && ! -f "$wt_path/.env" ]]; then
    cp "$repo_root/../main/.env.example" "$wt_path/.env" 2>/dev/null || true
fi

# 2. Project-level custom hooks (if defined in repository)
if [[ -x "$wt_path/.hooks/post-create" ]]; then
    "$wt_path/.hooks/post-create" "$wt_path" "$branch_name" "$base_branch"
elif [[ -x "$wt_path/.git/hooks/post-worktree-create" ]]; then
    "$wt_path/.git/hooks/post-worktree-create" "$wt_path" "$branch_name" "$base_branch"
fi
