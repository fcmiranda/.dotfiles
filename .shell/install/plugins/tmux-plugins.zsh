#!/bin/zsh

# Install tmux plugins

# Unset git env vars to avoid conflicts with bare repo dotfile setups
unset GIT_DIR GIT_WORK_TREE

TMUX_PLUGINS_DIR="${HOME}/.tmux/plugins"
mkdir -p "$TMUX_PLUGINS_DIR"

install_tmux_plugin() {
  local name="$1"
  local repo="$2"
  local description="$3"
  
  if [ ! -d "$TMUX_PLUGINS_DIR/$name" ]; then
    echo "Installing $name - $description..."
    git clone "https://github.com/$repo" "$TMUX_PLUGINS_DIR/$name"
    echo "$name installed."
  else
    echo "$name is already installed."
  fi
}

install_tmux_plugin "tpm" "tmux-plugins/tpm" "Tmux Plugin Manager"
install_tmux_plugin "tmux-sensible" "tmux-plugins/tmux-sensible" "Basic tmux settings everyone can agree on"
install_tmux_plugin "tmux-catppuccin" "catppuccin/tmux" "Soothing pastel theme for tmux"
install_tmux_plugin "vim-tmux-navigator" "christoomey/vim-tmux-navigator" "Seamless navigation between tmux panes and vim splits"
install_tmux_plugin "tmux-tokyo-night" "janoamaral/tokyo-night-tmux" "Tokyo Night theme for tmux"
install_tmux_plugin "tmux-resurrect" "tmux-plugins/tmux-resurrect" "Persists tmux environment across system restarts"
install_tmux_plugin "tmux-continuum" "tmux-plugins/tmux-continuum" "Continuous saving of tmux environment"
install_tmux_plugin "tmux-online-status" "tmux-plugins/tmux-online-status" "Shows online status indicator in tmux status bar"
install_tmux_plugin "tmux-battery" "tmux-plugins/tmux-battery" "Battery percentage and status indicator for tmux"
install_tmux_plugin "tmux-nerd-font-window-name" "joshmedeski/tmux-nerd-font-window-name" "Display nerd font icons for tmux window names"
install_tmux_plugin "tmux-thumbs" "fcsonline/tmux-thumbs" "A lightning fast version of tmux-fingers written in Rust for copy/pasting with vimium/vimperator like hints"
install_tmux_plugin "tmux-fingers" "Morantron/tmux-fingers" "Copy pasting in terminal with vimium/vimperator like hints"
install_tmux_plugin "sesh" "joshmedeski/sesh" "Smart session manager for the terminal"