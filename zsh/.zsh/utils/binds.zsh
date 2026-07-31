# # binds to use emacs mode (disables vi mode)
# bindkey -e
# bindkey '\e' vi-cmd-mode

# Prevent Delete key from activating vi normal mode
bindkey '^[[3~' delete-char  # Standard Delete key
bindkey '^?' backward-delete-char  # Backspace

# Prevent Ctrl+Arrow keys from activating vi normal mode
bindkey '^[[1;5D' backward-word  # Ctrl+Left Arrow
bindkey '^[[1;5C' forward-word   # Ctrl+Right Arrow

# Single Tab: ghost text present→autosuggest-accept, else→_jump_widget
_jump_widget() {
    local result

    result=$(mm --no-read -o jump)
    local exit_code=$?

    if [[ -n "$result" ]]; then
        if [[ $exit_code -eq 2 ]]; then
            LBUFFER+="$result"
        elif [[ -d "$result" ]]; then
            zoxide add "$result"
            cd "$result"
        else
            LBUFFER+="$result"
        fi
    fi
    zle reset-prompt
}
zle -N _jump_widget
bindkey '^T' _jump_widget


_smart_tab() {
    if [[ -z "$BUFFER" ]]; then
        # Empty command line → open matchmaker jump widget directly
        zle _jump_widget
    elif [[ -n "$POSTDISPLAY" ]]; then
        # Ghost text visible → accept autosuggestion
        zle autosuggest-accept
    else
        # Command line has text → standard completion (fzf-tab)
        zle expand-or-complete
    fi
}
zle -N _smart_tab

# Delete previous word with Ctrl+Backspace in vi insert mode
bindkey -M viins $'\e\x7f' backward-kill-word
