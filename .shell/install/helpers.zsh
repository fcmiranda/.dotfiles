#!/usr/bin/env zsh

# Environment Setup
typeset -g INSTALL_DIR="${0:A:h}"
typeset -g PACKAGES_DIR="${INSTALL_DIR}/packages"
typeset -g PLUGINS_DIR="${INSTALL_DIR}/plugins"

# Install a package using available package manager
pkg_install() {
  local pkg="$1"
  local output
  local exit_code

  if command -v yay &>/dev/null; then
    # Try to install and capture output/exit code
    output=$(yay -S --noconfirm "$pkg" 2>&1)
    exit_code=$?
    
    if (( exit_code != 0 )); then
      if [[ "$output" == *"is not available for the 'aarch64' architecture"* ]]; then
        print -P "  %F{yellow}⚠%f %B${pkg}%b is not available for aarch64, skipping"
        return 0
      fi
      print -P "  %F{red}✗%f Failed to install %B${pkg}%b"
      echo "$output"
      return $exit_code
    fi
  elif command -v pacman &>/dev/null; then
    sudo pacman -S --noconfirm "$pkg"
  else
    print -P "  %F{red}✗%f No package manager found (yay/pacman)"
    return 1
  fi
}

# Check if a package is already installed (covers binaries and package DB)
pkg_is_installed() {
  local pkg="$1"

  # If the binary exists in PATH, consider it installed
  if command -v "$pkg" &>/dev/null; then
    return 0
  fi

  # Fallback to package database check
  if command -v yay &>/dev/null; then
    yay -Qi "$pkg" &>/dev/null && return 0
  elif command -v pacman &>/dev/null; then
    pacman -Qi "$pkg" &>/dev/null && return 0
  fi

  return 1
}

# Run package installation scripts
install_packages() {
  local -a items=("$@")

  (( ${#items[@]} == 0 )) && return

  print -P "%F{blue}:: %BPackages%b%f"

  for item in "${items[@]}"; do
    if pkg_is_installed "$item"; then
      print -P "  %F{cyan}✓%f %B${item}%b already installed"
      continue
    fi

    local script="${PACKAGES_DIR}/${item}.zsh"
    if [[ -f "$script" ]]; then
      print -P "  %F{green}→%f Installing %B${item}%b..."
      source "$script"
    else
      print -P "  %F{yellow}→%f Installing %B${item}%b via package manager..."
      pkg_install "$item"
    fi
  done
}

# Run plugin installation scripts
install_plugins() {
  local -a items=("$@")

  (( ${#items[@]} == 0 )) && return

  print -P "%F{blue}:: %BPlugins%b%f"

  for item in "${items[@]}"; do
    local script="${PLUGINS_DIR}/${item}.zsh"
    if [[ -f "$script" ]]; then
      print -P "  %F{green}→%f Installing %B${item}%b..."
      source "$script"
    else
      print -P "  %F{yellow}⚠%f Script for %B${item}%b not found"
    fi
  done
}
