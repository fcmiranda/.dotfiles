#!/usr/bin/env bash
#
# stow.sh - Manage dotfiles using GNU Stow
#
# Usage:
#   ./stow.sh [OPTIONS] [PACKAGES...]
#
# Options:
#   -a, --adopt     Adopt existing files into the dotfiles repo
#   -d, --delete    Unstow packages (remove symlinks)
#   -r, --restow    Restow packages (useful after changes)
#   -n, --dry-run   Show what would be done without making changes
#   -v, --verbose   Enable verbose output
#   -s, --status    Show stowed packages from lock file
#   -h, --help      Show this help message
#
# If no packages are specified, all packages will be processed.
#
# Lock file: stow.lock (JSON) tracks all stowed packages and their symlinks.

set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
readonly TARGET_DIR="${STOW_TARGET:-$HOME}"
readonly LOCK_FILE="$DOTFILES_DIR/stow-lock.json"

# Directories to ignore (not stow packages)
readonly IGNORE_DIRS=(
    ".git"
    ".github"
    "scripts"
)

# Colors for output
readonly RED='\033[0;31m'
readonly GREEN='\033[0;32m'
readonly YELLOW='\033[0;33m'
readonly BLUE='\033[0;34m'
readonly BOLD='\033[1m'
readonly NC='\033[0m' # No Color

# ─────────────────────────────────────────────────────────────────────────────
# Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

log_info() {
    echo -e "${BLUE}${BOLD}[INFO]${NC} $1"
}

log_success() {
    echo -e "${GREEN}${BOLD}[OK]${NC} $1"
}

log_warning() {
    echo -e "${YELLOW}${BOLD}[WARN]${NC} $1"
}

log_error() {
    echo -e "${RED}${BOLD}[ERROR]${NC} $1" >&2
}

show_help() {
    sed -n '2,/^$/p' "$0" | sed 's/^#//' | sed 's/^ //'
    exit 0
}

# Check if a directory should be ignored
is_ignored() {
    local dir="$1"
    for ignored in "${IGNORE_DIRS[@]}"; do
        [[ "$dir" == "$ignored" ]] && return 0
    done
    return 1
}

# Get all valid stow packages
get_packages() {
    local packages=()
    for dir in "$DOTFILES_DIR"/*/; do
        local name
        name=$(basename "$dir")
        if ! is_ignored "$name"; then
            packages+=("$name")
        fi
    done
    echo "${packages[@]}"
}

# Check if stow is installed
check_dependencies() {
    if ! command -v stow &>/dev/null; then
        log_error "GNU Stow is not installed. Please install it first."
        log_info "  Ubuntu/Debian: sudo apt install stow"
        log_info "  Fedora: sudo dnf install stow"
        log_info "  Arch: sudo pacman -S stow"
        log_info "  macOS: brew install stow"
        exit 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Lock File Operations
# ─────────────────────────────────────────────────────────────────────────────

# Get symlinks for a package
get_package_symlinks() {
    local package="$1"
    local package_dir="$DOTFILES_DIR/$package"
    local symlinks=()

    while IFS= read -r -d '' file; do
        local rel_path="${file#$package_dir/}"
        local target_path="$TARGET_DIR/$rel_path"
        if [[ -L "$target_path" ]]; then
            symlinks+=("$target_path")
        fi
    done < <(find "$package_dir" -type f -print0 2>/dev/null)

    printf '%s\n' "${symlinks[@]}"
}

# Add package to lock file
add_to_lock() {
    local package="$1"
    local timestamp
    timestamp=$(date -Iseconds)
    local temp_file
    temp_file=$(mktemp)

    get_package_symlinks "$package" > "$temp_file"

    python - "$LOCK_FILE" "$package" "$timestamp" "$TARGET_DIR" "$temp_file" <<'PY'
import json
import os
import sys

lock_path, package, ts, target, files_path = sys.argv[1:6]

files = []
with open(files_path, 'r', encoding='utf-8') as f:
    for line in f:
        line = line.strip()
        if line:
            files.append(line)

data = {}
if os.path.exists(lock_path):
    try:
        with open(lock_path, 'r', encoding='utf-8') as f:
            data = json.load(f)
    except Exception:
        data = {}

if not isinstance(data, dict):
    data = {}

packages = data.get("packages")
if not isinstance(packages, dict):
    packages = {}

packages[package] = {
    "stowed_at": ts,
    "target": target,
    "files": files,
}

data["packages"] = packages

with open(lock_path, 'w', encoding='utf-8') as f:
    json.dump(data, f, indent=2, sort_keys=True)
PY

    rm -f "$temp_file"
}

# Remove package from lock file
remove_from_lock() {
    local package="$1"
    [[ ! -f "$LOCK_FILE" ]] && return 0

    python - "$LOCK_FILE" "$package" <<'PY'
import json
import os
import sys

lock_path, package = sys.argv[1:3]

if not os.path.exists(lock_path):
    sys.exit(0)

try:
    with open(lock_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

packages = data.get("packages")
if isinstance(packages, dict) and package in packages:
    packages.pop(package, None)
    data["packages"] = packages
    with open(lock_path, 'w', encoding='utf-8') as f:
        json.dump(data, f, indent=2, sort_keys=True)
PY
}

# Show status from lock file
show_status() {
    if [[ ! -f "$LOCK_FILE" ]]; then
        log_warning "No lock file found. No packages have been stowed yet."
        exit 0
    fi

    env GREEN="$GREEN" RED="$RED" BLUE="$BLUE" BOLD="$BOLD" NC="$NC" \
        python - "$LOCK_FILE" <<'PY'
import json
import os
import sys

lock_path = sys.argv[1]

GREEN = os.environ.get("GREEN", "")
RED = os.environ.get("RED", "")
BLUE = os.environ.get("BLUE", "")
BOLD = os.environ.get("BOLD", "")
NC = os.environ.get("NC", "")

try:
    with open(lock_path, 'r', encoding='utf-8') as f:
        data = json.load(f)
except Exception:
    sys.exit(0)

packages = data.get("packages", {})
if not isinstance(packages, dict) or not packages:
    sys.exit(0)

for package in sorted(packages.keys()):
    print(package)
PY
}

# ─────────────────────────────────────────────────────────────────────────────
# Stow Operations
# ─────────────────────────────────────────────────────────────────────────────

stow_package() {
    local package="$1"
    local action="$2"
    local flags=("--target=$TARGET_DIR" "--dir=$DOTFILES_DIR")

    # Add optional flags
    [[ "$DRY_RUN" == true ]] && flags+=("--simulate")
    [[ "$VERBOSE" == true ]] && flags+=("--verbose")

    case "$action" in
        stow)
            flags+=("--stow")
            ;;
        adopt)
            flags+=("--adopt")
            ;;
        delete)
            flags+=("--delete")
            ;;
        restow)
            flags+=("--restow")
            ;;
    esac

    flags+=("$package")

    local output
    if output=$(stow "${flags[@]}" 2>&1); then
        [[ -n "$output" && "$VERBOSE" == true ]] && echo "$output"
        log_success "$action: $package"

        # Update lock file (skip in dry-run mode)
        if [[ "$DRY_RUN" != true ]]; then
            case "$action" in
                stow|adopt|restow)
                    add_to_lock "$package"
                    ;;
                delete)
                    remove_from_lock "$package"
                    ;;
            esac
        fi

        return 0
    else
        log_error "Failed to $action: $package"
        [[ -n "$output" ]] && echo "$output" | sed 's/^/    /'
        return 1
    fi
}

process_packages() {
    local action="$1"
    shift
    local packages=("$@")
    local success=0
    local failed=0

    log_info "Processing ${#packages[@]} package(s) with action: $action"
    echo

    for package in "${packages[@]}"; do
        if [[ -d "$DOTFILES_DIR/$package" ]]; then
            if stow_package "$package" "$action"; then
                success=$((success + 1))
            else
                failed=$((failed + 1))
            fi
        else
            log_warning "Package not found: $package"
            failed=$((failed + 1))
        fi
    done

    echo
    log_info "Summary: ${GREEN}$success succeeded${NC}, ${RED}$failed failed${NC}"

    [[ $failed -eq 0 ]]
}

# ─────────────────────────────────────────────────────────────────────────────
# Main
# ─────────────────────────────────────────────────────────────────────────────

main() {
    local action="stow"
    local packages=()
    DRY_RUN=false
    VERBOSE=false

    # Parse arguments
    while [[ $# -gt 0 ]]; do
        case "$1" in
            -a|--adopt)
                action="adopt"
                shift
                ;;
            -d|--delete)
                action="delete"
                shift
                ;;
            -r|--restow)
                action="restow"
                shift
                ;;
            -n|--dry-run)
                DRY_RUN=true
                shift
                ;;
            -v|--verbose)
                VERBOSE=true
                shift
                ;;
            -s|--status)
                show_status
                exit 0
                ;;
            -h|--help)
                show_help
                ;;
            -*)
                log_error "Unknown option: $1"
                show_help
                ;;
            *)
                packages+=("$1")
                shift
                ;;
        esac
    done

    check_dependencies

    # Use all packages if none specified
    if [[ ${#packages[@]} -eq 0 ]]; then
        read -ra packages <<< "$(get_packages)"
    fi

    if [[ ${#packages[@]} -eq 0 ]]; then
        log_error "No packages found in $DOTFILES_DIR"
        exit 1
    fi

    [[ "$DRY_RUN" == true ]] && log_warning "Dry run mode - no changes will be made"

    process_packages "$action" "${packages[@]}"
}

main "$@"
