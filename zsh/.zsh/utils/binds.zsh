# # binds to use emacs mode (disables vi mode)
# bindkey -e
# bindkey '\e' vi-cmd-mode

# Prevent Delete key from activating vi normal mode
bindkey '^[[3~' delete-char  # Standard Delete key
bindkey '^?' backward-delete-char  # Backspace

# Prevent Ctrl+Arrow keys from activating vi normal mode
bindkey '^[[1;5D' backward-word  # Ctrl+Left Arrow
bindkey '^[[1;5C' forward-word   # Ctrl+Right Arrow

# Single Tab: "j<Tab>" triggers zcd, otherwise normal completion
_smart_tab() {
    if [[ "$BUFFER" == "j" ]]; then
        BUFFER=""
        CURSOR=0
        _zcd_widget
    else
        zle autosuggest-accept
    fi
}
zle -N _smart_tab
bindkey '^I' _smart_tab

# Delete previous word with Ctrl+Backspace in vi insert mode
bindkey -M viins $'\e\x7f' backward-kill-word
