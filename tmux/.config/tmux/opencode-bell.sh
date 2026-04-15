#!/usr/bin/env sh

set -eu

msg=${1:-OpenCode}

exec tmux display-message -d 2000 "$msg"
