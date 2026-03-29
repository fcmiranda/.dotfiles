#!/usr/bin/env zsh
# Build and install Upscayl from source.
# Required because upscayl-bin (AUR) is x86_64 only; this script handles aarch64 too.
set -euo pipefail

UPSCAYL_REPO="https://github.com/upscayl/upscayl"
UPSCAYL_DIR="${TMPDIR:-/tmp}/upscayl-src"

# ── Dependencies ────────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Checking build dependencies..."

DEPS=(git nodejs npm python3)
MISSING=()

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

if (( ${#MISSING[@]} > 0 )); then
  print -P "%F{yellow}  →%f Installing missing dependencies: ${MISSING[*]}"
  sudo pacman -S --noconfirm --needed "${MISSING[@]}"
fi

# ── Clone ────────────────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Cloning Upscayl..."
rm -rf "$UPSCAYL_DIR"
git clone --depth=1 "$UPSCAYL_REPO" "$UPSCAYL_DIR"
cd "$UPSCAYL_DIR"

# ── Install Node dependencies ────────────────────────────────────────────────────
print -P "%F{blue}  →%f Installing Node dependencies..."
npm install

# ── Build ────────────────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Building Upscayl (this may take a while)..."
npm run dist

# ── Install AppImage ─────────────────────────────────────────────────────────────
# electron-builder places the output in dist/
APPIMAGE=$(ls dist/upscayl-*.AppImage 2>/dev/null | head -1)

if [[ -z "$APPIMAGE" ]]; then
  print -P "%F{red}  ✗%f Build succeeded but no AppImage found in dist/. Check build output."
  return 1
fi

INSTALL_PATH="$HOME/.local/bin/upscayl"
mkdir -p "$HOME/.local/bin"
cp "$APPIMAGE" "$INSTALL_PATH"
chmod +x "$INSTALL_PATH"

# ── Desktop entry ─────────────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/upscayl.desktop" <<EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Upscayl
Comment=Free and Open Source AI Image Upscaler
Exec=$INSTALL_PATH
Icon=upscayl
Terminal=false
Categories=Graphics;Photography;
Keywords=upscale;image;ai;enhance;
EOF

# ── Cleanup ───────────────────────────────────────────────────────────────────────
cd /
rm -rf "$UPSCAYL_DIR"

print -P "%F{green}  ✓%f Upscayl installed to %B${INSTALL_PATH}%b"
print -P "  Run with: %Bupscayl%b  or search for it in your app launcher."
