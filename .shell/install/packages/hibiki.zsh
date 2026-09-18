#!/usr/bin/env zsh
# Install hibiki (Wayland GTK4 Layer Shell Keystroke Visualizer)
# https://github.com/linuxmobile/hibiki

if command -v hibiki &>/dev/null; then
  print -P "  %F{cyan}✓%f %Bhibiki%b already installed"
  return 0
fi

# Try AUR if available
if command -v yay &>/dev/null; then
  print -P "%F{blue}  →%f Checking AUR for %Bhibiki%b..."
  if pkg_install hibiki-bin 2>/dev/null || pkg_install hibiki 2>/dev/null; then
    if command -v hibiki &>/dev/null; then
      print -P "  %F{green}✓%f %Bhibiki%b installed via AUR"
      return 0
    fi
  fi
fi

# Ensure required libraries are installed
local -a DEPS=(gtk4 gtk4-layer-shell alsa-lib)
local -a MISSING=()

for dep in "${DEPS[@]}"; do
  if ! pacman -Q "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

if (( ${#MISSING[@]} > 0 )); then
  print -P "%F{yellow}  →%f Installing build dependencies: ${MISSING[*]}"
  pkg_install "${MISSING[@]}" || {
    print -P "  %F{red}✗%f Failed to install dependencies: ${MISSING[*]}"
    return 1
  }
fi

# Build from source via cargo
print -P "%F{blue}  →%f Building %Bhibiki%b from GitHub via cargo..."
if command -v cargo &>/dev/null; then
  if cargo install --git https://github.com/linuxmobile/hibiki hibiki; then
    # Ensure binary is in ~/.local/bin/
    if [[ -f "$HOME/.cargo/bin/hibiki" ]]; then
      mkdir -p "$HOME/.local/bin"
      ln -sf "$HOME/.cargo/bin/hibiki" "$HOME/.local/bin/hibiki"
    fi
    print -P "  %F{green}✓%f %Bhibiki%b installed successfully"
    return 0
  else
    print -P "  %F{red}✗%f Failed to build %Bhibiki%b via cargo"
    return 1
  fi
else
  print -P "  %F{red}✗%f Cargo is required to build %Bhibiki%b"
  return 1
fi
