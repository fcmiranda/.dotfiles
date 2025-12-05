# ─────────────────────────────────────────────────────────────────────────────
# Git Aliases and Functions
# ─────────────────────────────────────────────────────────────────────────────

# ─────────────────────────────────────────────────────────────────────────────
# Status & Info
# ─────────────────────────────────────────────────────────────────────────────

alias gs='git status --short --branch'
alias gst='git status'
alias gl='git log --oneline --graph --decorate'
alias glp='git log --oneline --graph --decorate --patch'
alias gll='git log --oneline --graph --decorate --all'
alias gld='git log --oneline --graph --decorate --date=short --pretty=format:"%C(auto)%h %C(green)%ad %C(auto)%s %C(cyan)%d"'
alias gshow='git show --stat --pretty=format:"%C(auto)%H%n%C(green)Author: %an <%ae>%n%C(green)Date:   %ad%n%C(auto)%n%s%n%n%b"'

# ─────────────────────────────────────────────────────────────────────────────
# Branch Management
# ─────────────────────────────────────────────────────────────────────────────

alias gb='git branch --verbose'
alias gba='git branch --all --verbose'
alias gbd='git branch --delete'
alias gbD='git branch --delete --force'
alias gbm='git branch --move'
alias gbr='git branch --remotes'

# Checkout
alias gco='git checkout'
alias gcb='git checkout -b'
alias gcm='git checkout main 2>/dev/null || git checkout master'
alias gcd='git checkout develop'

# ─────────────────────────────────────────────────────────────────────────────
# Staging & Committing
# ─────────────────────────────────────────────────────────────────────────────

alias ga='git add'
alias gaa='git add --all'
alias gap='git add --patch'
alias gai='git add --interactive'

alias gc='git commit'
alias gcm='git commit --message'
alias gca='git commit --amend'
alias gcan='git commit --amend --no-edit'
alias gcf='git commit --fixup'

# ─────────────────────────────────────────────────────────────────────────────
# Remote Operations
# ─────────────────────────────────────────────────────────────────────────────

alias gf='git fetch'
alias gfa='git fetch --all'
alias gfp='git fetch --prune'

alias gp='git push'
alias gpf='git push --force-with-lease'
alias gpo='git push origin'
alias gpot='git push origin --tags'
alias gpu='git push upstream'

alias gl='git pull'
alias glr='git pull --rebase'
alias glra='git pull --rebase --autostash'

# ─────────────────────────────────────────────────────────────────────────────
# Diff & Comparison
# ─────────────────────────────────────────────────────────────────────────────

alias gd='git diff'
alias gds='git diff --staged'
alias gdw='git diff --word-diff'
alias gdc='git diff --cached'

alias gdt='git difftool'
alias gmt='git mergetool'

# ─────────────────────────────────────────────────────────────────────────────
# Stashing
# ─────────────────────────────────────────────────────────────────────────────

alias gsta='git stash push'
alias gstp='git stash pop'
alias gstl='git stash list'
alias gsts='git stash show --patch'
alias gstd='git stash drop'
alias gstc='git stash clear'

# ─────────────────────────────────────────────────────────────────────────────
# Rebasing & Merging
# ─────────────────────────────────────────────────────────────────────────────

alias grb='git rebase'
alias grbi='git rebase --interactive'
alias grbc='git rebase --continue'
alias grba='git rebase --abort'
alias grbs='git rebase --skip'

alias gm='git merge'
alias gma='git merge --abort'
alias gmc='git merge --continue'

# ─────────────────────────────────────────────────────────────────────────────
# Working Directory
# ─────────────────────────────────────────────────────────────────────────────

alias gcl='git clean'
alias gclf='git clean --force'
alias gcli='git clean --interactive'

alias grs='git reset'
alias grsh='git reset --hard'
alias grss='git reset --soft'
alias grsm='git reset --mixed'

alias grm='git rm'
alias grmc='git rm --cached'

# ─────────────────────────────────────────────────────────────────────────────
# Advanced Operations
# ─────────────────────────────────────────────────────────────────────────────

alias gcp='git cherry-pick'
alias gcpc='git cherry-pick --continue'
alias gcpa='git cherry-pick --abort'

alias grv='git revert'
alias grvc='git revert --continue'
alias grva='git revert --abort'

alias gbl='git blame'
alias gbs='git bisect'
alias gbsg='git bisect good'
alias gbsb='git bisect bad'
alias gbsr='git bisect reset'

# ─────────────────────────────────────────────────────────────────────────────
# Git Flow / Workflow
# ─────────────────────────────────────────────────────────────────────────────

# Quick commit with message
gcq() {
    git add --all && git commit --message "$*"
}

# Amend last commit with current changes
gcaa() {
    git add --all && git commit --amend --no-edit
}

# Push current branch
gpp() {
    git push origin "$(git branch --show-current)"
}

# Force push current branch (with lease)
gppf() {
    git push --force-with-lease origin "$(git branch --show-current)"
}

# Create and switch to new branch
gnb() {
    if [[ -z "$1" ]]; then
        echo "Usage: gnb <branch-name>"
        return 1
    fi
    git checkout -b "$1"
}

# Delete merged branches
gbdm() {
    git branch --merged | grep -vE "(^\*|master|main|develop)" | xargs -r git branch --delete
}

# Show git stats
gstats() {
    echo "=== Git Statistics ==="
    echo "Commits: $(git rev-list --count HEAD)"
    echo "Contributors: $(git shortlog -sn --no-merges | wc -l)"
    echo "Files: $(git ls-files | wc -l)"
    echo "Size: $(git ls-files | xargs du -ch | tail -1 | cut -f1)"
}

# ─────────────────────────────────────────────────────────────────────────────
# FZF Integration (requires fzf)
# ─────────────────────────────────────────────────────────────────────────────

# Checkout branch with fzf
gcfb() {
    local branches branch
    branches=$(git branch --all | grep -v HEAD) &&
    branch=$(echo "$branches" | fzf --height=20% --reverse --info=inline | sed "s/.* //" | sed "s#remotes/[^/]*/##") &&
    git checkout "$branch"
}

# Checkout commit with fzf
gfco() {
    local commits commit
    commits=$(git log --oneline --color=always) &&
    commit=$(echo "$commits" | fzf --ansi +m) &&
    git checkout "$(echo "$commit" | awk '{print $1}')"
}

# Add files with fzf
gfga() {
    local files
    files=$(git status --porcelain | fzf --multi --preview='git diff --color=always {2}' | awk '{print $2}') &&
    [[ -n "$files" ]] && echo "$files" | xargs git add
}

# ─────────────────────────────────────────────────────────────────────────────
# Utility Functions
# ─────────────────────────────────────────────────────────────────────────────

# Get current branch name
gcbn() {
    git branch --show-current 2>/dev/null || git rev-parse --abbrev-ref HEAD
}

# Check if working directory is clean
gis_clean() {
    [[ -z "$(git status --porcelain)" ]]
}

# Get repository root
groot() {
    git rev-parse --show-toplevel 2>/dev/null
}

# Open repository in default editor
gedit() {
    local root
    root=$(groot)
    if [[ -n "$root" ]]; then
        ${EDITOR:-vim} "$root"
    else
        echo "Not in a git repository"
        return 1
    fi
}

# ─────────────────────────────────────────────────────────────────────────────
# Configuration Helpers
# ─────────────────────────────────────────────────────────────────────────────

# Set git user name and email
guser() {
    if [[ $# -ne 2 ]]; then
        echo "Usage: guser 'Your Name' 'your.email@example.com'"
        return 1
    fi
    git config user.name "$1"
    git config user.email "$2"
    echo "Git user set to: $1 <$2>"
}

# Show current git configuration
gconfig() {
    echo "=== Git Configuration ==="
    echo "User: $(git config user.name) <$(git config user.email)>"
    echo "Editor: $(git config core.editor)"
    echo "Default branch: $(git config init.defaultBranch)"
    echo "Auto-correction: $(git config help.autocorrect)"
    echo "Push default: $(git config push.default)"
    echo "Pull rebase: $(git config pull.rebase)"
}

# Initialize a new git repository with sensible defaults
ginit() {
    git init
    git config init.defaultBranch main
    git config core.editor "${EDITOR:-vim}"
    git config help.autocorrect 1
    git config push.default simple
    git config pull.rebase false
    echo "Git repository initialized with sensible defaults"
}