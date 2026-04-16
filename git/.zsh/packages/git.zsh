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
alias gcd='git checkout develop'

# ─────────────────────────────────────────────────────────────────────────────
# Staging & Committing
# ─────────────────────────────────────────────────────────────────────────────

alias gadd='git add'
alias gaa='git add --all'
alias gap='git add --patch'
alias gai='git add --interactive'

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

alias gdiff='git diff'
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

# ─────────────────────────────────────────────────────────────────────────────
# AI Helpers
# ─────────────────────────────────────────────────────────────────────────────

# gc — generate a conventional commit message from staged changes via AI
#
# Usage:
#   gc                          # uses default provider (opencode)
#   gc -p claude                # use claude CLI
#   gc -p crush                 # use crush CLI
#   gc -p copilot               # use gh copilot CLI
#   gc -m github-copilot/gpt-4o # override model (opencode only)
#
# Env overrides:
#   GC_PROVIDER=claude gc
#   GC_MODEL=github-copilot/gpt-5 gc
#
# Pre-fills the zsh readline buffer with: git commit -m "<message>"
gc() {
  local provider="${GC_PROVIDER:-opencode}"
  local model="${GC_MODEL:-github-copilot/gpt-4o}"

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--provider) provider="$2"; shift 2 ;;
      -m|--model)    model="$2";    shift 2 ;;
      -h|--help)
        echo "Usage: gc [-p provider] [-m model]"
        echo "Providers: opencode (default), claude, crush, copilot"
        return 0 ;;
      *) echo "gc: unknown option '$1'" >&2; return 1 ;;
    esac
  done

  if git diff --staged --quiet; then
    # No staged changes — check for unstaged/untracked files
    local unstaged
    unstaged=$(git -c color.status=always status --short | grep -v '^[MADRCU]')
    if [[ -z "$unstaged" ]]; then
      echo "gc: nothing to commit — working tree clean" >&2
      return 1
    fi

    local choice
    choice=$(gum choose "Add all files" "Select files")

    case "$choice" in
      "Add all files")
        git add --all
        ;;
      "Select files")
        local selected
        selected=$(git status --short | grep -v '^[MADRCU]' | awk '{print $2}' \
          | gum filter --no-limit --placeholder "select files to stage…")
        if [[ -z "$selected" ]]; then
          echo "gc: no files selected" >&2
          return 1
        fi
        echo "$selected" | xargs git add
        ;;
      *)
        echo "gc: aborted" >&2
        return 1
        ;;
    esac
  fi

  local diff
  diff=$(git diff --staged)

  local prompt="Analyze the following staged git diff and generate a concise, conventional commit message.

Rules:
- Use the conventional commits format: \`<type>(<optional scope>): <description>\`
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Keep the subject line under 72 characters
- If the changes are complex, add a short body after a blank line explaining the why
- Output ONLY the commit message, nothing else

Staged diff:
${diff}"

  # Write to tempfile — avoids diff lines (e.g. '-m ...') being parsed as CLI flags
  local tmpfile
  tmpfile=$(mktemp /tmp/gc.XXXXXX)
  printf '%s' "$prompt" > "$tmpfile"
  trap "rm -f $tmpfile" EXIT INT

  # Generate message with gum spinner
  local msg
  msg=$(gum spin --spinner dot --title "generating commit message via ${provider}..." -- sh -c "
    case '$provider' in
      opencode) opencode run --model '$model' -- \"\$(cat $tmpfile)\" 2>/dev/null ;;
      claude)   claude --print \"\$(cat $tmpfile)\" 2>/dev/null ;;
      crush)    crush \"\$(cat $tmpfile)\" 2>/dev/null ;;
      copilot)  gh copilot explain \"\$(cat $tmpfile)\" 2>/dev/null ;;
    esac
  ")


  rm -f "$tmpfile"
  trap - EXIT INT

  if [[ -z "$msg" ]]; then
    echo "gc: failed to generate commit message" >&2
    return 1
  fi

  # Extract first non-empty, non-fence line (handles ```lang, ```, blank lines)
  msg=$(printf '%s\n' "$msg" | grep -v '^\s*```' | grep -v '^\s*$' | head -n 1 | xargs)

  if [[ -z "$msg" ]]; then
    echo "gc: model returned empty message after cleanup" >&2
    return 1
  fi

  echo "$msg"
  print -z "git commit -m ${(qq)msg}"
}