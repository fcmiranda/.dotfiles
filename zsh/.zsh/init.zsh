#!/usr/bin/env zsh

# Load helper functions
source "${HOME}/.zsh/helpers.zsh"

# Terminal Setup
# ghosttime -t 1 2>/dev/null || true
# printf '\n%.0s' {1..75}
# clear

# Initialize the zsh completion system before packages and plugins
autoload -Uz compinit && compinit

# Source Order: Utils → Completion → Packages → Plugins → Binds
source_utils \
	history \
	aliases \
	functions

source_packages \
	git \
	mise \
	starship \
	mm \
	fzf \
	atuin \
	yazi \
	duf \
	lolcat \
	figlet \
	procs \
	sesh \
	tmux \
	intelli-shell

source_if_exists packages fed cargo

source_plugins \
	zsh-vi-mode \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	zsh-transient-prompt \
	fzf-tab

# Load binds last so keybindings have final authority over plugins
source_utils binds

