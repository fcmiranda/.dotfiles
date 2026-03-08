
log() {
	printf '[setup:zsh] %s\n' "$*"
}

fail() {
	printf '[setup:zsh] ERROR: %s\n' "$*" >&2
	exit 1
}

detect_package_manager() {
	local managers=(pacman yay paru)
	for manager in "${managers[@]}"; do
		if command -v "${manager}" >/dev/null 2>&1; then
			printf '%s' "${manager}"
			return 0
		fi
	done
	return 1
}

install_zsh() {
	local manager
	if ! manager="$(detect_package_manager)"; then
		fail "No Arch-compatible package manager found; install zsh manually."
	fi

	log "Installing zsh via ${manager}"
	case "${manager}" in
		pacman)
			sudo pacman -Sy --needed zsh
			;;
		yay|paru)
			"${manager}" -Sy --needed zsh
			;;
		*)
			fail "Package manager ${manager} is not handled; install zsh manually."
			;;
	 esac
}

ensure_default_shell() {
	local target_shell current_shell
	target_shell="$(command -v zsh)"
	current_shell="$(getent passwd "${USER}" | cut -d: -f7)"
	current_shell="${current_shell:-${SHELL:-}}"

	if [[ "${current_shell}" == "${target_shell}" ]]; then
		log "zsh already set as the default shell"
		return 0
	fi

	if ! command -v chsh >/dev/null 2>&1; then
		log "chsh not available; set your default shell to ${target_shell} manually"
		return 0
	fi

	log "Setting default shell to ${target_shell}"
	if chsh -s "${target_shell}"; then
		log "Default shell updated; log out and back in to apply"
        return 0
	else
		log "Failed to update default shell; run 'chsh -s ${target_shell}' manually"
	fi
}

main() {
	if command -v zsh >/dev/null 2>&1; then
		log "zsh already installed"
	else
		install_zsh
	fi

	ensure_default_shell
}

main "$@"
