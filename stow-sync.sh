#!/usr/bin/env bash
#
# stow-sync.sh - Diff stowed packages vs repo folders and optionally stow missing ones
#
# Usage:
#   ./stow-sync.sh [--apply] [--dotfiles PATH] [--lock PATH] [--target PATH]
#
# Examples:
#   ./stow-sync.sh
#   ./stow-sync.sh --apply
#

set -uo pipefail

DOTFILES_DIR=""
LOCK_FILE=""
TARGET_DIR=""
APPLY=false

while [[ $# -gt 0 ]]; do
    case "$1" in
        --apply)
            APPLY=true
            shift
            ;;
        --dotfiles)
            DOTFILES_DIR="$2"
            shift 2
            ;;
        --lock)
            LOCK_FILE="$2"
            shift 2
            ;;
        --target)
            TARGET_DIR="$2"
            shift 2
            ;;
        -h|--help)
            sed -n '2,/^$/p' "$0" | sed 's/^#//' | sed 's/^ //'
            exit 0
            ;;
        *)
            echo "Unknown option: $1" >&2
            exit 1
            ;;
    esac
done

if [[ -z "$DOTFILES_DIR" ]]; then
    DOTFILES_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
fi

if [[ -z "$LOCK_FILE" ]]; then
    LOCK_FILE="$DOTFILES_DIR/stow-lock.json"
fi

if [[ -z "$TARGET_DIR" ]]; then
    TARGET_DIR="$HOME"
fi

if [[ ! -d "$DOTFILES_DIR" ]]; then
    echo "Dotfiles directory not found: $DOTFILES_DIR" >&2
    exit 1
fi

IGNORE_DIRS=(
    ".git"
    ".github"
    "scripts"
)

get_packages() {
    local packages=()
    for dir in "$DOTFILES_DIR"/*/; do
        local name
        name=$(basename "$dir")
        local ignored=false
        for ignored_dir in "${IGNORE_DIRS[@]}"; do
            [[ "$name" == "$ignored_dir" ]] && ignored=true && break
        done
        if [[ "$ignored" == false ]]; then
            packages+=("$name")
        fi
    done
    printf '%s\n' "${packages[@]}"
}

get_stowed_packages() {
    if [[ ! -f "$LOCK_FILE" ]]; then
        return 0
    fi

    python - "$LOCK_FILE" <<'PY'
import json
import sys

lock_path = sys.argv[1]

try:
    with open(lock_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

packages = data.get("packages", {})
if isinstance(packages, dict):
    for name in sorted(packages.keys()):
        print(name)
PY
}

mapfile -t all_packages < <(get_packages)
mapfile -t stowed_packages < <(get_stowed_packages)

# Build lookup for stowed packages
STOWED_SET=()
for p in "${stowed_packages[@]}"; do
    STOWED_SET+=("$p")
done

is_stowed() {
    local pkg="$1"
    for s in "${STOWED_SET[@]}"; do
        [[ "$s" == "$pkg" ]] && return 0
    done
    return 1
}

UNSTOWED=()
for pkg in "${all_packages[@]}"; do
    if ! is_stowed "$pkg"; then
        UNSTOWED+=("$pkg")
    fi
done

if [[ ${#UNSTOWED[@]} -eq 0 ]]; then
    echo "All packages are stowed."
    exit 0
fi

echo "Unstowed packages:"
for pkg in "${UNSTOWED[@]}"; do
    echo "  - $pkg"
    done

echo
if [[ "$APPLY" == true ]]; then
    echo "Stowing unstowed packages..."
    STOW_TARGET="$TARGET_DIR" "$DOTFILES_DIR/stow.sh" "${UNSTOWED[@]}"
else
    echo "Run with --apply to stow these packages."
fi
