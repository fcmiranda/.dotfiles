# Ghostty terminal emulator
export GHOSTTY_HOME="$HOME/.local/share/ghostty"
# Add ghostty to PATH if not already there
if [[ ":$PATH:" != *":$HOME/.local/bin:"* ]]; then
  export PATH="$HOME/.local/bin:$PATH"
fi

# Start ghostty in background and keep it running after terminal closes
ghostty() {
  nohup ghostty "$@" >/dev/null 2>&1 &
  disown
}