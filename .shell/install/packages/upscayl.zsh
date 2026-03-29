#!/usr/bin/env zsh
# Build and install Upscayl from source.
# Required because upscayl-bin (AUR) is x86_64 only; this script handles aarch64 too.
#
# Uses `npm run dist -- --dir` to produce the unpacked Electron app without
# invoking fpm/deb packaging, which ships an x86_64-only Ruby binary that
# fails on aarch64 with "Exec format error".
#
# Also builds the upscayl-ncnn backend from source, replacing the bundled
# x86_64 binary. Build notes for aarch64:
#   - GCC 15 has a codegen bug with ARM NEON indexed-element instructions
#     (smlal/smlal2 with v16-v31 as the indexed operand). Use clang instead.
#   - upscayl-ncnn's CMakeLists.txt unconditionally enables LTO when the
#     compiler supports it; the UPSCAYL_ENABLE_LTO=OFF patch disables this.
#   - ncnn submodule uses SSH URLs; override to HTTPS for clone without SSH keys.
set -eo pipefail

local UPSCAYL_REPO="https://github.com/upscayl/upscayl"
local UPSCAYL_NCNN_REPO="https://github.com/upscayl/upscayl-ncnn"
local UPSCAYL_DIR="${TMPDIR:-/tmp}/upscayl-src"
local UPSCAYL_NCNN_DIR="${TMPDIR:-/tmp}/upscayl-ncnn-src"
local INSTALL_DIR="$HOME/.local/share/upscayl"
local INSTALL_PATH="$HOME/.local/bin/upscayl"

# ── Already installed? ────────────────────────────────────────────────────────
if [[ -x "$INSTALL_PATH" ]]; then
  print -P "%F{cyan}  ✓%f Upscayl already installed at %B${INSTALL_PATH}%b"
  return 0
fi

# ── Dependencies ──────────────────────────────────────────────────────────────
print -P "%F{blue}  →%f Checking build dependencies..."

local -a DEPS=(git nodejs npm python3 clang cmake)
local -a PACMAN_DEPS=(vulkan-headers)
local -a MISSING=()
local -a MISSING_PKG=()

for dep in "${DEPS[@]}"; do
  if ! command -v "$dep" &>/dev/null; then
    MISSING+=("$dep")
  fi
done

for pkg in "${PACMAN_DEPS[@]}"; do
  if ! pacman -Qi "$pkg" &>/dev/null; then
    MISSING_PKG+=("$pkg")
  fi
done

if (( ${#MISSING[@]} > 0 || ${#MISSING_PKG[@]} > 0 )); then
  print -P "%F{yellow}  →%f Installing missing dependencies: ${MISSING[*]} ${MISSING_PKG[*]}"
  sudo pacman -S --noconfirm --needed "${MISSING[@]}" "${MISSING_PKG[@]}"
fi

# ══════════════════════════════════════════════════════════════════════════════
# 1. Build the Electron app (upscayl GUI)
# ══════════════════════════════════════════════════════════════════════════════
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

# ══════════════════════════════════════════════════════════════════════════════
# 2. Build the ncnn backend (upscayl-bin AI engine)
# ══════════════════════════════════════════════════════════════════════════════
# The Electron app bundles a prebuilt upscayl-bin which is x86_64-only.
# We build it from source for the host architecture.
print -P "%F{blue}  →%f Cloning upscayl-ncnn backend..."
rm -rf "$UPSCAYL_NCNN_DIR"
git clone --depth=1 "$UPSCAYL_NCNN_REPO" "$UPSCAYL_NCNN_DIR"

(
  cd "$UPSCAYL_NCNN_DIR"

  # Override submodule SSH URLs to HTTPS (no SSH keys needed in CI/fresh installs)
  git submodule set-url src/ncnn https://github.com/Tencent/ncnn.git
  git submodule set-url src/libwebp https://github.com/webmproject/libwebp.git
  git submodule update --init --recursive --depth=1

  # Patch CMakeLists.txt to add UPSCAYL_ENABLE_LTO option.
  # The upstream file unconditionally enables LTO when the compiler supports it;
  # on aarch64 with GCC 15 this hits a codegen bug in ARM NEON indexed-element
  # instructions. We use clang to avoid that bug, but patch LTO out anyway for
  # robustness.
  local LTO_ORIG='# enable global link time optimization
cmake_policy(SET CMP0069 NEW)
set(CMAKE_POLICY_DEFAULT_CMP0069 NEW)
include(CheckIPOSupported)
check_ipo_supported(RESULT ipo_supported OUTPUT ipo_supported_output)
if(ipo_supported)
    set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
else()
    message(WARNING "IPO is not supported: ${ipo_supported_output}")
endif()'
  local LTO_PATCHED='# enable global link time optimization
cmake_policy(SET CMP0069 NEW)
set(CMAKE_POLICY_DEFAULT_CMP0069 NEW)
option(UPSCAYL_ENABLE_LTO "enable link-time optimization" ON)
if(UPSCAYL_ENABLE_LTO)
    include(CheckIPOSupported)
    check_ipo_supported(RESULT ipo_supported OUTPUT ipo_supported_output)
    if(ipo_supported)
        set(CMAKE_INTERPROCEDURAL_OPTIMIZATION TRUE)
    else()
        message(WARNING "IPO is not supported: ${ipo_supported_output}")
    endif()
else()
    message(STATUS "LTO disabled via UPSCAYL_ENABLE_LTO=OFF")
endif()'

  # Use Python to do the substitution (avoids shell quoting hell with sed)
  python3 - <<PYEOF
import pathlib, sys
p = pathlib.Path("src/CMakeLists.txt")
t = p.read_text()
orig = """${LTO_ORIG}"""
patched = """${LTO_PATCHED}"""
if orig not in t:
    print("WARNING: LTO patch pattern not found — CMakeLists.txt may have changed upstream.")
    sys.exit(0)
p.write_text(t.replace(orig, patched, 1))
print("LTO patch applied.")
PYEOF

  # Build with clang to avoid GCC 15 aarch64 NEON codegen bug
  mkdir -p build
  CC=clang CXX=clang++ cmake \
    -DCMAKE_POLICY_VERSION_MINIMUM=3.5 \
    -DUPSCAYL_ENABLE_LTO=OFF \
    -DVulkan_INCLUDE_DIR="/usr/include" \
    -DVulkan_LIBRARY="/usr/lib/libvulkan.so" \
    -B build \
    src

  cmake --build build --parallel "$(nproc)"

  # Replace the bundled x86_64 binary with our native build
  print -P "%F{blue}  →%f Installing native upscayl-bin..."
  cp build/upscayl-bin "$INSTALL_DIR/resources/bin/upscayl-bin"
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
rm -rf "$UPSCAYL_DIR" "$UPSCAYL_NCNN_DIR"

print -P "%F{green}  ✓%f Upscayl installed to %B${INSTALL_PATH}%b"
print -P "  Run with: %Bupscayl%b  or search for it in your app launcher."
