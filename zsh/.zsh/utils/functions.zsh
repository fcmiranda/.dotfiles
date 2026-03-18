# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

# dotadd - Copy current directory contents to dotfiles with proper stow structure
# Usage: dotadd <package-name> [files...]
#   If no files specified, copies all files in current directory
#
# Examples:
#   cd ~/.config/nvim && dotadd nvim          # Copy all nvim config
#   cd ~/.config/ghostty && dotadd ghostty config  # Copy specific file
#   dotadd zsh ~/.zshrc                       # Copy specific file from anywhere
#
dotadd() {
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles}"
    local package="$1"
    shift

    if [[ -z "$package" ]]; then
        echo "Usage: dotadd <package-name> [files...]"
        echo "  Copies files to $dotfiles_dir/<package>/ with proper stow structure"
        return 1
    fi

    local files=("$@")
    local cwd="$PWD"

    # If no files specified, use all files in current directory
    if [[ ${#files[@]} -eq 0 ]]; then
        files=(*(N))  # (N) = nullglob, don't error if empty
        if [[ ${#files[@]} -eq 0 ]]; then
            echo "Error: No files found in current directory"
            return 1
        fi
    fi

    # Determine the relative path from $HOME
    local rel_path
    if [[ "$cwd" == "$HOME"* ]]; then
        rel_path="${cwd#$HOME/}"
    else
        echo "Error: Current directory must be under \$HOME"
        return 1
    fi

    # Target directory in dotfiles
    local target_dir="$dotfiles_dir/$package/$rel_path"

    echo "Package: $package"
    echo "Source:  $cwd"
    echo "Target:  $target_dir"
    echo "Files:   ${files[*]}"
    echo

    # Create target directory
    mkdir -p "$target_dir"

    # Copy files
    local copied=0
    local failed=0
    for file in "${files[@]}"; do
        if [[ -e "$file" ]]; then
            if cp -r "$file" "$target_dir/"; then
                echo "  ✓ $file"
                ((copied++))
            else
                echo "  ✗ $file (copy failed)"
                ((failed++))
            fi
        else
            echo "  ✗ $file (not found)"
            ((failed++))
        fi
    done

    echo
    echo "Copied $copied file(s), $failed failed"

    if [[ $copied -gt 0 ]]; then
        echo
        echo "Running stow to create symlinks..."
        (cd "$dotfiles_dir" && ./stow.sh -a "$package")
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# opencode — tmux-aware wrapper with question tool notifications
# ─────────────────────────────────────────────────────────────────────────────
# When running inside tmux, spawns `opencode-notify` in the background.
# The notifier watches for opencode's `question` tool and fires a tmux
# bell + status-bar popup whenever the AI asks a question in an inactive
# window — so you don't miss it while working in a different window.
#
# Usage:  opencode [any opencode args]
# ─────────────────────────────────────────────────────────────────────────────
opencode() {
  # Outside tmux — just run opencode normally
  if [[ -z "${TMUX:-}" ]]; then
    command opencode "$@"
    return $?
  fi

  # Capture current tmux context
  local _pane _window _session _oc_pid _notify_pid
  _pane=$(tmux display-message -p "#{pane_id}")
  _window=$(tmux display-message -p "#{window_index}")
  _session=$(tmux display-message -p "#{session_name}")

  # Enable tmux activity monitoring on this window so the bell indicator works
  tmux set-window-option -t "${_session}:${_window}" monitor-activity on  2>/dev/null || true
  tmux set-window-option -t "${_session}:${_window}" monitor-bell on       2>/dev/null || true

  # Start the background notifier (it will discover the opencode PID itself)
  opencode-notify "$_pane" "$_session" "$_window" &
  _notify_pid=$!

  # Run opencode in the foreground
  command opencode "$@"
  local _ret=$?

  # Teardown: stop the notifier, restore window options
  kill "$_notify_pid" 2>/dev/null || true
  wait "$_notify_pid" 2>/dev/null || true
  tmux set-window-option -t "${_session}:${_window}" monitor-activity off 2>/dev/null || true

  return $_ret
}