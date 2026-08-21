#!/usr/bin/env bash
# sesh-fzf.sh — interactive sesh session picker using fzf in a tmux popup

REAL_SCRIPT=$(readlink -f "$0" 2>/dev/null || realpath "$0")

if [ -z "${TMUX_POPUP:-}" ]; then
  exec tmux display-popup -b rounded -w 80% -h 75% -E "TMUX_POPUP=1 $REAL_SCRIPT"
fi

session=$(sesh list --icons | grep -Ev '(_lazygitrs|_popups|[[:space:]]+\.)' | fzf \
  --no-sort --ansi \
  --border-label ' ⚡ sesh ' \
  --prompt '⚡  ' \
  --header '  ^a all ^t tmux ^g configs ^x zoxide ^d kill ^f find' \
  --bind 'tab:down,btab:up' \
  --bind 'ctrl-a:change-prompt(⚡  )+reload(sesh list --icons | grep -Ev "(_lazygitrs|_popups|[[:space:]]+\.)")' \
  --bind 'ctrl-t:change-prompt(🪟  )+reload(sesh list -t --icons | grep -Ev "(_lazygitrs|_popups|[[:space:]]+\.)")' \
  --bind 'ctrl-g:change-prompt(⚙️  )+reload(sesh list -c --icons)' \
  --bind 'ctrl-x:change-prompt(📁  )+reload(sesh list -z --icons)' \
  --bind 'ctrl-f:change-prompt(🔎  )+reload(fd -H -d 2 -t d -E .Trash . ~ 2>/dev/null || find ~ -maxdepth 2 -type d)' \
  --bind 'ctrl-d:execute(sess={}; sess=${sess#* }; tmux kill-session -t "$sess" 2>/dev/null)+change-prompt(⚡  )+reload(sesh list --icons | grep -Ev "(_lazygitrs|_popups|[[:space:]]+\.)")' \
  --preview-window 'right:55%' \
  --preview 'sesh preview {}')

if [ -n "$session" ]; then
  sesh connect "$session"
fi
