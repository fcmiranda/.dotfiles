  # Configure fzf key bindings and completion
  [[ -f ~/.fzf.zsh ]] && source ~/.fzf.zsh
  # Set default fzf options
  export FZF_DEFAULT_OPTS='--height 40% --layout=reverse --border'
  # Use fd with fzf if available
  if command -v fd > /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --hidden --follow --exclude .git'
    export FZF_CTRL_T_COMMAND="$FZF_DEFAULT_COMMAND"
  fi