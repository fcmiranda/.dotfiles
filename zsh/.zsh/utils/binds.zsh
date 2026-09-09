# # binds to use emacs mode (disables vi mode)
# bindkey -e
# bindkey '\e' vi-cmd-mode

# Prevent Delete key from activating vi normal mode
bindkey '^[[3~' delete-char  # Standard Delete key
bindkey '^?' backward-delete-char  # Backspace

# Word navigation keys
bindkey '^[[1;5D' backward-word  # Ctrl+Left Arrow
bindkey '^[[5D'   backward-word
bindkey '^[[1;3D' backward-word  # Alt+Left Arrow
bindkey '^[b'     backward-word

bindkey '^[[1;5C' forward-word   # Ctrl+Right Arrow
bindkey '^[[5C'   forward-word
bindkey '^[[1;3C' forward-word   # Alt+Right Arrow
bindkey '^[f'     forward-word


# Matchmaker Jump Widget: context-aware navigation & Object-First buffer ergonomics
_jump_widget() {
    local initial_buf="$BUFFER"
    local raw_result
    raw_result=$(mm --no-read -o jump)
    [[ -z "$raw_result" ]] && { zle reset-prompt; return 0; }

    local -a lines=("${(@f)raw_result}")
    local -a valid_lines=()
    for l in "${lines[@]}"; do
        [[ -n "$l" ]] && valid_lines+=("$l")
    done

    (( ${#valid_lines} == 0 )) && { zle reset-prompt; return 0; }

    # If a single directory was selected on an empty prompt -> cd immediately
    if (( ${#valid_lines} == 1 )) && [[ -z "${initial_buf// /}" ]]; then
        local target="${valid_lines[1]}"
        target="${target/#\~/$HOME}"
        target=$(realpath "$target" 2>/dev/null || echo "$target")
        if [[ -d "$target" ]]; then
            cd "$target" || cd "${valid_lines[1]}"
            BUFFER=""
            zle reset-prompt
            return 0
        fi
    fi

    # Format paths:
    # - If inside $PWD: use shortest relative path (e.g. "completion.md" or "docs/shell/completion.md")
    # - If outside $PWD: use canonical path with ~ compression (e.g. "~/.dotfiles/...")
    local -a formatted_items=()
    for line in "${valid_lines[@]}"; do
        local full_path
        full_path=$(realpath "$line" 2>/dev/null || echo "$line")
        local formatted=""
        if [[ "$full_path" == "$PWD/"* ]]; then
            local rel="${full_path#$PWD/}"
            formatted="${(q-)rel}"
        elif [[ "$full_path" == "$PWD" ]]; then
            formatted="."
        elif [[ "$full_path" == "$HOME"* ]]; then
            local rest="${full_path#$HOME/}"
            if [[ "$rest" != "$full_path" ]]; then
                rest="${(q-)rest}"
                formatted="~/$rest"
            else
                formatted="~"
            fi
        else
            formatted="${(q-)full_path}"
        fi
        formatted_items+=("$formatted")
    done

    local formatted_result="${(j: :)formatted_items}"
    [[ -z "$formatted_result" ]] && { zle reset-prompt; return 0; }

    if [[ -z "${initial_buf// /}" ]]; then
        # Empty command buffer: leading space and cursor at index 0 (Object-First ergonomics)
        BUFFER=" $formatted_result"
        CURSOR=0
    else
        # Active command buffer: append to cursor position with trailing space
        if [[ "$LBUFFER" == *" " || -z "$LBUFFER" ]]; then
            LBUFFER+="$formatted_result "
        else
            LBUFFER+=" $formatted_result "
        fi
    fi

    zle reset-prompt
}
zle -N _jump_widget
bindkey '^F' _jump_widget
bindkey -r '^T' 2>/dev/null || true


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
    # 1. Empty command line (or whitespace only) → do nothing (jump is on Ctrl+F)
    if [[ -z "${BUFFER// /}" ]]; then
        return
    fi

    # 2. Ghost text visible AND cursor at the end of the line → accept autosuggestion
    if [[ -n "$POSTDISPLAY" && $CURSOR -eq $#BUFFER ]]; then
        zle autosuggest-accept
        return
    fi

    # 3. Middle-of-line or argument completion → trigger Matchmaker completion via mm-ftb
    _auto_space_if_command
    zstyle ':fzf-tab:*' fzf-command mm-ftb
    if (( $+widgets[fzf-tab-complete] )); then
        zle fzf-tab-complete
    else
        zle expand-or-complete
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

# =============================================================================
# Prefix-aware history search navigation
# =============================================================================
autoload -U history-search-end
zle -N history-beginning-search-backward-end history-search-end
zle -N history-beginning-search-forward-end history-search-end

bindkey '^[[A' history-beginning-search-backward-end
bindkey '^K'   history-beginning-search-backward-end
bindkey '^J'   history-beginning-search-forward-end
bindkey '^[[B' history-beginning-search-forward-end

bindkey -M viins '^[[A' history-beginning-search-backward-end
bindkey -M viins '^K'   history-beginning-search-backward-end
bindkey -M viins '^J'   history-beginning-search-forward-end
bindkey -M viins '^[[B' history-beginning-search-forward-end

# Hook for zsh-vi-mode plugin to preserve keybindings after zvm init
_binds_zvm_setup() {
    # Unbind legacy ctrl-p/ctrl-n/ctrl-t in insert mode
    bindkey -M viins -r '^P' 2>/dev/null || true
    bindkey -M viins -r '^T' 2>/dev/null || true
    bindkey -M vicmd -r '^T' 2>/dev/null || true

    # Prefix-aware history search
    zvm_bindkey viins '^[[A' history-beginning-search-backward-end
    zvm_bindkey viins '^K'   history-beginning-search-backward-end
    zvm_bindkey viins '^J'   history-beginning-search-forward-end
    zvm_bindkey viins '^[[B' history-beginning-search-forward-end

    # Atuin history search
    if (( $+widgets[atuin-search] )); then
        zvm_bindkey viins '^R' atuin-search
        zvm_bindkey vicmd '^R' atuin-search
    fi

    # Word navigation (Ctrl+Left, Ctrl+Right, Alt+Left, Alt+Right)
    zvm_bindkey viins '^[[1;5D' backward-word
    zvm_bindkey viins '^[[5D'   backward-word
    zvm_bindkey viins '^[[1;3D' backward-word
    zvm_bindkey viins '^[b'     backward-word
    bindkey -M viins '^[[1;5D'  backward-word
    bindkey -M viins '^[[5D'    backward-word
    bindkey -M viins '^[[1;3D'  backward-word
    bindkey -M viins '^[b'      backward-word

    zvm_bindkey viins '^[[1;5C' forward-word
    zvm_bindkey viins '^[[5C'   forward-word
    zvm_bindkey viins '^[[1;3C' forward-word
    zvm_bindkey viins '^[f'     forward-word
    bindkey -M viins '^[[1;5C'  forward-word
    bindkey -M viins '^[[5C'    forward-word
    bindkey -M viins '^[[1;3C'  forward-word
    bindkey -M viins '^[f'      forward-word

    zvm_bindkey vicmd '^[[1;5D' backward-word
    zvm_bindkey vicmd '^[[1;5C' forward-word
    bindkey -M vicmd '^[[1;5D'  backward-word
    bindkey -M vicmd '^[[1;5C'  forward-word

    # Word deletion (Ctrl+Backspace / Alt+Backspace) & Delete key
    zvm_bindkey viins $'\e\x7f' backward-kill-word
    zvm_bindkey viins '^H'      backward-kill-word
    zvm_bindkey viins '^[^?'    backward-kill-word
    zvm_bindkey viins '^[[3~'   delete-char
    bindkey -M viins $'\e\x7f'  backward-kill-word
    bindkey -M viins '^H'       backward-kill-word
    bindkey -M viins '^[^?'     backward-kill-word
    bindkey -M viins '^[[3~'    delete-char

    # Custom widgets
    zvm_bindkey viins '^G' _git_files_widget
    zvm_bindkey vicmd '^G' _git_files_widget
    zvm_bindkey viins '^F' _jump_widget
    zvm_bindkey vicmd '^F' _jump_widget
    zvm_bindkey viins '^I' _smart_tab
    zvm_bindkey viins '^N' _mm_tab_widget
    zvm_bindkey vicmd '^N' _mm_tab_widget
}
zvm_after_init_commands+=('_binds_zvm_setup')







