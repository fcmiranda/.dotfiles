# Omarchy-based colors for zsh-vi-mode prompt indicator
# Override the colors file path by exporting ZVM_OMARCHY_COLORS_FILE.

ZVM_OMARCHY_COLORS_FILE="${ZVM_OMARCHY_COLORS_FILE:-$HOME/.config/omarchy/current/theme/colors.toml}"

function _zvm_omarchy_get_color() {
    local key="$1"
    local file="$ZVM_OMARCHY_COLORS_FILE"
    local value=""

    if [[ -f "$file" ]]; then
        value="$(awk -F'=' -v k="$key" '
            BEGIN { IGNORECASE = 1 }
            $1 ~ "^[[:space:]]*" k "[[:space:]]*$" {
                gsub(/[[:space:]"]/, "", $2);
                print $2;
                exit
            }
        ' "$file")"
    fi

    echo "$value"
}

# Colors (override these variables if you want custom values)
: ${ZVM_VI_MODE_INSERT_COLOR:=$(_zvm_omarchy_get_color color2)}
: ${ZVM_VI_MODE_NORMAL_COLOR:=$(_zvm_omarchy_get_color accent)}
: ${ZVM_VI_MODE_VISUAL_COLOR:=$(_zvm_omarchy_get_color color5)}

# Fallbacks if colors are missing
: ${ZVM_VI_MODE_INSERT_COLOR:=#9ece6a}
: ${ZVM_VI_MODE_NORMAL_COLOR:=#7aa2f7}
: ${ZVM_VI_MODE_VISUAL_COLOR:=#ad8ee6}
