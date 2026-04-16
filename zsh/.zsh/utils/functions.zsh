# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

# gcm — AI-generated commit message via opencode run (free model)
# Generates a conventional commit message from staged changes and
# pre-fills the shell prompt with: git commit -m "<message>"
# Usage: git add <files> && gcm
gcm() {
  if git diff --staged --quiet; then
    echo "gcm: no staged changes — run 'git add' first" >&2
    return 1
  fi

  local diff
  diff=$(git diff --staged)

  echo "gcm: generating commit message..." >&2

  # Build prompt as a variable and pass with -- to stop opencode from
  # treating diff content (lines like "-m ...") as CLI flags.
  local prompt="Analyze the following staged git diff and generate a concise, conventional commit message.

Rules:
- Use the conventional commits format: \`<type>(<optional scope>): <description>\`
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Keep the subject line under 72 characters
- If the changes are complex, add a short body after a blank line explaining the why
- Output ONLY the commit message, nothing else

Staged diff:
${diff}"

  local msg
  msg=$(opencode run --model opencode/gpt-5-nano -- "$prompt" 2>/dev/null)

  if [[ -z "$msg" ]]; then
    echo "gcm: failed to generate commit message" >&2
    return 1
  fi

  echo "$msg"
  # Pre-fill the zsh readline buffer so the user just hits Enter
  print -z "git commit -m ${(q)msg}"
}

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