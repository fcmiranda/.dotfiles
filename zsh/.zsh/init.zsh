#!/usr/bin/env zsh

# Load helper functions
source "${HOME}/.zsh/helpers.zsh"

# Terminal Setup
# ghosttime -t 1 2>/dev/null || true
# printf '\n%.0s' {1..75}
# clear

# Source Order: Utils → Packages → Plugins
source_utils \
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
	sesh

source_plugins \
    zsh-vi-mode \
	zsh-autosuggestions \
	zsh-syntax-highlighting \
	zsh-transient-prompt