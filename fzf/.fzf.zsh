# Setup fzf
# ---------
if [[ ! "$PATH" == */home/felipe/.fzf/bin* ]]; then
  PATH="${PATH:+${PATH}:}/home/felipe/.fzf/bin"
fi

source <(fzf --zsh)
