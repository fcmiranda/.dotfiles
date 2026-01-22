# Source zsh-autosuggestions plugin
if [ -f "${HOME}/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "${HOME}/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

    # Ensure the binding works in vi insert mode (and emacs mode as a fallback)
    bindkey -M viins '^I' autosuggest-accept
    bindkey -M emacs '^I' autosuggest-accept
fi