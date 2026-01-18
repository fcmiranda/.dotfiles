# Source zsh-transient-prompt plugin
# When using zsh-vi-mode, transient-prompt must be loaded after zvm initialization
# because zvm overrides zle-line-finish widget

_load_transient_prompt() {
    if [ -f "${HOME}/.zsh-plugins/zsh-transient-prompt/transient-prompt.plugin.zsh" ]; then
        source "${HOME}/.zsh-plugins/zsh-transient-prompt/transient-prompt.plugin.zsh"
        TRANSIENT_PROMPT_TRANSIENT_PROMPT='% '
    fi
}

# Check if zsh-vi-mode is loaded and use its hook, otherwise load directly
if (( ${+functions[zvm_after_init]} )) || [[ -n "${zvm_after_init_commands+x}" ]]; then
    zvm_after_init_commands+=(_load_transient_prompt)
else
    _load_transient_prompt
fi