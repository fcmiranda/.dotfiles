#!/usr/bin/env bash
# Matchmaker Agent Worktree Delete Handler: deletes worktree, kills Tmux session, and switches to last session if active
# Args: <session_name> <wt_path> <branch_raw> [flags...]

session_name="$1"
wt_path="$2"
branch_raw="$3"
shift 3 2>/dev/null || true

# Parse flags
force=0
keep_branch=0
no_tmux=0

for arg in "$@"; do
    case "$arg" in
        -f|--force) force=1 ;;
        --no-delete-branch) keep_branch=1 ;;
        --no-tmux) no_tmux=1 ;;
    esac
done

branch_clean=$(echo "$branch_raw" | sed -E 's/^[^a-zA-Z0-9._/-]+//; s/[[:space:]].*//')

# 1. Validation: Prevent deleting main branch / root repository
if [[ "$branch_clean" == "main" || "$branch_clean" == "master" ]]; then
    printf "\n\033[1;31m󰅖 Cannot delete default base branch '%s'!\033[0m\n" "$branch_clean" >/dev/tty
    sleep 1.2
    exit 0
fi

# 2. Check if currently attached to this session in Tmux
cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
is_current_session=0
if [[ -n "$cur_session" && ( "$cur_session" == "$session_name" || "$cur_session" == "_$session_name" ) ]]; then
    is_current_session=1
fi

# 3. Remove Worktree purely via Native Git
if [[ $force -eq 1 ]]; then
    git worktree remove -f "$wt_path" >/dev/null 2>&1 || (rm -rf "$wt_path" && git worktree prune >/dev/null 2>&1) || true
else
    git worktree remove "$wt_path" >/dev/null 2>&1 || git worktree remove -f "$wt_path" >/dev/null 2>&1 || true
fi

# Delete Git branch unless --no-delete-branch was specified
if [[ $keep_branch -eq 0 ]]; then
    git branch -D "$branch_clean" >/dev/null 2>&1 || true
fi

# 4. Handle Tmux session cleanup & redirection unless --no-tmux was specified
if [[ $no_tmux -eq 0 ]]; then
    if [[ $is_current_session -eq 1 ]]; then
        # Switch to previous session before killing current session
        if command -v sesh >/dev/null 2>&1; then
            sesh last >/dev/null 2>&1 || tmux switch-client -l >/dev/null 2>&1 || tmux switch-client -n >/dev/null 2>&1
        else
            tmux switch-client -l >/dev/null 2>&1 || tmux switch-client -n >/dev/null 2>&1
        fi
        # Kill the deleted session
        tmux kill-session -t "$session_name" >/dev/null 2>&1 || tmux kill-session -t "_$session_name" >/dev/null 2>&1 || true
        exit 0
    else
        # If the session was in background, kill it cleanly
        if tmux has-session -t "$session_name" >/dev/null 2>&1; then
            tmux kill-session -t "$session_name" >/dev/null 2>&1 || true
        elif tmux has-session -t "_$session_name" >/dev/null 2>&1; then
            tmux kill-session -t "_$session_name" >/dev/null 2>&1 || true
        fi
    fi
fi
