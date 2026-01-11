
# Source the Omarchy initialization script
PATH="$HOME/.local/bin:$PATH"

source ~/.zsh/init.zsh

# All the default Omarchy aliases and functions
# (don't mess with these directly, just overwrite them here!)
# source from Omarchy
source ~/.local/share/omarchy/default/bash/aliases
source ~/.local/share/omarchy/default/bash/functions
source ~/.local/share/omarchy/default/bash/envs

# Locale settings (added by us-intl-locale.sh)
export LANG=en_US.UTF-8
export LC_ALL=en_US.UTF-8

. "$HOME/.local/share/../bin/env"
