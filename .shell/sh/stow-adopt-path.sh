#!/usr/bin/env bash

set -euo pipefail

SCRIPT_DIR="$(cd "$(dirname "${BASH_SOURCE[0]}")" && pwd)"
DOTFILES_DIR="$(cd "$SCRIPT_DIR/.." && pwd)"
STOW_WRAPPER="$DOTFILES_DIR/stow.sh"
HOME_DIR="${HOME:?HOME is not set}"

usage() {
    cat <<'EOF'
Usage:
  stow-adopt-path.sh <package> <source-path> [target-relative-path]

Description:
  Move an existing file/folder into ~/.dotfiles/<package>/... and run stow adopt.
  Can be executed from any directory.

Arguments:
  package               Package folder name inside ~/.dotfiles
  source-path           Existing file/folder to add to dotfiles (absolute or relative)
  target-relative-path  Optional path relative to $HOME for the link target.
                        If omitted, it is inferred from source-path and must be under $HOME.

Examples:
  stow-adopt-path.sh omarchy-bin ~/.local/share/omarchy/bin/omarchy-launch-sesh
  stow-adopt-path.sh omarchy-bin ./omarchy-launch-sesh .local/share/omarchy/bin/omarchy-launch-sesh
EOF
}

error() {
    echo "[ERROR] $1" >&2
    exit 1
}

info() {
    echo "[INFO] $1"
}

require_cmd() {
    command -v "$1" >/dev/null 2>&1 || error "Required command not found: $1"
}

main() {
    if [[ "${1:-}" == "-h" || "${1:-}" == "--help" ]]; then
        usage
        exit 0
    fi

    [[ $# -lt 2 || $# -gt 3 ]] && {
        usage
        exit 1
    }

    local package="$1"
    local source_input="$2"
    local target_rel_input="${3:-}"

    require_cmd realpath
    require_cmd mv

    [[ -f "$STOW_WRAPPER" ]] || error "Missing stow wrapper: $STOW_WRAPPER"

    local source_abs
    source_abs="$(realpath "$source_input")"
    [[ -e "$source_abs" ]] || error "Source path does not exist: $source_input"

    local target_rel
    if [[ -n "$target_rel_input" ]]; then
        target_rel="${target_rel_input#/}"
    else
        case "$source_abs" in
            "$HOME_DIR"/*)
                target_rel="${source_abs#"$HOME_DIR"/}"
                ;;
            *)
                error "Source is outside $HOME. Provide target-relative-path explicitly."
                ;;
        esac
    fi

    [[ -n "$target_rel" ]] || error "Resolved target path is empty"

    local package_dir="$DOTFILES_DIR/$package"
    local repo_dest="$package_dir/$target_rel"
    local target_abs="$HOME_DIR/$target_rel"

    mkdir -p "$(dirname "$repo_dest")"

    if [[ -e "$repo_dest" || -L "$repo_dest" ]]; then
        error "Destination already exists in dotfiles: $repo_dest"
    fi

    info "Moving $source_abs"
    info "  -> $repo_dest"
    mv "$source_abs" "$repo_dest"

    info "Running stow adopt for package: $package"
    "$STOW_WRAPPER" -a "$package"

    if [[ -L "$target_abs" ]]; then
        info "Done. Symlink created: $target_abs -> $(readlink "$target_abs")"
    else
        info "Completed, but target is not a symlink: $target_abs"
    fi
}

main "$@"
