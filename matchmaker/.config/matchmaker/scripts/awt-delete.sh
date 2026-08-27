#!/usr/bin/env bash
# Matchmaker Agent Worktree Delete Handler: deletes worktree, kills Tmux session, and switches to last session if active

session_name="$1"
wt_path="$2"
branch_raw="$3"

branch_clean=$(echo "$branch_raw" | sed "s/^[ @^]*//; s/ .*//")

# 1. Validation: Prevent deleting main branch / root repository
if [[ "$branch_clean" == "main" || "$branch_clean" == "master" ]]; then
    printf "\n\033[1;31m✖ Cannot delete default base branch '%s'!\033[0m\n" "$branch_clean" >/dev/tty
    sleep 1.2
    exit 0
fi

# 2. Check if worktree has custom commits or uncommitted changes
base_branch=$(git -C "$wt_path" config "branch.${branch_clean}.base" 2>/dev/null)
base_branch="${base_branch:-main}"

ahead_commits=$(git -C "$wt_path" rev-list --count "${base_branch}..HEAD" 2>/dev/null || echo "0")
dirty_count=$(git -C "$wt_path" status --porcelain 2>/dev/null | wc -l)

# If worktree has commits or dirty files -> require Action Box confirmation!
if [[ "$ahead_commits" -gt 0 || "$dirty_count" -gt 0 ]]; then
    details=""
    if [[ "$ahead_commits" -gt 0 ]]; then
        details+="${ahead_commits} commit(s)"
    fi
    if [[ "$dirty_count" -gt 0 ]]; then
        [[ -n "$details" ]] && details+=", "
        details+="${dirty_count} uncommitted file(s)"
    fi

    export MM_CONFIRM_ITEMS=$(printf "ACTION\tLABEL\ncancel\t🛡️  No, Cancel (Keep %s)\ndelete\t🗑️  Yes, Force Delete (%s with %s)\n" "$branch_clean" "$branch_clean" "$details")

    confirm_choice=$(mm -o awt-confirm)

    # If user cancelled, pressed Esc, or chose No -> exit cleanly
    if [[ "$confirm_choice" != "delete" ]]; then
        exit 0
    fi
fi

# 3. Check if currently attached to this session in Tmux
cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
is_current_session=0
if [[ -n "$cur_session" && ( "$cur_session" == "$session_name" || "$cur_session" == "_$session_name" ) ]]; then
    is_current_session=1
fi

# 4. Remove Worktree from Git
if command -v wt >/dev/null 2>&1; then
    wt remove "$wt_path" >/dev/null 2>&1 || wt remove -f "$branch_clean" >/dev/null 2>&1 || git worktree remove -f "$wt_path" >/dev/null 2>&1
else
    git worktree remove -f "$wt_path" >/dev/null 2>&1 || true
fi

# Also delete branch if not already deleted
git branch -D "$branch_clean" >/dev/null 2>&1 || true

# 5. Handle Tmux session cleanup & redirection
if [[ $is_current_session -eq 1 ]]; then
    printf "\033[1;32m✓ Worktree removed. Switching to last Tmux session...\033[0m\n" >/dev/tty
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
