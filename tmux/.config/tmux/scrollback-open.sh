#!/usr/bin/env sh
# scrollback-open.sh — open a file[:line[:col]] token in $EDITOR (extrakto edit).
# Usage: scrollback-open.sh <token> [cwd] | scrollback-open.sh --check <token> [cwd]
# --check only prints resolution (used by tests): "file|line|col|exists".
set -u

CHECK=0
if [ "${1:-}" = "--check" ]; then CHECK=1; shift; fi
t="${1:-}"
cwd="${2:-}"

file="$t"; line=1; col=1
if printf '%s' "$t" | grep -qE ':[0-9]+(:[0-9]+)?$'; then
  suffix="$(printf '%s' "$t" | grep -oE ':[0-9]+(:[0-9]+)?$')"
  file="${t%"$suffix"}"
  line="$(printf '%s' "$suffix" | cut -d: -f2)"
  col="$(printf '%s' "$suffix" | cut -d: -f3)"
  [ -n "$col" ] || col=1
fi
case "$file" in '~'*) file="$HOME${file#'~'}";; esac

exists=0
if [ -n "$cwd" ]; then
  [ -f "$cwd/$file" ] && exists=1 && file="$cwd/$file"
elif [ -f "$file" ]; then
  exists=1
fi

if [ "$CHECK" = "1" ]; then
  printf '%s|%s|%s|%s\n' "$file" "$line" "$col" "$exists"
  exit 0
fi
if [ "$exists" != "1" ]; then
  tmux display-message "scrollback: não é arquivo: $file"
  exit 0
fi
exec ${EDITOR:-nvim} +"call cursor($line,$col)" -- "$file"
