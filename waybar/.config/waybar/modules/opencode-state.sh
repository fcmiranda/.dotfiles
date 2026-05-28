#!/usr/bin/env sh
# opencode-state.sh — outputs current OpenCode state as JSON for the waybar custom/opencode module.
#
# State is written by hooker.ts to /tmp/opencode-waybar-state (plain word: busy/idle/question/permission/retry).
# Waybar polls this script every second (interval: 1) and also on SIGRTMIN+13 (signal: 13) for instant
# response to state changes.
#
# Icons mirror the tmux bell/state icons used by hooker.ts:
#   busy       → arc spinner (time-based animation)   — accent/yellow
#   idle       → 󱥂  finished                          — teal   (#94e2d5)
#   question   → 󱜻  needs your input                  — mauve  (#cba6f7)
#   permission → 󱅭  needs permission                  — red    (#f38ba8)
#   retry      → 󰨄  retrying                          — yellow (#f9e2af)

STATE_FILE="/tmp/opencode-waybar-state"

[ -f "$STATE_FILE" ] || exit 0

state=$(cat "$STATE_FILE" 2>/dev/null)
[ -z "$state" ] && exit 0

case "$state" in
  busy)
    # Arc spinner frames — driven by the system clock (same approach as opencode-state.sh for tmux).
    frames='◜ ◠ ◝ ◞ ◡ ◟'
    fps=150
    n=6
    now_ms=$(date +%s%3N)
    idx=$(( (now_ms / fps) % n ))
    frame=$(printf '%s' "$frames" | tr ' ' '\n' | sed -n "$((idx + 1))p")
    printf '{"text":"%s","class":"busy","tooltip":"OpenCode: working…"}\n' "$frame"
    ;;
  idle)
    printf '{"text":"󱥂","class":"idle","tooltip":"OpenCode: finished"}\n'
    ;;
  question)
    printf '{"text":"󱜻","class":"question","tooltip":"OpenCode: has a question for you"}\n'
    ;;
  permission)
    printf '{"text":"󱅭","class":"permission","tooltip":"OpenCode: needs permission"}\n'
    ;;
  retry)
    printf '{"text":"󰨄","class":"retry","tooltip":"OpenCode: retrying…"}\n'
    ;;
  *)
    exit 0
    ;;
esac
