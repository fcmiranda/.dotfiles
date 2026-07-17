#!/bin/bash
# Check if device is a MacBook and dynamically manage Waybar symlinks
WAYBAR_DIR="$HOME/.config/waybar"
CHANGED=false

update_link() {
  local target="$1"
  local symlink="$2"
  if [[ ! -L "$symlink" || "$(readlink "$symlink")" != "$target" ]]; then
    ln -sf "$target" "$symlink"
    CHANGED=true
  fi
}

if grep -qi "macbook" /sys/firmware/devicetree/base/model 2>/dev/null; then
  update_link "config.jsonc.macbook" "$WAYBAR_DIR/config.jsonc"
  update_link "style.css.macbook" "$WAYBAR_DIR/style.css"
else
  update_link "config.jsonc.default" "$WAYBAR_DIR/config.jsonc"
  update_link "style.css.default" "$WAYBAR_DIR/style.css"
fi

if [[ $CHANGED == "true" ]]; then
  # Restart waybar if links changed
  omarchy-restart-waybar
fi
