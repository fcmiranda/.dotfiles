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
# CTRL-T: Unbound (Matchmaker Jump is bound to Ctrl+F in ~/.zsh/utils/binds.zsh)
# Unbind ^T in all keymaps to remove fzf-file-widget installed by key-bindings.zsh.
# ─────────────────────────────────────────────────────────────────────────────
bindkey -M emacs -r '^T' 2>/dev/null || true
bindkey -M vicmd -r '^T' 2>/dev/null || true
bindkey -M viins -r '^T' 2>/dev/null || true

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