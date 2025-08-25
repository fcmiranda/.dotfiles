export ZSH="$HOME/.oh-my-zsh"
plugins=(
git
starship
zsh-syntax-highlighting
zsh-autosuggestions
transient-prompt
)
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

bindkey '\t\t' autosuggest-accept

TRANSIENT_PROMPT_TRANSIENT_PROMPT='% '