if [[ -f /usr/share/fzf/completion.zsh ]]; then
    source /usr/share/fzf/completion.zsh
fi
if [[ -f /usr/share/fzf/key-bindings.zsh ]]; then
    source /usr/share/fzf/key-bindings.zsh
fi

# ─────────────────────────────────────────────────────────────────────────────
# FZF Configuration
# ─────────────────────────────────────────────────────────────────────────────

# Default command - use fd if available, otherwise find
if command -v fd &> /dev/null; then
    export FZF_DEFAULT_COMMAND='fd --type f --strip-cwd-prefix --hidden --follow --exclude .git'
else
    export FZF_DEFAULT_COMMAND='find . -type f -not -path "*/\.git/*"'
fi

# Default options with catppuccin-inspired theme
export FZF_DEFAULT_OPTS="
    --height=60%
    --layout=reverse
    --border=rounded
    --info=inline
    --margin=1
    --padding=1
    --prompt='❯ '
    --pointer='▶'
    --marker='✓'
    --header-first
    --cycle
    --scroll-off=5
    --color=bg+:#313244,bg:#1e1e2e,spinner:#f5e0dc,hl:#f38ba8
    --color=fg:#cdd6f4,header:#f38ba8,info:#cba6f7,pointer:#f5e0dc
    --color=marker:#f5e0dc,fg+:#cdd6f4,prompt:#cba6f7,hl+:#f38ba8
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-d:preview-page-down'
    --bind='ctrl-u:preview-page-up'
    --bind='ctrl-a:select-all'
    --bind='ctrl-y:execute-silent(echo {+} | xclip -selection clipboard)'
"

# ─────────────────────────────────────────────────────────────────────────────
# CTRL-T: Paste selected files/directories onto command line
# ─────────────────────────────────────────────────────────────────────────────
if command -v fd &> /dev/null; then
    export FZF_CTRL_T_COMMAND='fd --type f --type d --strip-cwd-prefix --hidden --follow --exclude .git'
else
    export FZF_CTRL_T_COMMAND='find . -type f -o -type d -not -path "*/\.git/*"'
fi

export FZF_CTRL_T_OPTS="
    --preview='[[ -d {} ]] && eza --tree --level=2 --icons --color=always {} || bat --style=numbers --color=always --line-range=:300 {}'
    --preview-window=right:60%:border-left
    --bind='ctrl-/:toggle-preview'
    --header='CTRL-T: Select files/directories'
"

# ─────────────────────────────────────────────────────────────────────────────
# CTRL-R: Search command history
# ─────────────────────────────────────────────────────────────────────────────
export FZF_CTRL_R_OPTS="
    --preview='echo {}'
    --preview-window=down:3:wrap:hidden
    --bind='ctrl-/:toggle-preview'
    --bind='ctrl-y:execute-silent(echo -n {2..} | xclip -selection clipboard)+abort'
    --header='CTRL-R: Search history | CTRL-Y: Copy to clipboard'
    --color=header:italic
"

# ─────────────────────────────────────────────────────────────────────────────
# ALT-C: cd into selected directory
# ─────────────────────────────────────────────────────────────────────────────
if command -v fd &> /dev/null; then
    export FZF_ALT_C_COMMAND='fd --type d --strip-cwd-prefix --hidden --follow --exclude .git'
else
    export FZF_ALT_C_COMMAND='find . -type d -not -path "*/\.git/*"'
fi

export FZF_ALT_C_OPTS="
    --preview='eza --tree --level=2 --icons --color=always {}'
    --preview-window=right:60%:border-left
    --bind='ctrl-/:toggle-preview'
    --header='ALT-C: cd into directory'
"

# ─────────────────────────────────────────────────────────────────────────────
# Useful FZF functions
# ─────────────────────────────────────────────────────────────────────────────

# fkill - kill process with fzf
fkill() {
    local pid
    pid=$(ps -ef | sed 1d | fzf -m --header='Select process to kill' | awk '{print $2}')
    if [[ -n "$pid" ]]; then
        echo "$pid" | xargs kill -${1:-9}
    fi
}

# fe - open file with default editor
fe() {
    local file
    file=$(fzf --query="$1" --select-1 --exit-0 \
        --preview='bat --style=numbers --color=always --line-range=:300 {}')
    [[ -n "$file" ]] && ${EDITOR:-vim} "$file"
}

# fcd - cd to selected directory
fcd() {
    local dir
    dir=$(fd --type d --hidden --follow --exclude .git 2>/dev/null | fzf +m \
        --preview='eza --tree --level=2 --icons --color=always {}')
    [[ -n "$dir" ]] && cd "$dir"
}

# fh - search command history and execute
fh() {
    eval $(history | fzf +s --tac | sed 's/ *[0-9]* *//')
}

# fbr - checkout git branch
fbr() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf -d $((2 + $(wc -l <<< "$branches"))) +m) &&
    git checkout $(echo "$branch" | sed "s/.* //" | sed "s#remotes/[^/]*/##")
}

# fco - checkout git commit
fco() {
    local commits commit
    commits=$(git log --oneline --color=always) &&
    commit=$(echo "$commits" | fzf --ansi +m) &&
    git checkout $(echo "$commit" | awk '{print $1}')
}

# fga - git add with fzf
fga() {
    local files
    files=$(git status -s | fzf -m --preview='git diff --color=always {2}' | awk '{print $2}')
    [[ -n "$files" ]] && echo "$files" | xargs git add
}

# frg - ripgrep with fzf (search file contents)
frg() {
    local file line
    read -r file line <<< $(rg --line-number --no-heading --color=always "${@:-}" | \
        fzf --ansi --delimiter=: \
            --preview='bat --style=numbers --color=always --highlight-line {2} {1}' \
            --preview-window=right:60%:+{2}-10 | \
        awk -F: '{print $1, $2}')
    [[ -n "$file" ]] && ${EDITOR:-vim} "$file" +"$line"
}