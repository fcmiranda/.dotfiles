#!/usr/bin/env zsh
# Install mcat (Terminal image, video, and Markdown viewer)
# https://github.com/Skardyy/mcat

if command -v mcat &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bmcat%b already installed"
  return 0
fi

if command -v yay &>/dev/null; then
  print -P "%F{blue}  →%f Installing %Bmcat-bin%b via AUR..."
  if pkg_install mcat-bin; then
    return 0
  fi
fi

print -P "%F{blue}  →%f Building %Bmcat%b via cargo..."
if command -v cargo &>/dev/null; then
  cargo install mcat
else
  print -P "  %F{red}✗%f Cargo is required to build %Bmcat%b"
  return 1
fi
