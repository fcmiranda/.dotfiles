#!/usr/bin/env sh
# opencode-state.sh <window_id>
# Called by tmux #() in window-status-format every status-interval seconds.
# Reads /tmp/opencode-state-<window_id> written by hooker.ts and outputs a
# styled tmux format string. Handles the busy spinner using the system clock
# so the animation is driven entirely by tmux — zero plugin overhead.

SCRIPT_DIR=$(cd "$(dirname "$0")" && pwd)
_tmux_style="$HOME/.config/omarchy/current/theme/tmux-style.sh"
[ -f "$_tmux_style" ] || _tmux_style="$SCRIPT_DIR/tmux-style.sh"
# shellcheck source=/dev/null
. "$_tmux_style"
unset _tmux_style

f="/tmp/opencode-state-$1"
[ -f "$f" ] || exit 0

s=$(cat "$f")

case "$s" in
  busy)
    case "$TMUX_SPINNER_NAME" in
      minidot)   frames='⠋ ⠙ ⠹ ⠸ ⠼ ⠴ ⠦ ⠧ ⠇ ⠏'; fps=83  ;;
      line)      frames='| / - \';                fps=100 ;;
      jump)      frames='⢄ ⢂ ⢁ ⡁ ⡈ ⡐ ⡠';        fps=100 ;;
      pulse)     frames='█ ▓ ▒ ░';               fps=125 ;;
      points)    frames='∙∙∙ ●∙∙ ∙●∙ ∙∙●';       fps=143 ;;
      meter)     frames='▱▱▱ ▰▱▱ ▰▰▱ ▰▰▰ ▰▰▱ ▰▱▱ ▱▱▱'; fps=143 ;;
      hamburger) frames='☱ ☲ ☴ ☲';               fps=333 ;;
      ellipsis)  frames='· .. ... ..';            fps=333 ;;
      globe)     frames='🌍 🌎 🌏';               fps=250 ;;
      moon)      frames='🌑 🌒 🌓 🌔 🌕 🌖 🌗 🌘'; fps=125 ;;
      monkey)    frames='🙈 🙉 🙊';               fps=333 ;;
      arc)       frames='◜ ◠ ◝ ◞ ◡ ◟';           fps=150 ;;
      nerd)      frames='    '; fps=100 ;;
      nerdarc)   frames='◜  ◝ ◞ ◡ ◟ '; fps=120 ;;
      *)         frames='⣾ ⣽ ⣻ ⢿ ⡿ ⣟ ⣯ ⣷';       fps=100 ;;
    esac
    n=$(printf '%s' "$frames" | wc -w | tr -d ' ')
    now_ms=$(date +%s%3N)
    idx=$(( (now_ms / fps) % n ))
    p=$(printf '%s' "$frames" | tr ' ' '\n' | sed -n "$((idx + 1))p")
    printf " #[fg=%s]%s#[fg=default]" "$TMUX_SPINNER_COLOR" "$p"
    ;;
  idle)       printf ' #[fg=green]#[fg=default]'         ;;
  retry)      printf ' #[fg=colour208]#[fg=default]'     ;;
  permission) printf ' #[fg=red]#[fg=default]'           ;;
esac
