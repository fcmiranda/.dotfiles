#!/usr/bin/env zsh

if ! command -v cargo &>/dev/null; then
  print -P "  %F{green}→%f Installing %Bcargo%b via rustup..."
  curl --proto '=https' --tlsv1.2 -sSf https://sh.rustup.rs | sh -s -- -y --no-modify-path
  
  # Source the environment for the current script
  source "$HOME/.cargo/env"
fi

if command -v cargo &>/dev/null; then
  print -P "  %F{green}✓%f %Bcargo%b is installed"
else
  print -P "  %F{red}✗%f %Bcargo%b installation failed"
  return 1
fi
