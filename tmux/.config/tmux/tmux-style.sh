#!/usr/bin/env sh
# tmux-style.sh — fallback style config (hardcoded defaults).
# The theme-aware version is generated at:
#   ~/.config/omarchy/current/theme/tmux-style.sh
# This file is only used when no theme has been applied yet.

# ── Popup appearance ──────────────────────────────────────────────────────────
TMUX_POPUP_BORDER_COLOR="magenta"
TMUX_POPUP_TEXT_COLOR="#89b482"
TMUX_POPUP_WIDTH="80%"
TMUX_POPUP_HEIGHT="80%"

# ── bfzf color spec (window-picker --color flag) ─────────────────────────────
TMUX_BFZF_COLOR_SPEC="border:239,header:245,cursor:214,fg+:223"

# ── Spinner ───────────────────────────────────────────────────────────────────
TMUX_SPINNER_NAME="arc"
TMUX_SPINNER_COLOR="214"
