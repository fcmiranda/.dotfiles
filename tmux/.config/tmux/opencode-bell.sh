#!/usr/bin/env sh

set -eu

msg=${1:-OpenCode}
timeout=${2:-2}

exec tmux display-popup \
  -E \
  -w 40% -h 5 \
  -s "fg=colour15,bg=colour236" \
  -S "fg=colour240" \
  sh -c "printf '\n  %s\n' \"$msg\"; sleep $timeout"
