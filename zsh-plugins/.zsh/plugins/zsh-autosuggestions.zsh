# Source zsh-autosuggestions plugin
if [ -f "${HOME}/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh" ]; then
    source "${HOME}/.zsh-plugins/zsh-autosuggestions/zsh-autosuggestions.zsh"

    bindkey '\t\t' autosuggest-accept
fi