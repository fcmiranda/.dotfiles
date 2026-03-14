#!/usr/bin/env zsh

# Install hyprland-video-wallpapers and its dependencies
# https://github.com/XclusivVv/hyprland-video-wallpapers

set -e

# Install dependencies
local -a deps=(python python-gobject gtk4 libadwaita mpv ffmpeg jq socat hyprpaper)
for dep in "${deps[@]}"; do
  if ! pkg_is_installed "$dep"; then
    print -P "  %F{yellow}→%f Installing dependency %B${dep}%b..."
    pkg_install "$dep"
  fi
done

# Clone or update the repo
local repo_dir="${HOME}/.local/share/hyprland-video-wallpapers"

if [[ -d "$repo_dir/.git" ]]; then
  print -P "  %F{cyan}✓%f Repository already cloned, pulling latest..."
  git -C "$repo_dir" pull --ff-only
else
  print -P "  %F{green}→%f Cloning hyprland-video-wallpapers..."
  git clone --depth=1 https://github.com/XclusivVv/hyprland-video-wallpapers "$repo_dir"
fi

print -P "  %F{green}✓%f hyprland-video-wallpapers installed to %B${repo_dir}%b"
print -P "  %F{blue}ℹ%f Run %Bpython ${repo_dir}/app.py%b to launch the setup GUI"
