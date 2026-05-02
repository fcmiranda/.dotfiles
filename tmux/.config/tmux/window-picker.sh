#!/usr/bin/env sh
# window-picker.sh — cross-session window picker with OpenCode state
# All sessions and their windows, grouped, with color-coded AI state and live preview.

SCRIPT_DIR=$(dirname "$0")
ITEMS_SCRIPT="${SCRIPT_DIR}/window-picker-items.sh"
# shellcheck source=/dev/null
. "${SCRIPT_DIR}/opencode-style.sh"

tmux display-popup \
  -b rounded \
  -S "fg=$OPENCODE_POPUP_BORDER_COLOR" \
  -w 80% \
  -h 55% \
  -E \
  "$ITEMS_SCRIPT | /home/fecavmi/go/bin/bfzf \
    -group-prefix '#' \
    -spinner-prefix '@SPIN@' \
    -spinner '$OPENCODE_SPINNER_NAME' \
    -spinner-color='$OPENCODE_SPINNER_COLOR' \
    -with-nth 3 \
    -no-sort \
    -no-input \
    --height 100% \
    -header='' \
    -cursor='▸ ' \
    -no-info \
    -color='border:239,header:245,cursor:214,fg+:223' \
    -reload-cmd='$ITEMS_SCRIPT' \
    -reload-interval=1000 \
    -preview='
      sess={1}; idx={2}
      tmux capture-pane -ep -t \"\${sess}:\${idx}\" 2>/dev/null \
        || printf \"  \033[38;2;146;131;116m(no preview)\033[0m\n\"
    ' \
    -preview-position=right \
    -preview-size=50 \
  | (read chosen && [ -n \"\$chosen\" ] && \
      session=\$(printf '%s' \"\$chosen\" | cut -f1) && \
      idx=\$(printf '%s' \"\$chosen\" | cut -f2) && \
      [ -n \"\$idx\" ] && \
      tmux switch-client -t \"\${session}:\${idx}\"); true"
