# Tmux configuration
alias tmux='tmux -2'
# Enable 256 color support
export TERM=screen-256color

# # Auto-start tmux on terminal open
# # Skip if: already inside tmux, running in a non-interactive shell,
# # inside an IDE terminal (VS Code, IntelliJ, etc.), or over SSH without tmux desired
# if command -v tmux &>/dev/null && \
#    [[ -z "$TMUX" ]] && \
#    [[ $- == *i* ]] && \
#    [[ -z "$VSCODE_RESOLVING_ENVIRONMENT" ]] && \
#    [[ "$TERM_PROGRAM" != "vscode" ]]; then
#   # Attach to existing session named "main" or create a new one
#   tmux attach-session -t main 2>/dev/null || tmux new-session -s main
# fi