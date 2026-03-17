#!/bin/zsh
set -euo pipefail

echo "=== Motion wallpaper installer for Omarchy / Hyprland ==="

# 1) Check for required commands
if ! command -v pacman >/dev/null 2>&1; then
  echo "This script expects a pacman-based system (Arch/Omarchy). Aborting."
  return 1
fi

# 2) Check if dependencies are installed
DEPENDENCIES=(mpv jq zenity meson ninja gcc pkg-config)
MISSING_DEPS=()

for dep in "${DEPENDENCIES[@]}"; do
  if ! command -v "$dep" >/dev/null 2>&1; then
    MISSING_DEPS+=("$dep")
  fi
done

if [ ${#MISSING_DEPS[@]} -eq 0 ]; then
  echo "All dependencies (mpv, jq, zenity, meson, ninja, gcc, pkg-config) are already installed."
else
  # Install required packages from official repos
  echo "Installing missing packages: ${MISSING_DEPS[*]}"
  sudo pacman -S --needed "${MISSING_DEPS[@]}"
fi

# 3) Build and install mpvpaper from source
echo
echo "Building and installing mpvpaper from source..."

# Remove existing directory if it exists to avoid git clone errors
rm -rf mpvpaper

# Clone the repository
git clone https://github.com/GhostNaN/mpvpaper
cd mpvpaper

# Build and install using meson
meson setup build
meson compile -C build
sudo meson install -C build

# Post-install cleanup
cd ..
rm -rf mpvpaper

# Verify mpvpaper is installed
if ! command -v mpvpaper >/dev/null 2>&1; then
  echo "ERROR: mpvpaper is not installed. Cannot continue."
  return 1
fi

# 4) Create ~/.local/bin if it doesn't exist
mkdir -p "$HOME/.local/bin"

# 5) Create the toggle script
cat << 'EOF' > "$HOME/.local/bin/motion-wallpaper-toggle"
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Motion Wallpaper"

# Helper to show an error dialog (falls back to echo)
zen_err() {
  if command -v zenity >/dev/null 2>&1; then
    zenity --error --title="$APP_NAME" --text="$1" || true
  else
    echo "ERROR: $1" >&2
  fi
}

zen_info() {
  if command -v zenity >/dev/null 2>&1; then
    zenity --info --title="$APP_NAME" --text="$1" || true
  else
    echo "$1"
  fi
}

zen_question() {
  if command -v zenity >/dev/null 2>&1; then
    zenity --question --title="$APP_NAME" --text="$1"
    return $?
  else
    # No zenity, default to "yes"
    return 0
  fi
}

# 1) If mpvpaper is already running, offer to stop it (toggle OFF)
if pgrep -x mpvpaper >/dev/null 2>&1; then
  if zen_question "Motion wallpaper is currently running.\n\nDo you want to stop it and return to your normal wallpaper?"; then
    pkill mpvpaper || true
    zen_info "Motion wallpaper stopped."
  fi
  exit 0
fi

# 2) No mpvpaper → toggle ON

# 2a) Check hyprctl
if ! command -v hyprctl >/dev/null 2>&1; then
  zen_err "hyprctl not found. Are you running Hyprland?"
  exit 1
fi

# 2b) Get monitor list
MON_JSON="$(hyprctl monitors -j 2>/dev/null || true)"
if [ -z "$MON_JSON" ]; then
  zen_err "Could not get monitor info from hyprctl."
  exit 1
fi

if ! command -v jq >/dev/null 2>&1; then
  zen_err "jq is not installed. Please install jq and try again."
  exit 1
fi

MONITORS="$(printf '%s\n' "$MON_JSON" | jq -r '.[].name')"
if [ -z "$MONITORS" ]; then
  zen_err "No monitors detected."
  exit 1
fi

MON_COUNT="$(printf '%s\n' "$MONITORS" | wc -l)"

# 2c) Choose monitor (if more than one)
SELECTED_MON=""
if [ "$MON_COUNT" -eq 1 ]; then
  SELECTED_MON="$MONITORS"
else
  # Build a list for Zenity
  MON_LIST=$(printf '%s\n' "$MONITORS" | awk '{print NR, $1}')
  SELECTED_MON=$(echo "$MON_LIST" | zenity --list \
    --title="$APP_NAME - Select monitor" \
    --column="ID" --column="Monitor" \
    --height=300 \
    --print-column=2)
fi

if [ -z "${SELECTED_MON:-}" ]; then
  # User cancelled
  exit 0
fi

# 2d) Choose video file
if ! command -v zenity >/dev/null 2>&1; then
  zen_err "Zenity is not installed but is required for file selection."
  exit 1
fi

VIDEO="$(zenity --file-selection \
  --title="$APP_NAME - Choose motion wallpaper video" \
  --file-filter="Video files | *.mp4 *.mkv *.webm *.mov *.avi")" || exit 0

if [ -z "$VIDEO" ]; then
  # User cancelled
  exit 0
fi

if [ ! -f "$VIDEO" ]; then
  zen_err "Selected file does not exist:\n$VIDEO"
  exit 1
fi

# 2e) Start mpvpaper
nohup mpvpaper -o "--loop --no-audio --vo=gpu --profile=high-quality --keep-open=yes" \
  "$SELECTED_MON" "$VIDEO" >/dev/null 2>&1 &

zen_info "Motion wallpaper started on $SELECTED_MON."
EOF

chmod +x "$HOME/.local/bin/motion-wallpaper-toggle"

# 6) Create desktop entry for app menu
mkdir -p "$HOME/.local/share/applications"

cat << EOF > "$HOME/.local/share/applications/motion-wallpaper-toggle.desktop"
[Desktop Entry]
Version=1.0
Type=Application
Name=Motion Wallpaper
Comment=Toggle animated video wallpaper on/off
Exec=$HOME/.local/bin/motion-wallpaper-toggle
Icon=preferences-desktop-wallpaper
Terminal=false
Categories=Utility;Settings;DesktopSettings;
Keywords=wallpaper;video;animated;background;
EOF

echo
echo "=== Install complete ==="
echo
echo "✓ Motion Wallpaper has been added to your application menu"
echo "  Search for 'Motion Wallpaper' in your app launcher"

# Check if ~/.local/bin is in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  echo
  echo "⚠️  NOTE: ~/.local/bin is not in your PATH."
  echo "Add this to your ~/.bashrc or ~/.zshrc:"
  echo
  echo "  export PATH=\"\$HOME/.local/bin:\$PATH\""
  echo
  echo "Then reload your shell with: source ~/.bashrc"
  echo
  echo "For now, run with full path:"
  echo "  ~/.local/bin/motion-wallpaper-toggle"
else
  echo
  echo "Run this to toggle motion wallpaper on/off:"
  echo
  echo "  motion-wallpaper-toggle"
fi

echo
echo "Optional Hyprland keybind (add to your hyprland.conf):"
echo
echo "  bind = SUPER, W, exec, ~/.local/bin/motion-wallpaper-toggle"
echo
