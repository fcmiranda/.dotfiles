#!/usr/bin/env zsh

# Fix for ghostty-terminfo conflict with ncurses
# The error "ghostty-terminfo-git: /usr/share/terminfo/g/ghostty exists in filesystem (owned by ncurses)"
# is common on some systems. We force overwrite the conflicting file.

if ! pkg_is_installed ghostty; then
  print -P "  %F{yellow}→%f Forcing installation of ghostty to resolve terminfo conflict..."
  if command -v yay &>/dev/null; then
    yay -S --noconfirm --overwrite "/usr/share/terminfo/g/ghostty" ghostty-git
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm --overwrite "/usr/share/terminfo/g/ghostty" ghostty
  else
    print -P "  %F{red}✗%f No package manager found"
    return 1
  fi
fi
