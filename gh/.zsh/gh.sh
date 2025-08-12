# GitHub CLI
export PATH="$HOME/.local/bin:$PATH"

# Enable completions
if command -v gh >/dev/null 2>&1; then
  eval "$(gh completion zsh)"
fi
