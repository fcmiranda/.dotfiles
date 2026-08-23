#!/usr/bin/env zsh
# Install leaf (Terminal Markdown previewer)
# https://github.com/RivoLink/leaf

if command -v leaf &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bleaf%b already installed"
  return 0
fi

if [[ "$(uname -m)" == "x86_64" ]] && command -v yay &>/dev/null; then
  print -P "%F{blue}  →%f x86_64 detected — installing via AUR (leaf-markdown-viewer-bin)..."
  if pkg_install leaf-markdown-viewer-bin && command -v leaf &>/dev/null; then
    return 0
  fi
fi

print -P "%F{blue}  →%f Installing %Bleaf%b via official install script..."
if curl -fsSL https://raw.githubusercontent.com/RivoLink/leaf/main/scripts/install.sh | sh; then
  if command -v leaf &>/dev/null; then
    print -P "  %F{green}✓%f %Bleaf%b is installed"
    return 0
  fi
fi

if command -v cargo &>/dev/null; then
  print -P "%F{blue}  →%f Installing %Bleaf%b via cargo..."
  cargo install leaf-markdown-viewer
fi

if command -v leaf &>/dev/null; then
  print -P "  %F{green}✓%f %Bleaf%b is installed"
else
  print -P "  %F{red}✗%f %Bleaf%b installation failed"
  return 1
fi
