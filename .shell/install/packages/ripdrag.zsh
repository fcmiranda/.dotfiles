#!/usr/bin/env zsh

if ! command -v ripdrag &>/dev/null; then
  print -P "  %F{green}→%f Installing %Bripdrag%b via cargo..."
  cargo install ripdrag
fi

if command -v ripdrag &>/dev/null; then
  print -P "  %F{green}✓%f %Bripdrag%b is installed"
else
  print -P "  %F{red}✗%f %Bripdrag%b installation failed"
  return 1
fi
