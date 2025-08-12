# LazyVim Neovim configuration
alias vim='nvim'
alias vi='nvim'
export EDITOR='nvim'
export VISUAL='nvim'

# LazyVim specific aliases
alias lv='nvim'
alias lazyvim='nvim'

# Ensure nvim is available in PATH
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi
