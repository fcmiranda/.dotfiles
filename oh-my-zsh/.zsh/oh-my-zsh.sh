# Configure Oh My Zsh with Starship integration
export ZSH="$HOME/.oh-my-zsh"

# Plugins configuration
plugins=(
    git
    starship
    transient-prompt
    zsh-autosuggestions
    zsh-syntax-highlighting
)

# Load Oh My Zsh
[[ -f $ZSH/oh-my-zsh.sh ]] && source $ZSH/oh-my-zsh.sh

# Starship with enhanced transient prompt configuration
if command -v starship >/dev/null 2>&1; then
    # Initialize Starship
    eval "$(starship init zsh)"
    
    # Configure transient prompt settings for zsh-transient-prompt plugin
    # This creates a minimal prompt for completed commands
    typeset -g TRANSIENT_PROMPT_TRANSIENT_PROMPT='%F{green}❯%f '
    typeset -g TRANSIENT_PROMPT_TRANSIENT_RPROMPT=''
    
    # Hook function to enhance transient prompt behavior
    function TRANSIENT_PROMPT_PRETRANSIENT() {
        # Clear any lingering right prompts for cleaner transient display
        RPROMPT=""
    }
    
    # Set up Starship environment variables for transient support
    export STARSHIP_CONFIG="$HOME/.config/starship.toml"
    
    # Additional zsh configuration for better prompt handling
    setopt PROMPT_SUBST
    setopt TRANSIENT_RPROMPT
fi

# Alternative manual transient implementation (fallback if plugin doesn't work)
# Uncomment the following if you prefer a manual implementation:
#
# autoload -Uz add-zsh-hook
# 
# # Function to set transient prompt after command execution
# _set_transient_prompt() {
#     # Only show a simple prompt for previous commands
#     PROMPT='%F{green}❯%f '
#     RPROMPT=''
# }
# 
# # Function to restore full prompt before new command
# _restore_full_prompt() {
#     # This will be handled by Starship automatically
#     :
# }
# 
# add-zsh-hook preexec _set_transient_prompt
# add-zsh-hook precmd _restore_full_prompt
