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


_auto_space_if_command() {
    # If buffer is an exact command, alias or function without trailing space,
    # auto-append a space so Zsh completes its arguments (e.g. branches/files)
    if [[ -n "$BUFFER" && "$BUFFER" != *" " ]]; then
        if (( $+aliases[$BUFFER] )) || (( $+commands[$BUFFER] )) || (( $+functions[$BUFFER] )); then
            BUFFER="$BUFFER "
            CURSOR=$#BUFFER
        fi
    fi
}

_smart_tab() {
    local trimmed="${BUFFER// /}"
    if [[ -z "$trimmed" ]]; then
        # Empty command line (or whitespace only) → open matchmaker jump widget directly
        zle _jump_widget
    elif [[ -n "$POSTDISPLAY" ]]; then
        # Ghost text visible → accept autosuggestion
        zle autosuggest-accept
    else
        _auto_space_if_command
        # Command line has text → trigger Matchmaker completion via mm-ftb
        zstyle ':fzf-tab:*' fzf-command mm-ftb
        if (( $+widgets[fzf-tab-complete] )); then
            zle fzf-tab-complete
        else
            zle expand-or-complete
        fi
    fi
}
zle -N _smart_tab
bindkey '^I' _smart_tab
bindkey -M viins '^I' _smart_tab

# =============================================================================
# Matchmaker Completion (Ctrl+N): Uses Matchmaker (mm-ftb) as the completion UI
# =============================================================================
_mm_tab_widget() {
    _auto_space_if_command
    zstyle ':fzf-tab:*' fzf-command mm-ftb
    if (( $+widgets[fzf-tab-complete] )); then
        zle fzf-tab-complete
    else
        zle expand-or-complete
    fi
}
zle -N _mm_tab_widget
bindkey '^N' _mm_tab_widget
bindkey -M viins '^N' _mm_tab_widget
bindkey -M emacs '^N' _mm_tab_widget

# =============================================================================
# FZF-Tab Completion (Ctrl+F): Uses classic FZF as the completion UI (Disabled)
# =============================================================================
# _fzf_tab_widget() {
#     _auto_space_if_command
#     zstyle ':fzf-tab:*' fzf-command fzf
#     if (( $+widgets[fzf-tab-complete] )); then
#         zle fzf-tab-complete
#     else
#         zle expand-or-complete
#     fi
# }
# zle -N _fzf_tab_widget
# bindkey '^F' _fzf_tab_widget
# bindkey -M viins '^F' _fzf_tab_widget
# bindkey -M emacs '^F' _fzf_tab_widget

# Delete previous word with Ctrl+Backspace in vi insert mode
bindkey -M viins $'\e\x7f' backward-kill-word

# Git Status & Review Loop with lazygitrs (Ctrl+g)
_git_files_widget() {
    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        [[ -n "$WIDGET" ]] && zle reset-prompt
        return 1
    fi

    if [[ -n "$TMUX" ]]; then
        if tmux display-message -p '#{session_name}' 2>/dev/null | grep -q '^_popups'; then
            tmux detach-client
        else
            ~/.config/tmux/lazygitrs-popup.sh "$PWD"
        fi
    elif command -v lazygitrs >/dev/null 2>&1; then
        lazygitrs
    fi
    [[ -n "$WIDGET" ]] && zle reset-prompt
}
zle -N _git_files_widget
bindkey '^G' _git_files_widget
bindkey -M viins '^G' _git_files_widget
bindkey -M vicmd '^G' _git_files_widget
bindkey -M emacs '^G' _git_files_widget

# Hook for zsh-vi-mode plugin to preserve keybindings after zvm init
function zvm_after_init() {
    zvm_bindkey viins '^G' _git_files_widget
    zvm_bindkey vicmd '^G' _git_files_widget
    zvm_bindkey viins '^T' _jump_widget
    zvm_bindkey vicmd '^T' _jump_widget
    zvm_bindkey viins '^I' _smart_tab
    zvm_bindkey viins '^N' _mm_tab_widget
    zvm_bindkey vicmd '^N' _mm_tab_widget
    # zvm_bindkey viins '^F' _fzf_tab_widget
    # zvm_bindkey vicmd '^F' _fzf_tab_widget
}







