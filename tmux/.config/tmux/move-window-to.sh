#!/usr/bin/env bash
# Move the current window to a target index by swapping it into place.
# Windows between the current and target indices get shifted towards the
# current window's old position (i.e. a rotation of the window list in range).
#
# Example: current window is 3, target is 1
#   -> window 3 becomes 1, window 1 becomes 2, window 2 becomes 3
set -euo pipefail

target="${1:?usage: move-window-to.sh <index>}"

cur="$(tmux display-message -p '#I')"

if [ "$cur" -lt "$target" ]; then
  i="$cur"
  while [ "$i" -lt "$target" ]; do
    tmux swap-window -s "$i" -t "$((i + 1))"
    i=$((i + 1))
  done
elif [ "$cur" -gt "$target" ]; then
  i="$cur"
  while [ "$i" -gt "$target" ]; do
    tmux swap-window -s "$i" -t "$((i - 1))"
    i=$((i - 1))
  done
fi

# Focus the moved window at its new index
tmux select-window -t "$target"