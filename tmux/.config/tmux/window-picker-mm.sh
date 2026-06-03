#!/usr/bin/env sh
# window-picker-mm.sh — cross-session window picker with OpenCode state using mm
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
  "$ITEMS_SCRIPT | ~/.cargo/bin/mm \
    start.sort=false \
    start.ansi=true \
    'c.s=\\t' \
    tui.mouse=true \
    c.n=name c.n=session c.n=idx c.n=display \
    'b.Start=ToggleColumn(name)|||ToggleColumn(session)|||ToggleColumn(idx)' \
    --group-prefix '#' \
    results.spinner_prefix='@SPIN@' \
    results.spinner='$TMUX_SPINNER_NAME' \
    --color 'spinner:$TMUX_SPINNER_COLOR' \
    query.status_inline=true \
    query.prompt=' ' \
    results.current_prefix=' ' \
    --nav \
    --color '$TMUX_COLOR_SPEC' \
    p.wrap=false \
    'P=command=sess=\"{=session}\"; tmux capture-pane -ep -t \"\${sess}:{=idx}\" 2>/dev/null || printf \"  \033[38;2;146;131;116m(no preview)\033[0m\n\"|||side=right|||percentage=50|||title={item}' \
  | (read chosen && [ -n \"\$chosen\" ] && \
      session=\$(printf '%s' \"\$chosen\" | cut -f2) && \
      idx=\$(printf '%s' \"\$chosen\" | cut -f3) && \
      [ -n \"\$idx\" ] && \
      tmux switch-client -t \"\${session}:\${idx}\"); true"
