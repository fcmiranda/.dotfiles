#!/usr/bin/env sh
# window-picker-delete.sh — helper script to delete selected windows in window-picker

RAW_INPUT=$(cat)

[ -z "$RAW_INPUT" ] && exit 0

count=0
window_list=""

IFS='
'
for line in $RAW_INPUT; do
  [ -z "$line" ] && continue
  session=$(printf '%s' "$line" | cut -f4)
  idx=$(printf '%s' "$line" | cut -f2)
  if [ -n "$session" ] && [ -n "$idx" ]; then
    count=$((count + 1))
    window_list="${window_list}${session}:${idx}
"
  fi
done
unset IFS

[ "$count" -eq 0 ] && exit 0

if [ "$count" -gt 1 ]; then
  confirmed=0
  if command -v gum >/dev/null 2>&1; then
    if [ -n "$TMUX" ]; then
      tmux display-popup -b rounded -w 40 -h 10 -E "gum confirm 'remove $count windows?'" 2>/dev/null && confirmed=1
    else
      gum confirm "remove $count windows?" && confirmed=1
    fi
  else
    confirmed=1
  fi
  [ "$confirmed" -eq 0 ] && exit 0
fi

IFS='
'
for target in $window_list; do
  [ -n "$target" ] && tmux kill-window -t "$target" 2>/dev/null || true
done
unset IFS

exit 0
