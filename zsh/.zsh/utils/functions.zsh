# ─────────────────────────────────────────────────────────────────────────────
# Dotfiles Helper Functions
# ─────────────────────────────────────────────────────────────────────────────

# killport - Kill whatever process (or Docker container) is listening on a port
# Usage: killport <port>
# Examples:
#   killport 1313   # kill the hugo dev server
#   killport 3000   # kill a node server
#   killport 5432   # free up postgres
#
killport() {
    local port="$1"
    if [[ -z "$port" ]]; then
        echo "Usage: killport <port>"
        return 1
    fi

    # ── Docker containers exposing the port ──────────────────────────────────
    local containers
    containers=$(docker ps --format '{{.ID}} {{.Names}} {{.Ports}}' 2>/dev/null \
        | grep -E "0\.0\.0\.0:${port}->|:::${port}->" \
        | awk '{print $1}')
    if [[ -n "$containers" ]]; then
        echo "$containers" | while read -r cid; do
            local name
            name=$(docker inspect --format '{{.Name}}' "$cid" 2>/dev/null | sed 's|^/||')
            echo "  Stopping Docker container: $name ($cid)"
            docker stop "$cid"
        done
        return 0
    fi

    # ── Regular OS process ───────────────────────────────────────────────────
    local pids
    pids=$(lsof -ti tcp:"$port" 2>/dev/null)
    if [[ -z "$pids" ]]; then
        echo "  Nothing is listening on port $port"
        return 0
    fi

    echo "$pids" | while read -r pid; do
        local cmd
        cmd=$(ps -p "$pid" -o comm= 2>/dev/null)
        echo "  Killing PID $pid ($cmd) on port $port"
        kill -9 "$pid"
    done
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
    local dotfiles_dir="${DOTFILES_DIR:-$HOME/.dotfiles/main}"
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
# rebuild_lazygirts - Build and reinstall lazygitrs + lazygirts alias
# Usage: rebuild_lazygirts [-b <branch>] [repo_path]
#   -b <branch>  Build from a worktree branch (e.g. -b ai-commit-shortcut)
#   repo_path    Explicit path to repo (overrides -b)
rebuild_lazygirts() {
    local branch=""
    while [[ "$1" == -* ]]; do
        case "$1" in
            -b|--branch) branch="$2"; shift 2 ;;
            -h|--help)
                echo "Usage: rebuild_lazygirts [-b <branch>] [repo_path]"
                echo "  -b <branch>  Build from a worktree branch folder"
                echo "Default repo_path: $HOME/dev/github/lazygitrs/main"
                return 0
                ;;
            *) echo "Unknown option: $1"; return 1 ;;
        esac
    done

    local base_dir="$HOME/dev/github/lazygitrs"
    local default_path="${branch:+$base_dir/$branch}"
    local repo_path="${1:-${default_path:-$base_dir/main}}"
    local cargo_bin="$HOME/.cargo/bin/cargo"
    local install_dir="$HOME/.local/bin"

    if [[ ! -d "$repo_path" ]]; then
        echo "Error: repo not found: $repo_path"
        return 1
    fi

    if [[ ! -x "$cargo_bin" ]]; then
        echo "Error: cargo not found at $cargo_bin"
        return 1
    fi

    echo "Building lazygitrs from: $repo_path"
    (cd "$repo_path" && "$cargo_bin" build --release) || return 1

    mkdir -p "$install_dir" || return 1
    install -m 755 "$repo_path/target/release/lazygitrs" "$install_dir/lazygitrs" || return 1
    ln -sf "$install_dir/lazygitrs" "$install_dir/lazygirts" || return 1

    echo "Installed: $install_dir/lazygitrs"
    echo "Alias:     $install_dir/lazygirts"
    "$install_dir/lazygirts" --version
}
