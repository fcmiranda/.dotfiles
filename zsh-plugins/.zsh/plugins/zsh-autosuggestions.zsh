# Source zsh-autosuggestions plugin
if [ -f "${HOME}/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    # Must be set BEFORE sourcing — plugin reads these at load time
    ZSH_AUTOSUGGEST_STRATEGY=(history completion)

    source "${HOME}/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

    # Note: Tab bindings (^I) are handled in zvm_after_init to avoid override conflicts
fi