# Starship configuration for Zsh
# Auto-detect omarchy theme and use matching starship theme
_starship_theme_path="$HOME/.config/starship/themes"
_omarchy_theme_name_file="$HOME/.config/omarchy/current/theme.name"

if [[ -f "$_omarchy_theme_name_file" ]]; then
  _current_theme=$(cat "$_omarchy_theme_name_file")
  if [[ -f "$_starship_theme_path/$_current_theme.toml" ]]; then
    export STARSHIP_CONFIG="$_starship_theme_path/$_current_theme.toml"
  else
    export STARSHIP_CONFIG="$HOME/.config/starship/config.toml"
  fi
else
  export STARSHIP_CONFIG="$HOME/.config/starship/config.toml"
fi

unset _starship_theme_path _omarchy_theme_name_file _current_theme

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