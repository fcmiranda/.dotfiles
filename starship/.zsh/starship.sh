
# Initialize starship prompt
eval "$(starship init zsh)"

# Enhanced transient prompt support for Starship
# This provides a minimal prompt for previous commands
if [[ -n "$STARSHIP_SESSION_KEY" ]]; then
    # Enable transient prompt if supported by Starship version
    autoload -Uz add-zsh-hook
    
    # Function to enable transient prompt
    starship_transient_prompt_precmd() {
        if [[ -n "$STARSHIP_SESSION_KEY" ]]; then
            # Clear right prompt for transient display
            RPROMPT=""
        fi
    }
    
    # Function to setup transient prompt after command execution
    starship_transient_prompt_preexec() {
        if [[ -n "$STARSHIP_SESSION_KEY" ]]; then
            # This will be called before each command
            # Starship handles the transient prompt automatically
            :
        fi
    }
    
    # Add hooks for transient prompt functionality
    add-zsh-hook precmd starship_transient_prompt_precmd
    add-zsh-hook preexec starship_transient_prompt_preexec
fi

# Additional zsh configuration for better Starship integration
setopt PROMPT_SUBST
setopt TRANSIENT_RPROMPT
