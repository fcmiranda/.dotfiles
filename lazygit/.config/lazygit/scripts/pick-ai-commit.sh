#!/usr/bin/env bash

set -euo pipefail

echo "lazycommit: picking AI commit..."

if ! command -v lazycommit >/dev/null 2>&1; then
  echo "lazycommit is not installed or not in PATH."
  exit 1
fi

if ! command -v fzf >/dev/null 2>&1; then
  echo "fzf is not installed or not in PATH."
  exit 1
fi

msgs="$(lazycommit commit -q || true)"
if [[ -z "${msgs//[[:space:]]/}" ]]; then
  echo "No AI commit messages generated."
  exit 0
fi

msg="$(printf '%s\n' "$msgs" | fzf --prompt='AI Commit Message > ' --height=40% --layout=reverse --border)"
if [[ -z "${msg:-}" ]]; then
  echo "Cancelled."
  exit 0
fi

action="$(printf 'direct\nedit\n' | fzf --prompt='Action > ' --height=20% --layout=reverse --border)"
if [[ -z "${action:-}" ]]; then
  echo "Cancelled."
  exit 0
fi

if [[ "$action" == "edit" ]]; then
  editor="${EDITOR:-nvim}"
  msg_file="$(git rev-parse --git-dir)/COMMIT_EDITMSG"
  printf '%s\n' "$msg" > "$msg_file"
  "$editor" "$msg_file"
  if [[ ! -s "$msg_file" ]]; then
    echo "Commit message is empty, commit aborted."
    exit 0
  fi
  git commit -F "$msg_file"
else
  git commit -m "$msg"
fi
