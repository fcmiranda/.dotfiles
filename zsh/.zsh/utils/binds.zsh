# # binds to use emacs mode (disables vi mode)
# bindkey -e
# bindkey '\e' vi-cmd-mode

# Prevent Delete key from activating vi normal mode
bindkey '^[[3~' delete-char  # Standard Delete key
bindkey '^?' backward-delete-char  # Backspace

# Prevent Ctrl+Arrow keys from activating vi normal mode
bindkey '^[[1;5D' backward-word  # Ctrl+Left Arrow
bindkey '^[[1;5C' forward-word   # Ctrl+Right Arrow

# Single Tab: "j<Tab>"→zcd, trailing space→fzf-tab,
#             ghost text present→autosuggest-accept, else→fzf-tab
_smart_tab() {
    if [[ "$BUFFER" == "j" ]]; then
        BUFFER=""
        CURSOR=0
        _zcd_widget
    elif [[ "$LBUFFER" == *" " ]]; then
        zle fzf-tab-complete
    elif [[ -n "$POSTDISPLAY" ]]; then
        # Ghost text visible → accept it
        zle autosuggest-accept
    else
        # No ghost text, no trailing space → open completion
        zle fzf-tab-complete
    fi
}
zle -N _smart_tab

# Delete previous word with Ctrl+Backspace in vi insert mode
bindkey -M viins $'\e\x7f' backward-kill-word
