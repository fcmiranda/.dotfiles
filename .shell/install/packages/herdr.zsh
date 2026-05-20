#!/usr/bin/env zsh

if ! command -v herdr &>/dev/null; then
  print -P "  %F{green}→%f Installing %Bherdr%b via official install script..."
  curl -fsSL https://herdr.dev/install.sh | sh
fi

if command -v herdr &>/dev/null; then
  print -P "  %F{green}✓%f %Bherdr%b is installed"
else
  print -P "  %F{red}✗%f %Bherdr%b installation failed"
  return 1
fi
