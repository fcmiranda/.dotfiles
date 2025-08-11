# Kitty terminal emulator
# Add kitty to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Kitty terminal-specific aliases and functions (when running in kitty)
if [[ "$TERM" == "xterm-kitty" ]]; then
  # SSH with proper terminfo
  alias kssh="kitty +kitten ssh"
  
  # SSH fallback for when kssh fails
  alias kssh-slow="infocmp -a xterm-kitty | ssh myserver tic -x -o \~/.terminfo /dev/stdin"
  
  # Change color theme interactively
  alias kitty-theme="kitty +kitten themes"
  
  # Start kitty in background and keep it running after terminal closes
  kitty() {
    nohup kitty "$@" >/dev/null 2>&1 &
    disown
  }
fi

# Set TERM_PROGRAM for applications that check for kitty
export TERM_PROGRAM="kitty"
