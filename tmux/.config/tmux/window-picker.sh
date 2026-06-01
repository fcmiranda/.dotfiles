#!/usr/bin/env sh
# window-picker.sh — cross-session window picker with OpenCode state
# All sessions and their windows, grouped, with color-coded AI state and live preview.

SCRIPT_DIR=$(dirname "$0")
ITEMS_SCRIPT="${SCRIPT_DIR}/window-picker-items.sh"
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="${SCRIPT_DIR}/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style"
unset _tmux_style

tmux display-popup \
  -b rounded \
  -w 80% \
  -h 55% \
  -E \
  "~/.cargo/bin/mm \
    start.command='$ITEMS_SCRIPT' \
    start.sort=false \
    start.ansi=true \
    'c.s=\\t' \
    tui.mouse=false \
    c.n=session c.n=idx c.n=display \
    'b.Start=ToggleColumn(session)|||ToggleColumn(idx)' \
    --group-prefix '#' \
    results.spinner_prefix='@SPIN@' \
    results.spinner='$TMUX_SPINNER_NAME' \
    --color 'spinner:$TMUX_SPINNER_COLOR' \
    query.status_inline=true \
    results.current_prefix='  ' \
    --color '$TMUX_BFZF_COLOR_SPEC' \
    'P=command=sess=\"{session}\"; sess=\"\${sess#@SPIN@}\"; idx=\"{idx}\"; tmux capture-pane -ep -t \"\${sess}:\${idx}\" 2>/dev/null || printf \"  \033[38;2;146;131;116m(no preview)\033[0m\n\"|||side=right|||percentage=50' \
  | (read chosen && [ -n \"\$chosen\" ] && \
      session=\$(printf '%s' \"\$chosen\" | cut -f1) && \
      session=\"\${session#@SPIN@}\" && \
      idx=\$(printf '%s' \"\$chosen\" | cut -f2) && \
      [ -n \"\$idx\" ] && \
      tmux switch-client -t \"\${session}:\${idx}\"); true"
