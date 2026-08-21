#!/usr/bin/env zsh

if ! command -v cross &>/dev/null; then
  print -P "  %F{green}→%f Installing %Bcross%b via cargo..."
  cargo install cross --git https://github.com/cross-rs/cross
fi

if command -v cross &>/dev/null; then
  print -P "  %F{green}✓%f %Bcross%b is installed"
else
  print -P "  %F{red}✗%f %Bcross%b installation failed"
  return 1
fi
