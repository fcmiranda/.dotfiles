#!/usr/bin/env zsh

if ! command -v cargo-zigbuild &>/dev/null; then
  print -P "  %F{green}→%f Installing %Bcargo-zigbuild%b via cargo..."
  cargo install cargo-zigbuild
fi

if command -v cargo-zigbuild &>/dev/null; then
  print -P "  %F{green}✓%f %Bcargo-zigbuild%b is installed"
else
  print -P "  %F{red}✗%f %Bcargo-zigbuild%b installation failed"
  return 1
fi
