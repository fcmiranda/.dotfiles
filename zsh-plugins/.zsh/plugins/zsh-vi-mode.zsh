# Source zsh-vi-mode configuration
if [ -f "${HOME}/.zsh-plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh" ]; then
    source "${HOME}/.zsh-plugins/zsh-vi-mode/zsh-vi-mode.plugin.zsh"
fi

# Custom keybindings after zsh-vi-mode initialization
function zvm_after_init() {
    # Unbind ctrl-p/ctrl-n and bind ctrl-j/ctrl-k for history navigation
    bindkey -M viins -r '^P'
    bindkey -M viins -r '^N'

    bindkey -M viins '^[[A' up-line-or-history
    bindkey -M viins '^K' up-line-or-history
    bindkey -M viins '^J' down-line-or-history
    bindkey -M viins '^[[B' down-line-or-history

    # Bind ctrl-r to atuin-search in insert mode
    bindkey -M viins '^R' atuin-search
}
