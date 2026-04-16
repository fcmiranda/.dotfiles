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

# _gc_load_ignore_patterns — load .sgcignore (repo-local) or ~/.sgcignore (global)
# Echoes a newline-separated list of glob patterns to exclude from AI analysis.
# Built-in defaults are always included (lock files, minified assets).
_gc_load_ignore_patterns() {
  local git_root patterns
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)

  # Built-in defaults
  patterns="*-lock.*
*.lock
*.min.js
*.min.css
*.map"

  # Repo-local .sgcignore overrides / extends
  if [[ -n "$git_root" && -f "${git_root}/.sgcignore" ]]; then
    patterns+=$'\n'"$(cat "${git_root}/.sgcignore")"
  elif [[ -f "${HOME}/.sgcignore" ]]; then
    # Global fallback
    patterns+=$'\n'"$(cat "${HOME}/.sgcignore")"
  fi

  printf '%s\n' "$patterns"
}

# _gc_filter_ignored_files PATTERNS_FILE — read filenames from stdin, print non-ignored ones
# Uses python3 fnmatch so patterns behave like .gitignore globs (basename + full path match).
_gc_filter_ignored_files() {
  local patterns_file="$1"
  python3 - "$patterns_file" << 'PYEOF'
import sys, fnmatch, os

patterns_file = sys.argv[1]
with open(patterns_file) as f:
    patterns = [l.strip() for l in f if l.strip() and not l.startswith('#')]

for line in sys.stdin:
    path = line.rstrip('\n')
    basename = os.path.basename(path)
    ignored = any(
        fnmatch.fnmatch(basename, p) or fnmatch.fnmatch(path, p)
        for p in patterns
    )
    if not ignored:
        print(path)
PYEOF
}

# _gc_filter_diff_by_ignore PATTERNS_FILE — filter a unified diff, dropping ignored files' hunks
_gc_filter_diff_by_ignore() {
  local patterns_file="$1"
  python3 - "$patterns_file" << 'PYEOF'
import sys, fnmatch, os, re

patterns_file = sys.argv[1]
with open(patterns_file) as f:
    patterns = [l.strip() for l in f if l.strip() and not l.startswith('#')]

def is_ignored(path):
    basename = os.path.basename(path)
    return any(fnmatch.fnmatch(basename, p) or fnmatch.fnmatch(path, p) for p in patterns)

skip = False
for line in sys.stdin:
    if line.startswith('diff --git '):
        m = re.match(r'^diff --git a/(.+) b/(.+)$', line.rstrip())
        skip = bool(m and is_ignored(m.group(2)))
    if not skip:
        sys.stdout.write(line)
PYEOF
}

# _gc_compress_diff — reduce diff token count while preserving AI signal
#
# What is stripped (zero/minimal impact on commit message quality):
#   - "index abc..def" lines          — git object hashes, useless to AI
#   - "old mode / new mode" lines     — file permission metadata
#   - Binary file notices             — replaced with a short note
#   - Unchanged context lines         — reduced from 3 to 1 per hunk
#
# What is preserved (critical for AI analysis):
#   - "--- a/file" / "+++ b/file"     — filenames drive scope detection
#   - All "+" / "-" lines             — the actual changes
#   - Hunk headers "@@ ... @@"        — structural context
#   - Truncation markers              — AI knows when diff was capped
#
# Large hunks (>80 changed lines) are capped and annotated so the AI
# knows content was omitted rather than seeing a silently incomplete diff.
_gc_compress_diff() {
  python3 << 'PYEOF'
import sys, re

MAX_CHANGED_LINES = 80  # per hunk before truncating

lines = sys.stdin.read().splitlines()
out = []
i = 0
while i < len(lines):
    line = lines[i]

    # Strip index / mode metadata
    if re.match(r'^index [0-9a-f]+\.\.[0-9a-f]+', line) or \
       re.match(r'^(old|new) mode ', line) or \
       re.match(r'^deleted file mode ', line) or \
       re.match(r'^new file mode ', line):
        i += 1
        continue

    # Collapse binary notices
    if re.match(r'^Binary files ', line):
        m = re.match(r'^Binary files (.+) and (.+) differ', line)
        if m:
            out.append(f'Binary file changed: {m.group(1)}')
        i += 1
        continue

    # At a hunk header — collect the hunk, strip extra context, cap if huge
    if line.startswith('@@'):
        out.append(line)
        i += 1
        hunk_changed = 0
        hunk_ctx_streak = 0
        truncated = False
        while i < len(lines) and not lines[i].startswith('@@') and \
              not lines[i].startswith('diff '):
            l = lines[i]
            if l.startswith('+') or l.startswith('-'):
                hunk_changed += 1
                hunk_ctx_streak = 0
                if hunk_changed > MAX_CHANGED_LINES:
                    truncated = True
                    i += 1
                    continue
                out.append(l)
            else:
                # context line — keep only 1 per streak to reduce noise
                hunk_ctx_streak += 1
                if hunk_ctx_streak <= 1 and not truncated:
                    out.append(l)
            i += 1
        if truncated:
            skipped = hunk_changed - MAX_CHANGED_LINES
            out.append(f' [... {skipped} lines truncated for brevity ...]')
        continue

    out.append(line)
    i += 1

print('\n'.join(out))
PYEOF
}

# gc — generate a conventional commit message from staged changes via AI
#
# Usage:
#   gc                          # uses default provider (opencode)
#   gc -p claude                # use claude CLI
#   gc -p crush                 # use crush CLI
#   gc -p copilot               # use gh copilot CLI
#   gc -m github-copilot/gpt-4o # override model (opencode only)
#   gc -g 3                     # generate 3 candidates to pick from
#   gc -l es                    # generate message in Spanish (ISO 639-1)
#
# Env overrides:
#   GC_PROVIDER=claude gc
#   GC_MODEL=github-copilot/gpt-5 gc
#
# Pre-fills the zsh readline buffer with: git commit -m "<message>"
gc() {
  local provider="${GC_PROVIDER:-opencode}"
  local model="${GC_MODEL:-github-copilot/gpt-4o}"
  local generate=1
  local lang=""

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--provider) provider="$2"; shift 2 ;;
      -m|--model)    model="$2";    shift 2 ;;
      -g|--generate) generate="$2"; shift 2 ;;
      -l|--lang)     lang="$2";     shift 2 ;;
      -h|--help)
        echo "Usage: gc [-p provider] [-m model] [-g N] [-l lang]"
        echo "  -g N      generate N candidate messages to pick from (default: 1)"
        echo "  -l LANG   output language ISO 639-1 code (e.g. es, fr, ja)"
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

  # Load ignore patterns and filter staged diff
  local ignore_tmpfile
  ignore_tmpfile=$(mktemp /tmp/gc-ignore.XXXXXX)
  _gc_load_ignore_patterns > "$ignore_tmpfile"

  local diff
  diff=$(git diff --staged | _gc_filter_diff_by_ignore "$ignore_tmpfile" | _gc_compress_diff)
  rm -f "$ignore_tmpfile"

  # Language instruction (injected into rules if --lang is set)
  local lang_rule=""
  if [[ -n "$lang" ]]; then
    lang_rule=$'\n'"- Write the commit message in the language with ISO 639-1 code: ${lang}"
  fi

  local prompt
  if [[ "$generate" -gt 1 ]]; then
    prompt="Analyze the following staged git diff and generate ${generate} distinct, concise conventional commit message candidates.

Rules:
- Use the conventional commits format: \`<type>(<optional scope>): <description>\`
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Keep each subject line under 72 characters
- Each candidate must be meaningfully different (vary type, scope, or emphasis)
- Output ONLY a valid JSON array of strings, no markdown fences, no explanation${lang_rule}

Example output: [\"feat(auth): add OAuth2 login\", \"feat: integrate OAuth2 provider\"]

Staged diff:
${diff}"
  else
    prompt="Analyze the following staged git diff and generate a concise, conventional commit message.

Rules:
- Use the conventional commits format: \`<type>(<optional scope>): <description>\`
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Keep the subject line under 72 characters
- If the changes are complex, add a short body after a blank line explaining the why
- Output ONLY the commit message, nothing else${lang_rule}

Staged diff:
${diff}"
  fi

  # Write to tempfile — avoids diff lines (e.g. '-m ...') being parsed as CLI flags
  local tmpfile
  tmpfile=$(mktemp /tmp/gc.XXXXXX)
  printf '%s' "$prompt" > "$tmpfile"
  trap "rm -f $tmpfile" EXIT INT

  # Generate message(s) with gum spinner
  local raw
  raw=$(gum spin --spinner dot --title "generating commit message via ${provider}..." -- sh -c "
    case '$provider' in
      opencode) opencode run --model '$model' -- \"\$(cat $tmpfile)\" 2>/dev/null ;;
      claude)   claude --print \"\$(cat $tmpfile)\" 2>/dev/null ;;
      crush)    crush \"\$(cat $tmpfile)\" 2>/dev/null ;;
      copilot)  gh copilot explain \"\$(cat $tmpfile)\" 2>/dev/null ;;
    esac
  ")

  rm -f "$tmpfile"
  trap - EXIT INT

  if [[ -z "$raw" ]]; then
    echo "gc: failed to generate commit message" >&2
    return 1
  fi

  local msg
  if [[ "$generate" -gt 1 ]]; then
    # Parse JSON array of candidates and let user pick one
    local candidates
    candidates=$(python3 -c "
import json, re, sys
raw = sys.stdin.read()
m = re.search(r'\[.*\]', raw, re.DOTALL)
if not m:
    sys.exit(1)
try:
    items = json.loads(m.group())
    for item in items:
        print(item)
except Exception:
    sys.exit(1)
" <<< "$raw" 2>/dev/null)

    if [[ -z "$candidates" ]]; then
      echo "gc: could not parse candidates from AI response" >&2
      echo "$raw" >&2
      return 1
    fi

    msg=$(printf '%s\n' "$candidates" \
      | gum choose \
          --header "Pick a commit message · Enter to confirm" \
          --cursor.foreground="212")

    if [[ -z "$msg" ]]; then
      echo "gc: no message selected — aborted" >&2
      return 1
    fi
  else
    # Extract first non-empty, non-fence line (handles ```lang, ```, blank lines)
    msg=$(printf '%s\n' "$raw" | grep -v '^\s*```' | grep -v '^\s*$' | head -n 1 | xargs)
  fi

  if [[ -z "$msg" ]]; then
    echo "gc: model returned empty message after cleanup" >&2
    return 1
  fi

  echo "$msg"
  print -z "git commit -m ${(qq)msg}"
}

# sgc — smart AI commit: analyzes ALL unstaged changes, groups them into
#        logical atomic commits, lets you pick which ones to run
#
# Usage:
#   sgc                          # uses default provider (opencode)
#   sgc -p claude                # use claude CLI
#   sgc -m github-copilot/gpt-4o # override model (opencode only)
#   sgc -l es                    # generate messages in Spanish (ISO 639-1)
#
# Env overrides:
#   GC_PROVIDER=claude sgc
#   GC_MODEL=github-copilot/gpt-5 sgc
sgc() {
  local provider="${GC_PROVIDER:-opencode}"
  local model="${GC_MODEL:-github-copilot/gpt-4o}"
  local lang=""

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--provider) provider="$2"; shift 2 ;;
      -m|--model)    model="$2";    shift 2 ;;
      -l|--lang)     lang="$2";     shift 2 ;;
      -h|--help)
        echo "Usage: sgc [-p provider] [-m model] [-l lang]"
        echo "  -l LANG   output language ISO 639-1 code (e.g. es, fr, ja)"
        echo "Providers: opencode (default), claude, crush, copilot"
        return 0 ;;
      *) echo "sgc: unknown option '$1'" >&2; return 1 ;;
    esac
  done

  # Collect unstaged/untracked files
  local status_output
  status_output=$(git status --short)
  if [[ -z "$status_output" ]]; then
    echo "sgc: nothing to commit — working tree clean" >&2
    return 1
  fi

  # Load ignore patterns into a temp file (reused across filter calls)
  local ignore_tmpfile
  ignore_tmpfile=$(mktemp /tmp/sgc-ignore.XXXXXX)
  _gc_load_ignore_patterns > "$ignore_tmpfile"

  # Build full context: unstaged diffs + untracked file contents (both filtered)
  local diff_content untracked_content
  diff_content=$(git diff 2>/dev/null | _gc_filter_diff_by_ignore "$ignore_tmpfile" | _gc_compress_diff)

  local untracked_files
  untracked_files=$(git ls-files --others --exclude-standard \
    | _gc_filter_ignored_files "$ignore_tmpfile")
  if [[ -n "$untracked_files" ]]; then
    while IFS= read -r f; do
      untracked_content+="=== NEW FILE: ${f} ===\n$(cat "$f" 2>/dev/null)\n\n"
    done <<< "$untracked_files"
  fi

  # Filtered status: remove ignored files from the status shown to AI
  local filtered_status
  filtered_status=$(git status --short \
    | awk '{print $NF}' \
    | _gc_filter_ignored_files "$ignore_tmpfile" \
    | while IFS= read -r f; do git status --short -- "$f" 2>/dev/null; done)
  [[ -z "$filtered_status" ]] && filtered_status="$status_output"

  rm -f "$ignore_tmpfile"

  # Language instruction
  local lang_rule=""
  if [[ -n "$lang" ]]; then
    lang_rule=$'\n'"- Write all commit messages in the language with ISO 639-1 code: ${lang}"
  fi

  # ── Cache: fingerprint the exact content the AI would analyse ──────────────
  local git_root cache_dir cache_hash_file cache_json_file current_hash
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sgc/$(echo "$git_root" | md5sum | cut -d' ' -f1)"
  cache_hash_file="${cache_dir}/last.hash"
  cache_json_file="${cache_dir}/last.json"

  current_hash=$(printf '%s\0%s\0%s\0%s' "$filtered_status" "$diff_content" "$untracked_content" "$lang" \
    | md5sum | cut -d' ' -f1)

  local json
  if [[ -f "$cache_hash_file" && -f "$cache_json_file" ]] \
      && [[ "$(cat "$cache_hash_file")" == "$current_hash" ]]; then
    gum style --faint "↩ using cached commit plan (no changes since last run)"
    json=$(cat "$cache_json_file")
  else
    local prompt="You are a git expert. Analyze the following unstaged and untracked changes and group them into logical, atomic conventional commits.

Git status:
${filtered_status}

Unstaged diffs:
${diff_content}

New untracked files:
${untracked_content}

Rules:
- Use conventional commits format: <type>(<optional scope>): <description>
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Group related files into the same commit — each commit must be atomic and focused
- A file must appear in exactly one commit
- Output ONLY a valid JSON array, no markdown fences, no explanation${lang_rule}

Output format:
[
  {\"message\": \"<conventional commit message>\", \"files\": [\"<relative/path>\"]},
  ...
]"

    local tmpfile
    tmpfile=$(mktemp /tmp/sgc.XXXXXX)
    printf '%s' "$prompt" > "$tmpfile"
    trap "rm -f $tmpfile" EXIT INT

    local raw
    raw=$(gum spin --spinner dot --title "analyzing changes via ${provider}..." -- sh -c "
      case '$provider' in
        opencode) opencode run --model '$model' -- \"\$(cat $tmpfile)\" 2>/dev/null ;;
        claude)   claude --print \"\$(cat $tmpfile)\" 2>/dev/null ;;
        crush)    crush \"\$(cat $tmpfile)\" 2>/dev/null ;;
        copilot)  gh copilot explain \"\$(cat $tmpfile)\" 2>/dev/null ;;
      esac
    ")

    rm -f "$tmpfile"
    trap - EXIT INT

    if [[ -z "$raw" ]]; then
      echo "sgc: failed to get response from AI" >&2
      return 1
    fi

    # Extract JSON array robustly (strip markdown fences if present)
    json=$(python3 -c "
import json, re, sys
raw = sys.stdin.read()
m = re.search(r'\[.*\]', raw, re.DOTALL)
if not m:
    sys.exit(1)
try:
    parsed = json.loads(m.group())
    print(json.dumps(parsed))
except Exception:
    sys.exit(1)
" <<< "$raw" 2>/dev/null)

    if [[ -z "$json" ]]; then
      echo "sgc: could not parse AI response as JSON" >&2
      echo "$raw" >&2
      return 1
    fi

    # Save to cache
    mkdir -p "$cache_dir"
    printf '%s' "$current_hash" > "$cache_hash_file"
    printf '%s' "$json"         > "$cache_json_file"
  fi

  local commit_count
  commit_count=$(python3 -c "import json,sys; print(len(json.loads(sys.stdin.read())))" <<< "$json")

  if [[ -z "$commit_count" || "$commit_count" -eq 0 ]]; then
    echo "sgc: AI returned no commits" >&2
    return 1
  fi

  # Build display lines: "feat(scope): msg  ← file1, file2"
  local display_lines=()
  local i msg files_str
  for (( i=0; i<commit_count; i++ )); do
    msg=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d[$i]['message'])" <<< "$json")
    files_str=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(', '.join(d[$i]['files']))" <<< "$json")
    display_lines+=("${msg}  ← ${files_str}")
  done

  # Build --selected flags to pre-check all options
  local selected_flags=()
  for line in "${display_lines[@]}"; do
    selected_flags+=(--selected "$line")
  done

  # Let user pick which commits to run (gum choose supports multi-select with space)
  local selected
  selected=$(printf '%s\n' "${display_lines[@]}" \
    | gum choose --no-limit \
        "${selected_flags[@]}" \
        --header "Space to select commits · Enter to confirm" \
        --cursor.foreground="212" \
        --selected.foreground="212")

  if [[ -z "$selected" ]]; then
    echo "sgc: no commits selected — aborted" >&2
    return 1
  fi

  # Execute each selected commit in order
  local created=0
  local accepted_indices=()
  for (( i=1; i<=commit_count; i++ )); do
    local line="${display_lines[$i]}"
    if ! echo "$selected" | grep -qF "$line"; then
      continue
    fi

    local idx=$(( i - 1 ))
    local cmsg cfiles
    cmsg=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); print(d[$idx]['message'])" <<< "$json")
    cfiles=$(python3 -c "import json,sys; d=json.loads(sys.stdin.read()); [print(f) for f in d[$idx]['files']]" <<< "$json")

    echo "$cfiles" | xargs git add
    git commit -m "$cmsg"
    (( created++ ))
    accepted_indices+=($idx)
  done

  echo ""
  gum style --foreground 212 --bold "✓ ${created} commit(s) created"

  # Update cache: keep remaining (unaccepted) commits so next sgc run reuses them
  local remaining_json
  remaining_json=$(python3 -c "
import json, sys
accepted = set(map(int, sys.argv[1:]))
data = json.loads(sys.stdin.read())
remaining = [d for i, d in enumerate(data) if i not in accepted]
print(json.dumps(remaining))
" "${accepted_indices[@]}" <<< "$json" 2>/dev/null)

  if [[ -n "$remaining_json" ]] && python3 -c "import json,sys; d=json.loads(sys.stdin.read()); sys.exit(0 if len(d)>0 else 1)" <<< "$remaining_json" 2>/dev/null; then
    # Recompute hash based on current working tree state (post-commit), with ignore filter
    local new_ignore_tmpfile new_status new_diff new_untracked new_hash
    new_ignore_tmpfile=$(mktemp /tmp/sgc-ignore.XXXXXX)
    _gc_load_ignore_patterns > "$new_ignore_tmpfile"

    new_status=$(git status --short \
      | awk '{print $NF}' \
      | _gc_filter_ignored_files "$new_ignore_tmpfile" \
      | while IFS= read -r f; do git status --short -- "$f" 2>/dev/null; done)
    new_diff=$(git diff 2>/dev/null | _gc_filter_diff_by_ignore "$new_ignore_tmpfile" | _gc_compress_diff)
    new_untracked=""
    local new_untracked_files
    new_untracked_files=$(git ls-files --others --exclude-standard \
      | _gc_filter_ignored_files "$new_ignore_tmpfile")
    if [[ -n "$new_untracked_files" ]]; then
      while IFS= read -r f; do
        new_untracked+="=== NEW FILE: ${f} ===\n$(cat "$f" 2>/dev/null)\n\n"
      done <<< "$new_untracked_files"
    fi
    rm -f "$new_ignore_tmpfile"

    new_hash=$(printf '%s\0%s\0%s\0%s' "$new_status" "$new_diff" "$new_untracked" "$lang" \
      | md5sum | cut -d' ' -f1)
    mkdir -p "$cache_dir"
    printf '%s' "$new_hash"       > "$cache_hash_file"
    printf '%s' "$remaining_json" > "$cache_json_file"
  else
    # All commits accepted — invalidate cache fully
    rm -f "$cache_hash_file" "$cache_json_file"
  fi
}