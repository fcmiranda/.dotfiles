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
_jump_widget() {
    local result
    local _ignore_dirs=(
        node_modules .cache target dist build __pycache__
        .venv venv env vendor .gradle .npm .pnpm-store
        .next out coverage .tox .mypy_cache .pytest_cache
        .cargo .rustup .local .mozilla .thunderbird
    )

    if [[ "$PWD" == "$HOME" ]]; then
        result=$( {
            zoxide query -l 2>/dev/null
            zoxide query -l 2>/dev/null | while IFS= read -r _zd; do
                fd -H -E.git "${_ignore_dirs[@]/#/-E}" -a --max-depth 3 . "$_zd" 2>/dev/null
            done
            fd -H -E.git "${_ignore_dirs[@]/#/-E}" -a . "$HOME" 2>/dev/null
        } | awk '!seen[$0]++' | mm -o jump )
    else
        result=$(fd -td -H -E.git "${_ignore_dirs[@]/#/-E}" -a . | mm -o jump)
    fi

    if [[ -n "$result" ]]; then
        if [[ -d "$result" ]]; then
            zoxide add "$result"
            cd "$result"
        else
            LBUFFER+="$result"
        fi
    fi
    zle reset-prompt
}
zle -N _jump_widget

_smart_tab() {
    if [[ "$BUFFER" == "j" ]]; then
        BUFFER=""
        CURSOR=0
        zle _jump_widget
    elif [[ "$BUFFER" == "h" ]]; then
        BUFFER=""
        CURSOR=0
        zle _zcd_widget
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
