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
    zle -I 2>/dev/null || true
    local result

    result=$(mm --no-read -o jump)
    local exit_code=$?

    if [[ -n "$result" ]]; then
        if [[ $exit_code -eq 2 ]]; then
            LBUFFER+="$result"
        elif [[ -d "$result" ]]; then
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
    elif (( $+widgets[fzf-tab-complete] )); then
        # Command line has text → explicit fzf-tab completion
        zle fzf-tab-complete
    else
        # Standard completion fallback
        zle expand-or-complete
    fi
}
zle -N _smart_tab
bindkey '^I' _smart_tab
bindkey -M viins '^I' _smart_tab

# Ctrl+N explicitly triggers fzf-tab anytime (even with ghost text present)
_fzf_tab_widget() {
    if (( $+widgets[fzf-tab-complete] )); then
        zle fzf-tab-complete
    else
        zle expand-or-complete
    fi
}
zle -N _fzf_tab_widget
bindkey '^N' _fzf_tab_widget
bindkey -M viins '^N' _fzf_tab_widget
bindkey -M emacs '^N' _fzf_tab_widget


# Delete previous word with Ctrl+Backspace in vi insert mode
bindkey -M viins $'\e\x7f' backward-kill-word

# Git Status & Review Loop with lazygitrs (Alt+g)
_git_files_widget() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        [[ -n "$WIDGET" ]] && zle reset-prompt
        return 1
    fi

    if command -v lazygitrs >/dev/null 2>&1; then
        lazygitrs
    fi
    [[ -n "$WIDGET" ]] && zle reset-prompt
}
zle -N _git_files_widget
bindkey '\eg' _git_files_widget
bindkey -M viins '\eg' _git_files_widget
bindkey -M vicmd '\eg' _git_files_widget
bindkey -M emacs '\eg' _git_files_widget

# Hook for zsh-vi-mode plugin to preserve keybindings after zvm init
function zvm_after_init() {
    zvm_bindkey viins '\eg' _git_files_widget
    zvm_bindkey vicmd '\eg' _git_files_widget
    zvm_bindkey viins '^T' _jump_widget
    zvm_bindkey vicmd '^T' _jump_widget
    zvm_bindkey viins '^I' _smart_tab
    zvm_bindkey viins '^N' _fzf_tab_widget
    zvm_bindkey vicmd '^N' _fzf_tab_widget
}





