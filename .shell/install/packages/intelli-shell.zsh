#!/usr/bin/env zsh
# Install intelli-shell (Interactive command template and snippet manager)
# https://github.com/lasantosr/intelli-shell

if command -v intelli-shell &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bintelli-shell%b already installed"
  return 0
fi

_fetch_initial_tldr() {
  if [[ ! -f "${HOME}/.local/share/intelli-shell/storage.db3" ]]; then
    print -P "%F{blue}  →%f Populating initial tldr command templates..."
    intelli-shell tldr fetch &>/dev/null || true
  fi
}

# 1. Try official installer (pre-built binary into ~/.local/share/intelli-shell)
print -P "%F{blue}  →%f Installing %Bintelli-shell%b via official installer..."
if INTELLI_SKIP_PROFILE=1 sh -c "$(curl -fsSL https://raw.githubusercontent.com/lasantosr/intelli-shell/main/install.sh)" 2>/dev/null; then
  mkdir -p "${HOME}/.local/bin"
  ln -sf "${HOME}/.local/share/intelli-shell/bin/intelli-shell" "${HOME}/.local/bin/intelli-shell"
  _fetch_initial_tldr
  print -P "  %F{green}✓%f %Bintelli-shell%b installed"
  return 0
fi

# 2. Try pacman
if command -v pacman &>/dev/null; then
  print -P "%F{blue}  →%f Installing %Bintelli-shell%b via pacman..."
  if sudo pacman -S --noconfirm intelli-shell 2>/dev/null; then
    _fetch_initial_tldr
    return 0
  fi
fi

# 3. Try yay
if command -v yay &>/dev/null; then
  print -P "%F{blue}  →%f Installing %Bintelli-shell%b via yay..."
  if yay -S --noconfirm intelli-shell 2>/dev/null; then
    _fetch_initial_tldr
    return 0
  fi
fi

# 4. Fallback: cargo
print -P "%F{blue}  →%f Building %Bintelli-shell%b via cargo..."
if command -v cargo &>/dev/null; then
  cargo install intelli-shell
  _fetch_initial_tldr
  return 0
else
  print -P "  %F{red}✗%f Cargo is required to build %Bintelli-shell%b"
  return 1
fi
