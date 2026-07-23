#!/usr/bin/env zsh
# Install ai-memory

if command -v ai-memory &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bai-memory%b already installed"
  return 0
fi

if command -v yay &>/dev/null; then
  print -P "%F{blue}  →%f Installing %Bai-memory-bin%b via AUR..."
  if pkg_install ai-memory-bin; then
    return 0
  fi
fi

print -P "%F{blue}  →%f Building %Bai-memory%b from GitHub via cargo..."
if command -v cargo &>/dev/null; then
  cargo install --git https://github.com/akitaonrails/ai-memory ai-memory-cli
else
  print -P "  %F{red}✗%f Cargo is required to build %Bai-memory%b"
  return 1
fi
