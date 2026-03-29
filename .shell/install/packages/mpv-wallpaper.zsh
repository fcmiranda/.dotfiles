#!/usr/bin/env zsh
# Install mpvpaper (motion wallpaper) and its toggle script.
# Skips any step that is already in place.
set -eo pipefail

# ── Sanity check ─────────────────────────────────────────────────────────────
if ! command -v pacman &>/dev/null; then
  print -P "%F{red}  ✗%f This script requires a pacman-based system (Arch/Omarchy)."
  return 1
fi

# ── Dependencies ──────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Checking dependencies..."

local -a DEPS=(mpv jq zenity meson ninja gcc pkg-config git)
local -a MISSING=()

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

if (( ${#MISSING[@]} == 0 )); then
  print -P "%F{cyan}  ✓%f All dependencies already installed"
else
  print -P "%F{yellow}  →%f Installing missing dependencies: ${MISSING[*]}"
  sudo pacman -S --needed --noconfirm "${MISSING[@]}"
fi

# ── mpvpaper ──────────────────────────────────────────────────────────────────
if command -v mpvpaper &>/dev/null; then
  print -P "%F{cyan}  ✓%f mpvpaper already installed"
else
  print -P "%F{blue}  →%f Building mpvpaper from source..."

  local BUILD_DIR="${TMPDIR:-/tmp}/mpvpaper-src"
  rm -rf "$BUILD_DIR"
  git clone --depth=1 https://github.com/GhostNaN/mpvpaper "$BUILD_DIR"

  (
    cd "$BUILD_DIR"
    meson setup build
    meson compile -C build
    sudo meson install -C build
  )

  rm -rf "$BUILD_DIR"

  if ! command -v mpvpaper &>/dev/null; then
    print -P "%F{red}  ✗%f mpvpaper build succeeded but binary not found in PATH."
    return 1
  fi

  print -P "%F{green}  ✓%f mpvpaper installed"
fi

# ── Toggle script ─────────────────────────────────────────────────────────────
local TOGGLE="$HOME/.local/bin/motion-wallpaper-toggle"
mkdir -p "$HOME/.local/bin"

if [[ -x "$TOGGLE" ]]; then
  print -P "%F{cyan}  ✓%f Toggle script already exists at %B${TOGGLE}%b"
else
  print -P "%F{blue}  →%f Creating toggle script..."

  cat > "$TOGGLE" << 'TOGGLE_EOF'
#!/usr/bin/env bash
set -euo pipefail

APP_NAME="Motion Wallpaper"

zen_err() {
  if command -v zenity &>/dev/null; then
    zenity --error --title="$APP_NAME" --text="$1" || true
  else
    echo "ERROR: $1" >&2
  fi
}

zen_info() {
  if command -v zenity &>/dev/null; then
    zenity --info --title="$APP_NAME" --text="$1" || true
  else
    echo "$1"
  fi
}

zen_question() {
  if command -v zenity &>/dev/null; then
    zenity --question --title="$APP_NAME" --text="$1"
    return $?
  else
    return 0
  fi
}

# Toggle OFF if already running
if pgrep -x mpvpaper &>/dev/null; then
  if zen_question "Motion wallpaper is currently running.\n\nDo you want to stop it and return to your normal wallpaper?"; then
    pkill mpvpaper || true
    zen_info "Motion wallpaper stopped."
  fi
  exit 0
fi

# Toggle ON
if ! command -v hyprctl &>/dev/null; then
  zen_err "hyprctl not found. Are you running Hyprland?"
  exit 1
fi

MON_JSON="$(hyprctl monitors -j 2>/dev/null || true)"
if [[ -z "$MON_JSON" ]]; then
  zen_err "Could not get monitor info from hyprctl."
  exit 1
fi

if ! command -v jq &>/dev/null; then
  zen_err "jq is not installed. Please install jq and try again."
  exit 1
fi

MONITORS="$(printf '%s\n' "$MON_JSON" | jq -r '.[].name')"
if [[ -z "$MONITORS" ]]; then
  zen_err "No monitors detected."
  exit 1
fi

MON_COUNT="$(printf '%s\n' "$MONITORS" | wc -l)"
SELECTED_MON=""

if [[ "$MON_COUNT" -eq 1 ]]; then
  SELECTED_MON="$MONITORS"
else
  MON_LIST=$(printf '%s\n' "$MONITORS" | awk '{print NR, $1}')
  SELECTED_MON=$(echo "$MON_LIST" | zenity --list \
    --title="$APP_NAME - Select monitor" \
    --column="ID" --column="Monitor" \
    --height=300 \
    --print-column=2) || exit 0
fi

[[ -z "${SELECTED_MON:-}" ]] && exit 0

VIDEO="$(zenity --file-selection \
  --title="$APP_NAME - Choose motion wallpaper video" \
  --file-filter="Video files | *.mp4 *.mkv *.webm *.mov *.avi")" || exit 0

[[ -z "$VIDEO" ]] && exit 0

if [[ ! -f "$VIDEO" ]]; then
  zen_err "Selected file does not exist:\n$VIDEO"
  exit 1
fi

nohup mpvpaper -o "--loop --no-audio --vo=gpu --profile=high-quality --keep-open=yes" \
  "$SELECTED_MON" "$VIDEO" &>/dev/null &

zen_info "Motion wallpaper started on $SELECTED_MON."
TOGGLE_EOF

  chmod +x "$TOGGLE"
  print -P "%F{green}  ✓%f Toggle script created at %B${TOGGLE}%b"
fi

# ── Desktop entry ─────────────────────────────────────────────────────────────
local DESKTOP="$HOME/.local/share/applications/motion-wallpaper-toggle.desktop"
mkdir -p "$HOME/.local/share/applications"

if [[ -f "$DESKTOP" ]]; then
  print -P "%F{cyan}  ✓%f Desktop entry already exists"
else
  cat > "$DESKTOP" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Motion Wallpaper
Comment=Toggle animated video wallpaper on/off
Exec=$TOGGLE
Icon=preferences-desktop-wallpaper
Terminal=false
Categories=Utility;Settings;DesktopSettings;
Keywords=wallpaper;video;animated;background;
EOF
  print -P "%F{green}  ✓%f Desktop entry created"
fi

print -P "%F{green}  ✓%f mpv-wallpaper setup complete — run %Bmotion-wallpaper-toggle%b or find it in your app launcher"
