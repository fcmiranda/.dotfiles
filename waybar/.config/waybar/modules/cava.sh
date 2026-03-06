#!/usr/bin/env bash

cava -p "$HOME/.config/cava/waybar.ini" | while IFS= read -r line; do
    if playerctl -p spotify status 2>/dev/null | grep -q "Playing"; then
        echo "$line" | sed 's/;//g;s/0/▁/g;s/1/▁/g;s/2/▂/g;s/3/▃/g;s/4/▄/g;s/5/▅/g;s/6/▆/g;s/7/▇/g;s/8/█/g'
    else
        echo ""
    fi
done
