#!/usr/bin/env zsh
set -euo pipefail

if command -v bun &>/dev/null; then
  print -P "%F{green}  ✓%f bun already installed ($(bun --version))"
  return 0
fi

print -P "%F{blue}  →%f Installing bun..."
curl -fsSL https://bun.sh/install | bash

print -P "%F{green}  ✓%f bun installed"
