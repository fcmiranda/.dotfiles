#!/usr/bin/env sh
# opencode-style.sh — deprecated; replaced by tmux-style.sh.
# This shim is kept for backward compatibility with any external scripts.
_ocs_dir=$(cd "$(dirname "$0")" && pwd)
# shellcheck source=/dev/null
. "${_ocs_dir}/tmux-style.sh"
unset _ocs_dir
