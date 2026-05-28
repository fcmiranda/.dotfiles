#!/usr/bin/env sh

disabled_file="/tmp/waybar-cava-disabled"
config_file="/tmp/bar_cava_config"

if [ -f "$disabled_file" ]; then
    rm -f "$disabled_file"
    notify-send -u low "Waybar CAVA" "Visualizer enabled" 2>/dev/null || true
else
    : >"$disabled_file"
    notify-send -u low "Waybar CAVA" "Visualizer disabled" 2>/dev/null || true
fi

# Force the long-running module loop to observe the new state immediately.
pkill -f "cava -p $config_file" 2>/dev/null || true
