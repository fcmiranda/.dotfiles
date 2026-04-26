#!/usr/bin/env zsh

# Load helper functions
source "${HOME}/.zsh/helpers.zsh"

# Terminal Setup
# ghosttime -t 1 2>/dev/null || true
# printf '\n%.0s' {1..75}
# clear

# Source Order: Utils → Packages → Plugins
source_utils \
	history \
	aliases \
	functions \
	binds

source_packages \
	git \
	mise \
	starship \
	zoxide \
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

#   zsh-vi-mode \
source_plugins \
  zsh-vi-mode \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	zsh-transient-prompt \
	fzf-tab
