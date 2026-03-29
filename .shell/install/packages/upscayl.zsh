#!/usr/bin/env zsh
# Build and install Upscayl from source.
# Required because upscayl-bin (AUR) is x86_64 only; this script handles aarch64 too.
#
# Uses `npm run dist -- --dir` to produce the unpacked Electron app without
# invoking fpm/deb packaging, which ships an x86_64-only Ruby binary that
# fails on aarch64 with "Exec format error".
set -eo pipefail

local UPSCAYL_REPO="https://github.com/upscayl/upscayl"
local UPSCAYL_DIR="${TMPDIR:-/tmp}/upscayl-src"
local INSTALL_DIR="$HOME/.local/share/upscayl"
local INSTALL_PATH="$HOME/.local/bin/upscayl"

# ── Already installed? ────────────────────────────────────────────────────────
if [[ -x "$INSTALL_PATH" ]]; then
  print -P "%F{cyan}  ✓%f Upscayl already installed at %B${INSTALL_PATH}%b"
  return 0
fi

# ── Dependencies ──────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Checking build dependencies..."

local -a DEPS=(git nodejs npm python3)
local -a MISSING=()

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

if (( ${#MISSING[@]} > 0 )); then
  print -P "%F{yellow}  →%f Installing missing dependencies: ${MISSING[*]}"
  sudo pacman -S --noconfirm --needed "${MISSING[@]}"
fi

# ── Clone ─────────────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Cloning Upscayl..."
rm -rf "$UPSCAYL_DIR"
git clone --depth=1 "$UPSCAYL_REPO" "$UPSCAYL_DIR"

(
  cd "$UPSCAYL_DIR"

  # ── Node dependencies ──────────────────────────────────────────────────────
  print -P "%F{blue}  →%f Installing Node dependencies..."
  npm install

  # ── Build (unpacked only — skips fpm/deb which require x86_64 Ruby) ────────
  print -P "%F{blue}  →%f Building Upscayl (this may take a while)..."
  npm run dist -- --dir

  # ── Locate the unpacked app ────────────────────────────────────────────────
  # electron-builder names it dist/linux-<arch>-unpacked/
  local UNPACKED
  UNPACKED=$(echo dist/linux-*-unpacked 2>/dev/null | head -1)

  if [[ -z "$UNPACKED" || ! -d "$UNPACKED" ]]; then
    print -P "%F{red}  ✗%f Build finished but unpacked directory not found in dist/."
    return 1
  fi

  # ── Install unpacked app ───────────────────────────────────────────────────
  print -P "%F{blue}  →%f Installing to %B${INSTALL_DIR}%b..."
  rm -rf "$INSTALL_DIR"
  mkdir -p "$INSTALL_DIR"
  cp -r "$UNPACKED"/. "$INSTALL_DIR/"
)

# ── Launcher wrapper ──────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/bin"
cat > "$INSTALL_PATH" << EOF
#!/usr/bin/env bash
exec "$INSTALL_DIR/upscayl" "\$@"
EOF
chmod +x "$INSTALL_PATH"

# ── Desktop entry ─────────────────────────────────────────────────────────────
mkdir -p "$HOME/.local/share/applications"
cat > "$HOME/.local/share/applications/upscayl.desktop" << EOF
[Desktop Entry]
Version=1.0
Type=Application
Name=Upscayl
Comment=Free and Open Source AI Image Upscaler
Exec=$INSTALL_PATH
Icon=$INSTALL_DIR/resources/icons/512x512.png
Terminal=false
Categories=Graphics;Photography;
Keywords=upscale;image;ai;enhance;
EOF

# ── Cleanup ───────────────────────────────────────────────────────────────────
rm -rf "$UPSCAYL_DIR"

print -P "%F{green}  ✓%f Upscayl installed to %B${INSTALL_PATH}%b"
print -P "  Run with: %Bupscayl%b  or search for it in your app launcher."
