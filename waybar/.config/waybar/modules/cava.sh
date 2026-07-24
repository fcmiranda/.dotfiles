#!/bin/bash
# /* ---- 💫 https://github.com/JaKooLit 💫 ---- */  ##
# Not my own work. This was added through Github PR. Credit to original author

#----- Optimized bars animation without much CPU usage increase --------
bar="▁▂▃▄▅▆▇█"
dict="s/;//g"
config_file="/tmp/bar_cava_config"
disabled_file="/tmp/waybar-cava-disabled"

# Calculate the length of the bar outside the loop
bar_length=${#bar}

# Create dictionary to replace char with bar
for ((i = 0; i < bar_length; i++)); do
    dict+=";s/$i/${bar:$i:1}/g"
done

# Create cava config
cat >"$config_file" <<EOF
[general]
# Older systems show significant CPU use with default framerate
# Setting maximum framerate to 30  
# You can increase the value if you wish
framerate = 30
bars = 10

[input]
method = pulse
source = auto

[output]
method = raw
raw_target = /dev/stdout
data_format = ascii
ascii_max_range = 7
EOF

cleanup() {
    pkill -f "cava -p $config_file" 2>/dev/null
}

trap cleanup EXIT INT TERM

# Exit immediately if custom/cava is not configured in waybar
if ! grep -q "custom/cava" "$HOME/.config/waybar/config.jsonc" 2>/dev/null; then
    cleanup
    exit 0
fi

# Kill cava if it's already running
cleanup

while true; do
    if ! grep -q "custom/cava" "$HOME/.config/waybar/config.jsonc" 2>/dev/null; then
        cleanup
        exit 0
    fi

    if [ -f "$disabled_file" ]; then
        echo "󰗅"
        sleep 1
        continue
    fi

    LAST_CHECK=0
    IS_PLAYING=0

    # Read stdout from cava, show bars only when music is playing.
    # playerctl is checked once per second instead of 30x/sec to prevent high CPU usage from process forks.
    cava -p "$config_file" | sed -u "$dict" | while IFS= read -r line; do
        NOW=$SECONDS
        if [ $((NOW - LAST_CHECK)) -ge 1 ]; then
            LAST_CHECK=$NOW
            if playerctl status 2>/dev/null | grep -q "Playing"; then
                IS_PLAYING=1
            else
                IS_PLAYING=0
            fi
        fi

        if [ -f "$disabled_file" ]; then
            echo "󰗅"
            pkill -f "cava -p $config_file" 2>/dev/null
            break
        elif [ "$IS_PLAYING" -eq 1 ]; then
            echo "$line"
        else
            echo ""
        fi
    done

    sleep 1
done
