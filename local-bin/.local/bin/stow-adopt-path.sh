#!/usr/bin/env bash

set -euo pipefail

dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
exec "$dotfiles_dir/scripts/stow-adopt-path.sh" "$@"
