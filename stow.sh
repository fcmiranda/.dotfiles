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
#   -h, --help      Show this help message
#
# If no packages are specified, all packages will be processed.

set -uo pipefail

# ─────────────────────────────────────────────────────────────────────────────
# Configuration
# ─────────────────────────────────────────────────────────────────────────────

readonly DOTFILES_DIR="${DOTFILES_DIR:-$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)}"
readonly TARGET_DIR="${STOW_TARGET:-$HOME}"

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
