# Update font cache after installation
if command -v fc-cache >/dev/null 2>&1; then
  fc-cache -fv ~/.local/share/fonts >/dev/null 2>&1
fi

# Helpful aliases
alias list-fonts='fc-list | grep -i nerd'
alias font-cache='fc-cache -fv ~/.local/share/fonts'
