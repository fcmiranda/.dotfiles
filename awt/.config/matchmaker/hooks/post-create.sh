#!/usr/bin/env bash
# Matchmaker Agent Worktree Lifecycle Hook: post-create
# Args: <worktree_path> <branch_name> <base_branch>

wt_path="$1"
branch_name="$2"
base_branch="$3"

[ -d "$wt_path" ] || exit 0

repo_root=$(git -C "$wt_path" rev-parse --show-toplevel 2>/dev/null || echo "$wt_path")
parent_dir="$(cd "$wt_path/.." 2>/dev/null && pwd || dirname "$wt_path")"

# 1. Hermetic Secret & Environment Propagation (.env, .env.local, .env.*.local)
primary_wt=""
while IFS= read -r line; do
    if [[ "$line" =~ ^worktree\ (.*) ]]; then
        wt_cand="${BASH_REMATCH[1]}"
        if [[ -d "$wt_cand" && "$wt_cand" != "$wt_path" ]]; then
            if [[ -z "$primary_wt" ]]; then
                primary_wt="$wt_cand"
            fi
            b=$(basename "$wt_cand")
            if [[ "$b" == "main" || "$b" == "master" ]]; then
                primary_wt="$wt_cand"
                break
            fi
        fi
    fi
done < <(git -C "$wt_path" worktree list --porcelain 2>/dev/null || true)

# Fallback paths if porcelain check yields empty
if [[ -z "$primary_wt" || ! -d "$primary_wt" ]]; then
    if [[ -d "$parent_dir/main" && "$parent_dir/main" != "$wt_path" ]]; then
        primary_wt="$parent_dir/main"
    elif [[ -d "$parent_dir/master" && "$parent_dir/master" != "$wt_path" ]]; then
        primary_wt="$parent_dir/master"
    elif [[ -d "$repo_root/../main" && "$repo_root/../main" != "$wt_path" ]]; then
        primary_wt="$repo_root/../main"
    elif [[ -d "$repo_root/../master" && "$repo_root/../master" != "$wt_path" ]]; then
        primary_wt="$repo_root/../master"
    fi
fi

if [[ -n "$primary_wt" && -d "$primary_wt" ]]; then
    # Propagate standard and local hermetic environment files
    env_targets=(".env" ".env.local" ".env.development.local" ".env.test.local" ".env.production.local")
    
    # Also discover any existing .env.*.local files in primary worktree (deduplicated)
    for extra_env in "$primary_wt"/.env.*.local; do
        if [[ -f "$extra_env" ]]; then
            b_env="$(basename "$extra_env")"
            already_tracked=0
            for existing in "${env_targets[@]}"; do
                if [[ "$existing" == "$b_env" ]]; then
                    already_tracked=1
                    break
                fi
            done
            [[ $already_tracked -eq 0 ]] && env_targets+=("$b_env")
        fi
    done

    for env_file in "${env_targets[@]}"; do
        src="$primary_wt/$env_file"
        dst="$wt_path/$env_file"
        if [[ -f "$src" && ! -f "$dst" ]]; then
            cp "$src" "$dst" 2>/dev/null || true
        fi
    done

    # Fallback to .env.example or .env.local.example if no .env exists
    if [[ ! -f "$wt_path/.env" ]]; then
        if [[ -f "$primary_wt/.env.example" ]]; then
            cp "$primary_wt/.env.example" "$wt_path/.env" 2>/dev/null || true
        elif [[ -f "$wt_path/.env.example" ]]; then
            cp "$wt_path/.env.example" "$wt_path/.env" 2>/dev/null || true
        elif [[ -f "$primary_wt/.env.local.example" ]]; then
            cp "$primary_wt/.env.local.example" "$wt_path/.env" 2>/dev/null || true
        elif [[ -f "$wt_path/.env.local.example" ]]; then
            cp "$wt_path/.env.local.example" "$wt_path/.env" 2>/dev/null || true
        fi
    fi
fi

# 2. Project-level custom hooks (if defined in repository)
if [[ -x "$wt_path/.hooks/post-create" ]]; then
    "$wt_path/.hooks/post-create" "$wt_path" "$branch_name" "$base_branch"
elif [[ -x "$wt_path/.git/hooks/post-worktree-create" ]]; then
    "$wt_path/.git/hooks/post-worktree-create" "$wt_path" "$branch_name" "$base_branch"
fi
