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

# 2. Confirmation prompt
printf "\n\033[1;33m🗑️  Remove worktree \033[1;31m%s\033[1;33m (\033[1;36m%s\033[1;33m)? [y/N]: \033[0m" "$branch_clean" "$wt_path" >/dev/tty
read -r ans </dev/tty
case "$ans" in
    [yY]*) ;;
    *) exit 0 ;;
esac

# 3. Check if currently attached to this session in Tmux
cur_session=$(tmux display-message -p '#{session_name}' 2>/dev/null)
is_current_session=0
if [[ -n "$cur_session" && ( "$cur_session" == "$session_name" || "$cur_session" == "_$session_name" ) ]]; then
    is_current_session=1
fi

# 4. Remove Worktree from Git
printf "\n\033[1;33mRemoving worktree '%s'...\033[0m\n" "$wt_path" >/dev/tty
if command -v wt >/dev/null 2>&1; then
    wt remove "$wt_path" 2>/dev/null || wt remove -f "$branch_clean" 2>/dev/null || git worktree remove -f "$wt_path" 2>/dev/null
else
    git worktree remove -f "$wt_path" 2>/dev/null || true
fi

# Also delete branch if not already deleted
git branch -D "$branch_clean" 2>/dev/null || true

# 5. Handle Tmux session cleanup & redirection
if [[ $is_current_session -eq 1 ]]; then
    printf "\033[1;32m✓ Worktree removed. Switching to last Tmux session...\033[0m\n" >/dev/tty
    # Switch to previous session before killing current session
    if command -v sesh >/dev/null 2>&1; then
        sesh last 2>/dev/null || tmux switch-client -l 2>/dev/null || tmux switch-client -n 2>/dev/null
    else
        tmux switch-client -l 2>/dev/null || tmux switch-client -n 2>/dev/null
    fi
    # Kill the deleted session
    tmux kill-session -t "$session_name" 2>/dev/null || tmux kill-session -t "_$session_name" 2>/dev/null || true
    exit 0
else
    # If the session was in background, kill it cleanly
    if tmux has-session -t "$session_name" 2>/dev/null; then
        tmux kill-session -t "$session_name" 2>/dev/null || true
    elif tmux has-session -t "_$session_name" 2>/dev/null; then
        tmux kill-session -t "_$session_name" 2>/dev/null || true
    fi
    printf "\033[1;32m✓ Worktree and session removed successfully.\033[0m\n" >/dev/tty
fi
