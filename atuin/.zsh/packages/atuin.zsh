export ATUIN_NOBIND=true
eval "$(atuin init zsh)"

# Bindings for default/emacs mode and vi mode
bindkey '^R' atuin-search
bindkey -M viins '^R' atuin-search 2>/dev/null || true
bindkey -M vicmd '^R' atuin-search 2>/dev/null || true

# Register with zsh-vi-mode after-init hook if available
_atuin_zvm_setup() {
    if (( $+widgets[atuin-search] )); then
        zvm_bindkey viins '^R' atuin-search
        zvm_bindkey vicmd '^R' atuin-search
    fi
}
zvm_after_init_commands+=('_atuin_zvm_setup')