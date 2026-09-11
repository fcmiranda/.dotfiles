#!/usr/bin/env sh
# scrollback-view.sh — full scrollback -> view-only nvim (prefix+C-e).
# Capture and viewer are split so a capture failure can never silently
# swallow the binding: failures show a display-message and log to
# /tmp/scrollback-view.err instead of opening an empty editor.
set -u

ERRLOG=/tmp/scrollback-view.err
OUT=/tmp/tmux_scrollback.ansi

[ -n "${TMUX:-}" ] || { echo "scrollback-view: fora do tmux" >&2; exit 1; }

if ! tmux capture-pane -epJS - 2>"$ERRLOG" | sed '/^$/d' > "$OUT"; then
  tmux display-message "scrollback: capture-pane falhou (ver $ERRLOG)"
  exit 1
fi
if [ ! -s "$OUT" ]; then
  tmux display-message "scrollback: pane vazio, nada para abrir"
  exit 1
fi
tmux new-window 'nvim -c "silent! BaleiaColorize" -c "setlocal nomodified nomodifiable" -c "normal G" /tmp/tmux_scrollback.ansi'
