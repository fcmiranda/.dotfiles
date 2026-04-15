#!/usr/bin/env sh

set -eu

msg=${1:-OpenCode}
timeout=${2:-2}

exec tmux display-popup \
  -E -N \
  -x 0 -y 0 \
  -w 30% -h 3 \
  -s "fg=colour15,bg=colour236" \
  -S "fg=colour240" \
  sh -c "printf '  %s' \"$msg\"; sleep $timeout"
