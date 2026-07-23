#!/usr/bin/env zsh
# Install ai-usagebar

if command -v ai-usagebar &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bai-usagebar%b already installed"
  return 0
fi

if command -v yay &>/dev/null; then
  print -P "%F{blue}  →%f Installing %Bai-usagebar-bin%b via AUR..."
  if pkg_install ai-usagebar-bin; then
    return 0
  fi
fi

print -P "%F{blue}  →%f Building %Bai-usagebar%b from GitHub via cargo..."
if command -v cargo &>/dev/null; then
  cargo install --git https://github.com/akitaonrails/ai-usagebar
else
  print -P "  %F{red}✗%f Cargo is required to build %Bai-usagebar%b"
  return 1
fi
