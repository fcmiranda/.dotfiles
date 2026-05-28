#!/usr/bin/env zsh
set -euo pipefail

if command -v apm &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bapm%b already installed"
  return 0
fi

if ! command -v curl &>/dev/null; then
  print -P "  %F{yellow}→%f Installing %Bcurl%b via package manager..."
  pkg_install curl || {
    print -P "  %F{red}✗%f Failed to install %Bcurl%b"
    return 1
  }
fi

print -P "  %F{yellow}→%f Installing %Bapm-unix%b via installer script..."
curl -sSL https://aka.ms/apm-unix | sh
print -P "  %F{green}✓%f %Bapm-unix%b installed"
