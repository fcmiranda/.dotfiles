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


# wtr - Rename a worktrunk branch and its directory
# Usage: wtr [old-name] <new-name>
#   If old-name is omitted, it defaults to the branch of the current worktree.
#
# Examples:
#   wtr feature-auth login-redesign
#   wtr login-redesign (renames current worktree)
#
wtr() {
    local old_name
    local new_name

    if [[ "$#" -eq 1 ]]; then
        # Try to get the branch name from the current worktree
        old_name=$(git branch --show-current 2>/dev/null)
        if [[ -z "$old_name" ]]; then
            echo "Error: Not in a git repository or no branch found."
            return 1
        fi
        new_name="$1"
    elif [[ "$#" -eq 2 ]]; then
        old_name="$1"
        new_name="$2"
    else
        echo "Usage: wtr [old-name] <new-name>"
        return 1
    fi

    # 1. Remove the current worktree while keeping the branch (--no-delete-branch)
    #    Run in foreground (--foreground) to ensure it's gone before renaming.
    # 2. Rename the branch in git
    # 3. Create the new worktree with the updated name
    wt remove --no-delete-branch --foreground "$old_name" && \
    git branch -m "$old_name" "$new_name" && \
    wt switch "$new_name"
}

# OSC 7 Working Directory Notification for GPU Terminals (Ghostty / Kitty)
# Emits OSC 7 escape sequence on every directory change so Ghostty & Tmux sync working directory
chpwd() {
    printf "\033]7;file://%s%s\033\\" "${HOST:-$HOSTNAME}" "${PWD}"
}

# ai-fix - Capture last command, terminal error output, git status/diff, and dispatch to AI agent
# Usage: ai-fix [optional note]
ai-fix() {
    local last_status=$?
    local last_cmd
    last_cmd=$(fc -ln -1 2>/dev/null | sed 's/^[[:space:]]*//')
    if [[ -z "$last_cmd" ]]; then
        echo "ai-fix: No previous command found in history."
        return 1
    fi

    local user_note="$*"
    local last_output=""
    local git_context=""
    local repo_info=""

    # 1. Capture terminal scrollback from tmux (up to 45 lines)
    if [[ -n "$TMUX" ]]; then
        last_output=$(tmux capture-pane -p -S -80 2>/dev/null | sed '/^[[:space:]]*$/d' | tail -n 45)
    fi

    # 2. Capture Git & Worktree context (branch, status, recent diff)
    if git rev-parse --is-inside-work-tree >/dev/null 2>&1; then
        local branch
        branch=$(git branch --show-current 2>/dev/null || git rev-parse --short HEAD 2>/dev/null)
        local root
        root=$(git rev-parse --show-toplevel 2>/dev/null)
        local git_st
        git_st=$(git status --short 2>/dev/null | head -n 15)
        local git_diff
        git_diff=$(git diff -U2 HEAD 2>/dev/null | head -n 60)
        [[ -z "$git_diff" ]] && git_diff=$(git diff -U2 2>/dev/null | head -n 60)

        repo_info="**Working Directory:** \`$PWD\` (Repo: \`${root##*/}\` on branch \`$branch\`)\n"

        if [[ -n "$git_st" ]]; then
            git_context+="**Git Status (Modified/Untracked):**\n\`\`\`text\n$git_st\n\`\`\`\n\n"
        fi
        if [[ -n "$git_diff" ]]; then
            git_context+="**Recent Git Diff (Working Tree vs HEAD):**\n\`\`\`diff\n$git_diff\n\`\`\`\n\n"
        fi
    else
        repo_info="**Working Directory:** \`$PWD\`\n"
    fi

    # 3. Build structured 360° prompt
    local prompt="The following command failed or produced an error in the terminal:\n\n"
    prompt+="$repo_info\n"
    prompt+="**Executed command:** \`$last_cmd\`"
    (( last_status != 0 )) && prompt+=" (Exit code: $last_status)"
    prompt+="\n\n"

    if [[ -n "$last_output" ]]; then
        prompt+="**Recent terminal output / traceback:**\n\`\`\`text\n$last_output\n\`\`\`\n\n"
    fi

    if [[ -n "$git_context" ]]; then
        prompt+="$git_context"
    fi

    if [[ -n "$user_note" ]]; then
        prompt+="**Developer note:** $user_note\n\n"
    fi

    prompt+="Please analyze the error concisely, identify the root cause in the context of the recent code changes, and provide the exact fix or shell command."

    echo "󰚩 Enviando contexto 360° de '$last_cmd' ao agente..."

    if command -v opencode >/dev/null 2>&1; then
        opencode "$prompt"
    elif command -v agy >/dev/null 2>&1; then
        agy "$prompt"
    elif command -v claude >/dev/null 2>&1; then
        claude "$prompt"
    else
        echo "ai-fix: Nenhum agente ('opencode', 'agy' ou 'claude') encontrado no PATH."
        return 1
    fi
}

# wtj - Interactively select and jump (cd) into a Git Worktree via Matchmaker
# Usage: wtj
wtj() {
    local target
    target=$(mm -o wt)
    if [[ -n "$target" && -d "$target" ]]; then
        cd "$target"
    fi
}

# bd - Jump directly back to an ancestor directory by name
# Usage: bd <parent-dir-name>
# Example: in /a/b/matchmaker/src/foo, run 'bd matchmaker' -> jumps directly to /a/b/matchmaker
bd() {
    local target="$1"
    if [[ -z "$target" ]]; then
        cd ..
        return
    fi
    local curr="$PWD"
    while [[ "$curr" != "/" && "$curr" != "" ]]; do
        if [[ "$(basename "$curr")" == "$target" ]]; then
            cd "$curr"
            return 0
        fi
        curr="$(dirname "$curr")"
    done
    echo "bd: Ancestor directory '$target' not found."
    return 1
}

# acpd - Manage the ACPD daemon service
# Usage: acpd [status|start|stop|restart|logs|kill]
acpd() {
    local action="${1:-status}"
    case "$action" in
        start)
            systemctl --user start acpd.service && echo "acpd started"
            ;;
        stop)
            systemctl --user stop acpd.service && echo "acpd stopped"
            ;;
        restart)
            systemctl --user restart acpd.service && echo "acpd restarted"
            ;;
        status)
            systemctl --user status acpd.service
            ;;
        logs|log)
            journalctl --user -u acpd.service -f
            ;;
        kill)
            pkill -9 -x acpd 2>/dev/null && echo "acpd killed" || systemctl --user stop acpd.service
            ;;
        *)
            echo "Usage: acpd [status|start|stop|restart|logs|kill]"
            return 1
            ;;
    esac
}
# pasteto - Copy files to any frecency/project directory without leaving current context
# Usage: pasteto [files...] or pt [files...]
# If no files are passed, opens Matchmaker to visually select files in current directory.
pasteto() {
    local -a sources=("$@")

    # 1. Visual selection if no arguments passed
    if (( ${#sources} == 0 )); then
        local raw_items
        raw_items=$(mm --no-read 2>/dev/null)
        [[ -z "$raw_items" ]] && return 0
        local -a lines=("${(@f)raw_items}")
        for l in "${lines[@]}"; do
            [[ -n "$l" ]] && sources+=("$l")
        done
    fi

    if (( ${#sources} == 0 )); then
        echo "pasteto: Nenhum arquivo selecionado."
        return 1
    fi

    # 2. Select target destination directory using Matchmaker Frecency
    local target_dir
    target_dir=$(mm list --dirs 2>/dev/null | mm -o jump --header "PASTE TO (Escolha o Destino)")
    [[ -z "$target_dir" ]] && return 0

    target_dir="${target_dir/#\~/$HOME}"
    target_dir=$(realpath "$target_dir" 2>/dev/null || echo "$target_dir")

    if [[ ! -d "$target_dir" ]]; then
        echo "pasteto: Diretório de destino inválido: $target_dir"
        return 1
    fi

    # 3. Perform copy
    cp -a -- "${sources[@]}" "$target_dir/" || return 1
    echo "✓ ${#sources[@]} item(ns) copiado(s) para $target_dir"

    # 4. Optional 1-key jump to destination
    read -q "choice?Ir para o destino agora? [y/N] "
    echo
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        cd "$target_dir"
    fi
}

# moveto - Move files to any frecency/project directory without leaving current context
# Usage: moveto [files...] or mt [files...]
moveto() {
    local -a sources=("$@")

    # 1. Visual selection if no arguments passed
    if (( ${#sources} == 0 )); then
        local raw_items
        raw_items=$(mm --no-read 2>/dev/null)
        [[ -z "$raw_items" ]] && return 0
        local -a lines=("${(@f)raw_items}")
        for l in "${lines[@]}"; do
            [[ -n "$l" ]] && sources+=("$l")
        done
    fi

    if (( ${#sources} == 0 )); then
        echo "moveto: Nenhum arquivo selecionado."
        return 1
    fi

    # 2. Select target destination directory using Matchmaker Frecency
    local target_dir
    target_dir=$(mm list --dirs 2>/dev/null | mm -o jump --header "MOVE TO (Escolha o Destino)")
    [[ -z "$target_dir" ]] && return 0

    target_dir="${target_dir/#\~/$HOME}"
    target_dir=$(realpath "$target_dir" 2>/dev/null || echo "$target_dir")

    if [[ ! -d "$target_dir" ]]; then
        echo "moveto: Diretório de destino inválido: $target_dir"
        return 1
    fi

    # 3. Perform move
    mv -- "${sources[@]}" "$target_dir/" || return 1
    echo "✓ ${#sources[@]} item(ns) movido(s) para $target_dir"

    # 4. Optional 1-key jump to destination
    read -q "choice?Ir para o destino agora? [y/N] "
    echo
    if [[ "$choice" =~ ^[Yy]$ ]]; then
        cd "$target_dir"
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# AI Agent Worktree & Sesh Orchestration
# ─────────────────────────────────────────────────────────────────────────────

# aiwt / wtai - Create or select an isolated Git Worktree and launch an AI Agent Tmux session
# Usage:
#   aiwt                   -> Abre o Matchmaker (mm -o wt) para escolher ou navegar worktrees
#   aiwt <branch> [base]   -> Cria a worktree diretamente e conecta ao agente no Tmux
# Examples:
#   aiwt
#   aiwt feat-zsh-bench
#   wtai feat-nvim-lualine
aiwt() {
    local branch="$1"
    local base="${2:-HEAD}"

    if ! git rev-parse --is-inside-work-tree >/dev/null 2>&1 && ! git rev-parse --is-bare-repository >/dev/null 2>&1; then
        echo "aiwt: Você não está dentro de um repositório Git."
        return 1
    fi

    # Modo Interativo TUI: Se chamado sem argumentos, abre o Matchmaker (mm -o wt)
    if [[ -z "$branch" ]]; then
        local chosen
        if command -v mm >/dev/null 2>&1; then
            chosen=$(mm -o wt)
            [[ -z "$chosen" ]] && return 0
            chosen="${chosen/#\~/$HOME}"
            chosen=$(realpath "$chosen" 2>/dev/null || echo "$chosen")
            if command -v sesh >/dev/null 2>&1; then
                sesh connect "$chosen"
                return 0
            else
                cd "$chosen"
                return 0
            fi
        else
            echo "Uso: aiwt <nome-da-branch> [branch-base]"
            echo "Alias: wtai"
            return 1
        fi
    fi

    local target_dir=""
    local branch_clean="${branch//\//-}"
    local repo_root
    repo_root=$(git rev-parse --show-toplevel 2>/dev/null || pwd)
    target_dir="$repo_root/../$branch_clean"

    # 1. Cria ou alterna a worktree via worktrunk ou git puro
    if command -v wt >/dev/null 2>&1; then
        wt add "$branch" >/dev/null 2>&1 || wt switch "$branch" >/dev/null 2>&1
    fi

    if [[ ! -d "$target_dir" ]]; then
        git worktree add "$target_dir" -b "$branch" "$base" 2>/dev/null || \
        git worktree add "$target_dir" "$branch" 2>/dev/null || {
            echo "aiwt: Falha ao criar worktree em $target_dir"
            return 1
        }
    fi

    target_dir=$(realpath "$target_dir" 2>/dev/null || echo "$target_dir")
    echo "✓ Worktree pronta em $target_dir"

    # 2. Conecta instantaneamente via sesh no Tmux
    if command -v sesh >/dev/null 2>&1; then
        sesh connect "$target_dir"
    else
        cd "$target_dir"
    fi
}
alias wtai="aiwt"

# wtclone / wtc - Clone any Git repository into the .bare worktree container layout
# Usage: wtclone <user/repo | url> [custom-dest-dir]
# Examples:
#   wtclone fcmiranda/matchmaker
#   wtclone https://github.com/rust-lang/cargo.git
#   wtc user/repo
wtclone() {
    local target="$1"
    local dest_dir="$2"

    if [[ -z "$target" ]]; then
        echo "Uso: wtclone <user/repo | url> [diretório-destino]"
        echo "Alias: wtc, clone-wt"
        return 1
    fi

    local url=""
    local repo_name=""

    # 1. Normalização da URL e nome do repositório
    if [[ "$target" =~ ^https?:// ]] || [[ "$target" =~ ^git@ ]]; then
        url="$target"
        repo_name="${target##*/}"
        repo_name="${repo_name%.git}"
    elif [[ "$target" =~ / ]]; then
        url="https://github.com/${target}.git"
        repo_name="${target##*/}"
    else
        url="https://github.com/fcmiranda/${target}.git"
        repo_name="$target"
    fi

    # 2. Definição do diretório de destino (padrão: ~/dev/github/<repo_name>)
    local base_dir="${dest_dir:-$HOME/dev/github/$repo_name}"
    base_dir="${base_dir/#\~/$HOME}"

    if [[ -d "$base_dir" ]]; then
        echo "wtclone: O diretório $base_dir já existe."
        if command -v sesh >/dev/null 2>&1 && [[ -d "$base_dir/main" ]]; then
            sesh connect "$base_dir/main"
            return 0
        fi
        return 1
    fi

    echo "==> Clonando repositório bare em: $base_dir/.bare"
    mkdir -p "$base_dir" || return 1
    
    # 3. Clone em modo --bare
    if ! git clone --bare "$url" "$base_dir/.bare"; then
        echo "wtclone: Falha ao clonar $url"
        rm -rf "$base_dir"
        return 1
    fi

    # 4. Configura o refspec para rastreamento padrão de branches remotas
    git -C "$base_dir/.bare" config remote.origin.fetch "+refs/heads/*:refs/remotes/origin/*"
    git -C "$base_dir/.bare" fetch origin --quiet

    # 5. Descobre a branch padrão (main, master, etc.)
    local default_branch
    default_branch=$(git -C "$base_dir/.bare" symbolic-ref --short refs/remotes/origin/HEAD 2>/dev/null | sed 's|^origin/||')
    if [[ -z "$default_branch" ]]; then
        default_branch=$(git -C "$base_dir/.bare" branch -r | grep -E 'origin/(main|master)' | head -n1 | sed -E 's|.*origin/||' | tr -d ' ')
    fi
    [[ -z "$default_branch" ]] && default_branch="main"

    echo "==> Criando worktree principal: $base_dir/$default_branch"
    git -C "$base_dir/.bare" worktree add "$base_dir/$default_branch" "$default_branch" 2>/dev/null || \
    git -C "$base_dir/.bare" worktree add "$base_dir/$default_branch" -b "$default_branch" "origin/$default_branch" 2>/dev/null || \
    git -C "$base_dir/.bare" worktree add "$base_dir/$default_branch" -b "$default_branch"

    echo "✓ Repositório configurado com sucesso em $base_dir"

    # 6. Conecta via sesh no Tmux ou navega para a pasta
    if command -v sesh >/dev/null 2>&1; then
        sesh connect "$base_dir/$default_branch"
    else
        cd "$base_dir/$default_branch"
    fi
}
alias wtc="wtclone"
alias clone-wt="wtclone"



