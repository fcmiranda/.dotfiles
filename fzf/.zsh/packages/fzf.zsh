if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
fi
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
fi

# ─────────────────────────────────────────────────────────────────────────────
# FZF Configuration
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# CTRL-T: Replaced by Matchmaker (jump preset) — see ~/.zsh/utils/binds.zsh
# The _jump_widget runs `mm --no-read -o jump` and is the same widget bound
# to "j<Tab>" via _smart_tab. Rebind ^T in all keymaps to override the
# fzf-file-widget that key-bindings.zsh just installed.
# ─────────────────────────────────────────────────────────────────────────────
if (( $+commands[mm] )) && (( $+functions[_jump_widget] )); then
    bindkey -M emacs '^T' _jump_widget
    bindkey -M vicmd '^T' _jump_widget
    bindkey -M viins '^T' _jump_widget
fi

# FZF_CTRL_T_COMMAND / FZF_CTRL_T_OPTS are kept for manual fzf-file-widget use.
# ─────────────────────────────────────────────────────────────────────────────
export FZF_ALT_C_COMMAND=""
bindkey -r '\ec'
bindkey -M viins -r '\ec' 2>/dev/null || true
bindkey -M vicmd -r '\ec' 2>/dev/null || true


# ─────────────────────────────────────────────────────────────────────────────
# Useful FZF functions
# ─────────────────────────────────────────────────────────────────────────────

# frg - ripgrep with fzf (search file contents)
frg() {
    local file line
    read -r file line <<< $(rg --line-number --no-heading --color=always "${@:-}" | \
        fzf --ansi --delimiter=: \
            --preview='bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window=right:60%:+{2}-10 | \
        awk -F: '{print $1, $2}')
    [[ -n "$file" ]] && ${EDITOR:-vim} "$file" +"$line"
}

# Override Ctrl+T to use Matchmaker jump preset instead of FZF file widget
bindkey '^T' _jump_widget