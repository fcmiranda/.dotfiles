#!/usr/bin/env zsh
# Install ai-jail
# On x86_64: installs via the ai-jail-bin AUR package.
# On aarch64 (and others): builds from source using cargo.

if command -v ai-jail &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bai-jail%b already installed"
  return 0
fi

if [[ "$(uname -m)" == "x86_64" ]]; then
  print -P "%F{blue}  →%f x86_64 detected — installing via AUR (ai-jail-bin)..."
  pkg_install ai-jail-bin || return 1
  return 0
fi

print -P "%F{blue}  →%f Non-x86_64 detected — building %Bai-jail%b from GitHub via cargo..."

if ! command -v cargo &>/dev/null; then
  if [[ -f "$HOME/.cargo/env" ]]; then
    source "$HOME/.cargo/env"
  fi
fi

if command -v cargo &>/dev/null; then
  cargo install --git https://github.com/akitaonrails/ai-jail
else
  print -P "  %F{red}✗%f Cargo is required to build %Bai-jail%b on aarch64"
  return 1
fi
