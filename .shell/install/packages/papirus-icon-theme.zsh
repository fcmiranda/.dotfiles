#!/usr/bin/env zsh

# Installer for papirus-icon-theme (provides complete Freedesktop vector SVG icons)

if ! pkg_is_installed papirus-icon-theme; then
  print -P "  %F{yellow}→%f Installing papirus-icon-theme..."
  if command -v yay &>/dev/null; then
    yay -S --noconfirm papirus-icon-theme
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm papirus-icon-theme
  else
    print -P "  %F{red}✗%f No package manager found"
    return 1
  fi
fi
