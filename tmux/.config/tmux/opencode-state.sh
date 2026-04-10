#!/usr/bin/env sh
# opencode-state.sh <window_id>
# Called by tmux #() in window-status-format every status-interval seconds.
# Reads /tmp/opencode-state-<window_id> written by hooker.ts and outputs a
# styled tmux format string. Handles the busy spinner using the system clock
# so the animation is driven entirely by tmux — zero plugin overhead.

f="/tmp/opencode-state-$1"
[ -f "$f" ] || exit 0

s=$(cat "$f")

case "$s" in
  busy)
    # --- Spinner sets (uncomment one) ---

    # Braille dots (10 frames — fast, classic)
    # frames='⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏'
    # n=10

    # Quarter-circle fills (4 frames — bold, slow-friendly)
    # frames='◐ ◓ ◑ ◒'
    # n=4

    # Arc (6 frames — smooth sweep)
    # frames='◜ ◠ ◝ ◞ ◡ ◟'
    # n=6

    # Dots bounce (6 frames)
    frames='⣾ ⣽ ⣻ ⢿ ⡿ ⣟'
    n=6

    # Box corners (4 frames — minimal)
    # frames='▖ ▘ ▝ ▗'
    # n=4

    i=$(( $(date +%s) % n ))
    p=$(echo "$frames" | tr ' ' '\n' | sed -n "$((i+1))p")
    printf ' #[fg=yellow]%s#[fg=default]' "$p"
    ;;
  idle)       printf ' #[fg=green]#[fg=default]'         ;;
  retry)      printf ' #[fg=colour208]#[fg=default]'     ;;
  permission) printf ' #[fg=red]#[fg=default]'           ;;
esac
