#!/usr/bin/env sh
# window-picker.sh — cross-session window picker with OpenCode state
# All sessions and their windows, grouped, with color-coded AI state and live preview.

SCRIPT_DIR=$(dirname "$0")
ITEMS_SCRIPT="${SCRIPT_DIR}/window-picker-items.sh"

chosen=$("$ITEMS_SCRIPT" | /home/fecavmi/go/bin/bfzf \
  -popup center,80%,55% \
  -group-prefix '#' \
  -spinner-prefix '@SPIN@' \
  -with-nth 3 \
  -no-sort \
  -no-input \
  --height 90% \
  -header='↑↓ navigate  •  Enter switch  •  Esc cancel' \
  -cursor="▸ " \
  -no-info \
  -color="border:239,header:245,cursor:214,fg+:223" \
  -reload-cmd="$ITEMS_SCRIPT" \
  -reload-interval=1000 \
  -preview='
    sess={1}; idx={2}
    tmux capture-pane -ep -t "${sess}:${idx}" 2>/dev/null \
      || printf "  \033[38;2;146;131;116m(no preview)\033[0m\n"
  ' \
  -preview-position='right' \
  -preview-size=50)

[ -z "$chosen" ] && exit 0

# Extract session and window index from tab-delimited fields
session=$(printf '%s' "$chosen" | cut -f1)
idx=$(printf '%s' "$chosen" | cut -f2)

[ -z "$idx" ] && exit 0

tmux switch-client -t "${session}:${idx}"
