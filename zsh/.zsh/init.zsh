#!/usr/bin/env zsh

# Load helper functions
source "${HOME}/.zsh/helpers.zsh"

# Terminal Setup
# ghosttime -t 1 2>/dev/null || true
# printf '\n%.0s' {1..75}
# clear

# Source Order: Utils → Packages → Completion → Plugins → Binds
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
	tmux

source_if_exists packages fed cargo

# Initialize the zsh completion system before plugins
autoload -Uz compinit && compinit

source_plugins \
	zsh-vi-mode \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	zsh-transient-prompt \
	fzf-tab

# Load binds last so keybindings have final authority over plugins
source_utils binds

