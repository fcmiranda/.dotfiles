# Neovim configuration
alias vim='nvim'
alias vi='nvim'
export EDITOR='nvim'
export VISUAL='nvim'

# Add nvim to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Neovim specific aliases
alias nv='nvim'
alias neovim='nvim'

# Set XDG config directory for Neovim
export XDG_CONFIG_HOME="${XDG_CONFIG_HOME:-$HOME/.config}"
