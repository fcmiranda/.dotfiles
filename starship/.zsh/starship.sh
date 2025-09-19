# Starship configuration for Zsh
export STARSHIP_CONFIG=$HOME/.config/starship/config.toml

# Initialize starship prompt
eval "$(starship init zsh)"

# Function to switch Starship themes
set-starship-theme() {
  if [ -f "$HOME/.config/starship/themes/$1.toml" ]; then
    export STARSHIP_CONFIG="$HOME/.config/starship/themes/$1.toml"
    echo "Starship theme set to $1"
    # Reload the shell to apply the changes
    exec $SHELL
  else
    echo "Theme '$1' not found."
  fi
}