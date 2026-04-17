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
  local py_script
  py_script=$(mktemp /tmp/sgc-filter.XXXXXX.py)
  cat > "$py_script" << 'PYEOF'
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
  python3 "$py_script" "$patterns_file"
  rm -f "$py_script"
}

# _gc_filter_diff_by_ignore PATTERNS_FILE — filter a unified diff, dropping ignored files' hunks
_gc_filter_diff_by_ignore() {
  local patterns_file="$1"
  local py_script
  py_script=$(mktemp /tmp/sgc-filter.XXXXXX.py)
  cat > "$py_script" << 'PYEOF'
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
  python3 "$py_script" "$patterns_file"
  rm -f "$py_script"
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
  local py_script
  py_script=$(mktemp /tmp/gc-compress.XXXXXX.py)
  cat > "$py_script" << 'PYEOF'
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
  python3 "$py_script"
  rm -f "$py_script"
}

# _gc_load_commitlint_rules — parse commitlint config in the current repo root
#
# Searches for (in order):
#   .commitlintrc  .commitlintrc.json  .commitlintrc.yml  .commitlintrc.yaml
#   .commitlintrc.js  commitlint.config.js  commitlint.config.ts
#   commitlint.config.cjs  commitlint.config.mjs
#
# Extracts: type-enum, scope-enum, subject-max-length / header-max-length,
#           scope-case, subject-case rules and prints them as human-readable
#           constraint lines ready to append to the AI prompt.
#
# Outputs nothing (silently) when no config is found or no relevant rules exist.
_gc_load_commitlint_rules() {
  local git_root
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  [[ -z "$git_root" ]] && return

  python3 << PYEOF
import os, sys, json, re

root = "$git_root"

# ── 1. Locate config file ────────────────────────────────────────────────────
candidates = [
    ".commitlintrc",
    ".commitlintrc.json",
    ".commitlintrc.yml",
    ".commitlintrc.yaml",
    ".commitlintrc.js",
    ".commitlintrc.cjs",
    "commitlint.config.js",
    "commitlint.config.ts",
    "commitlint.config.cjs",
    "commitlint.config.mjs",
]
config_file = None
for c in candidates:
    p = os.path.join(root, c)
    if os.path.isfile(p):
        config_file = p
        break

# Also check package.json commitlint key
if config_file is None:
    pkg = os.path.join(root, "package.json")
    if os.path.isfile(pkg):
        try:
            with open(pkg) as f:
                pkg_data = json.load(f)
            if "commitlint" in pkg_data:
                config_file = pkg
        except Exception:
            pass

if config_file is None:
    sys.exit(0)

# ── 2. Parse config ──────────────────────────────────────────────────────────
rules = {}

def parse_json_or_yaml(text):
    # Try JSON first
    try:
        return json.loads(text)
    except Exception:
        pass
    # Minimal YAML: handle simple key: value and key: [list] structures
    # (avoids requiring PyYAML which may not be installed)
    try:
        import yaml
        return yaml.safe_load(text)
    except ImportError:
        pass
    # Hand-rolled fallback for common commitlintrc YAML patterns
    data = {}
    current_key = None
    list_items = []
    in_list = False
    for line in text.splitlines():
        stripped = line.strip()
        if not stripped or stripped.startswith("#"):
            continue
        if stripped.startswith("- ") and in_list:
            list_items.append(stripped[2:].strip().strip("'\""))
            continue
        if ":" in stripped:
            if in_list and current_key:
                data[current_key] = list_items
            in_list = False
            k, _, v = stripped.partition(":")
            k = k.strip()
            v = v.strip()
            if v == "":
                current_key = k
                list_items = []
                in_list = True
            else:
                data[k] = v
    if in_list and current_key:
        data[current_key] = list_items
    return data

ext = os.path.splitext(config_file)[1].lower()
with open(config_file) as f:
    raw = f.read()

config_data = {}
if config_file.endswith("package.json"):
    try:
        config_data = json.loads(raw).get("commitlint", {})
    except Exception:
        pass
elif ext in (".json", "") :
    config_data = parse_json_or_yaml(raw)
elif ext in (".yml", ".yaml"):
    config_data = parse_json_or_yaml(raw)
elif ext in (".js", ".ts", ".cjs", ".mjs"):
    # Extract rules object from JS/TS with regex — handles:
    #   module.exports = { rules: { ... } }
    #   export default { rules: { ... } }
    # We find the "rules" key and try to parse the JSON-like value
    m = re.search(r'rules\s*:\s*(\{[^}]+\})', raw, re.DOTALL)
    if m:
        # Normalise JS object to JSON: quote unquoted keys, fix trailing commas
        js_obj = m.group(1)
        js_obj = re.sub(r'(\w[\w-]*)\s*:', r'"\1":', js_obj)       # quote keys
        js_obj = re.sub(r',\s*\}', '}', js_obj)                     # trailing comma
        js_obj = re.sub(r',\s*\]', ']', js_obj)
        try:
            config_data = {"rules": json.loads(js_obj)}
        except Exception:
            pass

rules = config_data.get("rules", {})
if not rules:
    sys.exit(0)

# ── 3. Extract relevant constraints ─────────────────────────────────────────
# Rule format: [level, 'always'|'never', value]   (level 2 = error, 1 = warn)
lines = []

def rule_val(r):
    """Return (active, value) from a commitlint rule tuple/list."""
    if not isinstance(r, (list, tuple)) or len(r) < 1:
        return False, None
    level = r[0] if len(r) >= 1 else 0
    condition = r[1] if len(r) >= 2 else "always"
    value = r[2] if len(r) >= 3 else None
    if level == 0:
        return False, None
    return True, (value, condition)

# type-enum
active, val = rule_val(rules.get("type-enum", []))
if active and val and isinstance(val[0], list):
    condition = val[1]
    types = val[0]
    if condition == "always":
        lines.append(f"- Valid commit types (enforced by commitlint): {', '.join(types)}")
    elif condition == "never":
        lines.append(f"- Forbidden commit types (enforced by commitlint): {', '.join(types)}")

# scope-enum
active, val = rule_val(rules.get("scope-enum", []))
if active and val and isinstance(val[0], list) and val[0]:
    condition = val[1]
    scopes = val[0]
    if condition == "always":
        lines.append(f"- Valid scopes (enforced by commitlint): {', '.join(scopes)}")

# subject / header max length
for rule_name in ("header-max-length", "subject-max-length"):
    active, val = rule_val(rules.get(rule_name, []))
    if active and val and isinstance(val[0], int):
        lines.append(f"- Keep the subject line under {val[0]} characters (enforced by commitlint)")
        break  # one is enough

# subject-case
active, val = rule_val(rules.get("subject-case", []))
if active and val:
    cases, condition = val
    if condition == "always":
        c = cases if isinstance(cases, str) else (cases[0] if cases else None)
        if c:
            lines.append(f"- Subject must be {c} case (enforced by commitlint)")
    elif condition == "never":
        cs = cases if isinstance(cases, list) else [cases]
        lines.append(f"- Subject must NOT be {', '.join(cs)} case (enforced by commitlint)")

# scope-case
active, val = rule_val(rules.get("scope-case", []))
if active and val:
    cases, condition = val
    if condition == "always":
        c = cases if isinstance(cases, str) else (cases[0] if cases else None)
        if c:
            lines.append(f"- Scope must be {c} case (enforced by commitlint)")

if lines:
    print("\n# Commitlint constraints (from project config — you MUST follow these):")
    for l in lines:
        print(l)
PYEOF
}

# _gc_hook_script — emit the prepare-commit-msg hook body
# The hook only fires when the commit message file is empty and it's not a
# merge/squash/fixup commit — same guard opencommit uses.
_gc_hook_script() {
  cat << 'HOOKEOF'
#!/usr/bin/env bash
# gc-managed: prepare-commit-msg hook
# Automatically generates a commit message via gc when no message is provided.
# Remove this hook with: gc hook uninstall

COMMIT_MSG_FILE="$1"
COMMIT_SOURCE="$2"   # message | template | merge | squash | commit (amend)

# Only run when the user hasn't supplied a message and it's not a special commit
if [[ -n "$COMMIT_SOURCE" ]]; then
  exit 0
fi

# Skip if the file already has a non-comment line (e.g. -t template)
if grep -qE '^[^#]' "$COMMIT_MSG_FILE" 2>/dev/null; then
  exit 0
fi

# Require staged changes
if git diff --staged --quiet; then
  exit 0
fi

# Load zsh environment so gc and its helpers are available
if [[ -f "${HOME}/.zshrc" ]]; then
  # Run gc in a zsh subshell; capture the generated message
  msg=$(zsh -i -c 'source ~/.zshrc 2>/dev/null; gc' 2>/dev/null \
    | grep -v '^$' | tail -n 1)
fi

if [[ -n "$msg" ]]; then
  # Prepend the generated message (keep existing comments below)
  existing=$(cat "$COMMIT_MSG_FILE")
  printf '%s\n\n%s\n' "$msg" "$existing" > "$COMMIT_MSG_FILE"
fi
HOOKEOF
}

# gc hook — manage the prepare-commit-msg hook in the current repo
#
# Usage:
#   gc hook install    # install hook into .git/hooks/prepare-commit-msg
#   gc hook uninstall  # remove the gc-managed hook
#   gc hook status     # show whether the hook is installed
_gc_hook() {
  local subcmd="$1"
  local git_root hook_file
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  if [[ -z "$git_root" ]]; then
    echo "gc hook: not inside a git repository" >&2
    return 1
  fi
  hook_file="${git_root}/.git/hooks/prepare-commit-msg"

  case "$subcmd" in
    install)
      if [[ -f "$hook_file" ]] && grep -q "gc-managed" "$hook_file" 2>/dev/null; then
        echo "gc hook: already installed in this repository"
        return 0
      fi
      if [[ -f "$hook_file" ]]; then
        echo "gc hook: a prepare-commit-msg hook already exists — appending gc block"
        printf '\n' >> "$hook_file"
      fi
      _gc_hook_script >> "$hook_file"
      chmod +x "$hook_file"
      echo "gc hook: installed → ${hook_file}"
      ;;
    uninstall)
      if [[ ! -f "$hook_file" ]]; then
        echo "gc hook: no hook file found"
        return 0
      fi
      if ! grep -q "gc-managed" "$hook_file" 2>/dev/null; then
        echo "gc hook: hook file exists but was not installed by gc — not touching it"
        return 1
      fi
      # Remove everything from the gc-managed marker onwards
      python3 - "$hook_file" << 'PYEOF'
import sys
path = sys.argv[1]
with open(path) as f:
    lines = f.readlines()
# Find the gc-managed marker line
marker = next((i for i, l in enumerate(lines) if "gc-managed" in l), None)
if marker is None:
    sys.exit(0)
# Keep everything before the marker (strip trailing blank lines)
kept = lines[:marker]
while kept and kept[-1].strip() == "":
    kept.pop()
if kept:
    with open(path, "w") as f:
        f.writelines(kept)
        f.write("\n")
else:
    import os
    os.remove(path)
PYEOF
      echo "gc hook: uninstalled from ${hook_file}"
      ;;
    status)
      if [[ -f "$hook_file" ]] && grep -q "gc-managed" "$hook_file" 2>/dev/null; then
        echo "gc hook: installed → ${hook_file}"
      else
        echo "gc hook: not installed (run: gc hook install)"
      fi
      ;;
    *)
      echo "Usage: gc hook <install|uninstall|status>" >&2
      return 1
      ;;
  esac
}

# _gc_emoji_rule — returns the gitmoji instruction line to inject into prompts
# Each conventional commit type maps to one canonical emoji.
_gc_emoji_rule() {
  cat << 'EOF'

# Gitmoji (prepend ONE emoji to the subject, before the type):
# feat       → ✨   fix        → 🐛   refactor   → ♻️
# perf       → ⚡️   docs       → 📝   style      → 🎨
# test       → 🧪   chore      → 🔧   ci         → 👷
# build      → 📦   revert     → ⏪️   security   → 🔒️
- Prepend exactly one gitmoji emoji to the subject line, matching the commit type (see map above)
- Format: <emoji> <type>(<scope>): <description>   e.g. ✨ feat(gc): add emoji support
EOF
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
#   gc -e                       # prefix message with a gitmoji emoji
#   gc hook install             # install prepare-commit-msg hook in current repo
#   gc hook uninstall           # remove the gc-managed hook
#   gc hook status              # show hook installation status
#
# Env overrides:
#   GC_PROVIDER=claude gc
#   GC_MODEL=github-copilot/gpt-5 gc
#   GC_EMOJI=1 gc
#
# Pre-fills the zsh readline buffer with: git commit -m "<message>"
gc() {
  # Delegate hook subcommand
  if [[ "$1" == "hook" ]]; then
    shift
    _gc_hook "$@"
    return $?
  fi

  local provider="${GC_PROVIDER:-opencode}"
  local model="${GC_MODEL:-github-copilot/gpt-4o}"
  local generate=1
  local lang=""
  local emoji="${GC_EMOJI:-0}"
  local debug=0

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--provider) provider="$2"; shift 2 ;;
      -m|--model)    model="$2";    shift 2 ;;
      -g|--generate) generate="$2"; shift 2 ;;
      -l|--lang)     lang="$2";     shift 2 ;;
      -e|--emoji)    emoji=1;       shift ;;
      -d|--debug)    debug=1;       shift ;;
      -h|--help)
        echo "Usage: gc [-p provider] [-m model] [-g N] [-l lang] [-e] [-d]"
        echo "       gc hook <install|uninstall|status>"
        echo "  -g N      generate N candidate messages to pick from (default: 1)"
        echo "  -l LANG   output language ISO 639-1 code (e.g. es, fr, ja)"
        echo "  -e        prefix commit message with a gitmoji emoji"
        echo "  -d        debug mode: show prompt, command and raw AI output"
        echo "Providers: opencode (default), claude, crush, copilot"
        return 0 ;;
      *) echo "gc: unknown option '$1'" >&2; return 1 ;;
    esac
  done

  # Always stage all changes first
  local has_changes
  has_changes=$(git status --short)
  if [[ -z "$has_changes" ]]; then
    gum style --faint "gc: nothing to commit — working tree clean"
    return 1
  fi

  git add --all
  gum style --faint "staged all changes (git add --all)"

  # Load ignore patterns and filter staged diff
  local ignore_tmpfile
  ignore_tmpfile=$(mktemp /tmp/gc-ignore.XXXXXX)
  _gc_load_ignore_patterns > "$ignore_tmpfile"

  local diff
  diff=$(git diff --staged | _gc_filter_diff_by_ignore "$ignore_tmpfile" | _gc_compress_diff)
  rm -f "$ignore_tmpfile"

  # Commitlint constraints (empty string if no config found)
  local commitlint_rules
  commitlint_rules=$(_gc_load_commitlint_rules)

  # Language instruction (injected into rules if --lang is set)
  local lang_rule=""
  if [[ -n "$lang" ]]; then
    lang_rule=$'\n'"- Write the commit message in the language with ISO 639-1 code: ${lang}"
  fi

  # Emoji instruction
  local emoji_rule=""
  [[ "$emoji" == "1" ]] && emoji_rule=$(_gc_emoji_rule)

  local prompt
  if [[ "$generate" -gt 1 ]]; then
    prompt="Analyze the following staged git diff and generate ${generate} distinct, concise conventional commit message candidates.

Rules:
- Use the conventional commits format: \`<type>(<optional scope>): <description>\`
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Keep each subject line under 72 characters
- Each candidate must be meaningfully different (vary type, scope, or emphasis)
- Output ONLY a valid JSON array of strings, no markdown fences, no explanation${lang_rule}
${emoji_rule}
${commitlint_rules}
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
${emoji_rule}
${commitlint_rules}
Staged diff:
${diff}"
  fi

  # Write to tempfile — avoids diff lines (e.g. '-m ...') being parsed as CLI flags
  local tmpfile
  tmpfile=$(mktemp /tmp/gc.XXXXXX)
  printf '%s' "$prompt" > "$tmpfile"
  trap "rm -f $tmpfile" EXIT INT

  # Generate message(s)
  local raw
  if [[ "$debug" == "1" ]]; then
    local prompt_bytes
    prompt_bytes=$(wc -c < "$tmpfile" | tr -d ' ')
    gum style --faint "debug: provider=$provider model=$model"
    gum style --faint "debug: prompt written to $tmpfile ($prompt_bytes bytes)"
    gum style --faint "debug: diff length=${#diff}"
    echo "--- git diff --staged (raw, first 20 lines) ---"
    git diff --staged | head -20
    echo "--- after _gc_filter_diff_by_ignore (first 20 lines) ---"
    local dbg_ignore_tmp
    dbg_ignore_tmp=$(mktemp /tmp/gc-ignore.XXXXXX)
    _gc_load_ignore_patterns > "$dbg_ignore_tmp"
    git diff --staged | _gc_filter_diff_by_ignore "$dbg_ignore_tmp" | head -20
    rm -f "$dbg_ignore_tmp"
    echo "--- after _gc_compress_diff (first 20 lines) ---"
    echo "$diff" | head -20
    echo "--- prompt preview (first 500 chars) ---"
    head -c 500 "$tmpfile"
    echo ""
    echo "--- running opencode (raw output) ---"
    case "$provider" in
      opencode) raw=$(opencode run --model "$model" -- "$prompt") ;;
      claude)   raw=$(claude --print "$prompt") ;;
      crush)    raw=$(crush "$prompt") ;;
      copilot)  raw=$(gh copilot explain "$prompt") ;;
    esac
    echo "--- raw output ---"
    echo "$raw"
    echo "--- end ---"
  else
    raw=$(gum spin --spinner dot --title "generating commit message via ${provider}..." -- sh -c '
      case "$1" in
        opencode) opencode run --model "$2" -- "$3" 2>/dev/null ;;
        claude)   claude --print "$3" 2>/dev/null ;;
        crush)    crush "$3" 2>/dev/null ;;
        copilot)  gh copilot explain "$3" 2>/dev/null ;;
      esac
    ' _ "$provider" "$model" "$(< $tmpfile)")
  fi

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

# _sgc_preview_cmd — fzf --preview helper for sgc --preview
#   Usage: _sgc_preview_cmd <json_tmpfile> <0-based-index>
#   Prints file summary + bat-rendered diff for the commit at <index>
_sgc_preview_cmd() {
  local json_file="$1" idx="$2"
  local files
  files=$(python3 - "$json_file" "$idx" <<'PYEOF'
import json, sys
data = json.loads(open(sys.argv[1]).read())
idx = int(sys.argv[2])
for f in data[idx]['files']:
    print(f)
PYEOF
)
  if [[ -z "$files" ]]; then
    echo "(no files)"
    return
  fi

  # Print file list header
  local file_list
  file_list=$(echo "$files" | tr '\n' ' ')
  printf '\033[1;34m● %s\033[0m\n' "${file_list% }"
  printf '%.0s─' {1..60}; echo

  # Show diff for these files via bat
  local diff_output
  diff_output=$(git diff -- ${(f)files} 2>/dev/null)
  if [[ -n "$diff_output" ]]; then
    echo "$diff_output" | bat --language=diff --style=grid --color=always --paging=never 2>/dev/null \
      || echo "$diff_output"
  else
    # Untracked / new files: show full content
    echo "$files" | while IFS= read -r f; do
      [[ -f "$f" ]] || continue
      printf '\033[2m(new file)\033[0m %s\n' "$f"
      bat --style=grid --color=always --paging=never "$f" 2>/dev/null || cat "$f"
    done
  fi
}

# sgc — smart AI commit: analyzes ALL unstaged changes, groups them into
#        logical atomic commits, lets you pick which ones to run
#
# Usage:
#   sgc                          # uses default provider (opencode)
#   sgc -p claude                # use claude CLI
#   sgc -m github-copilot/gpt-4o # override model (opencode only)
#   sgc -l es                    # generate messages in Spanish (ISO 639-1)
#   sgc -e                       # prefix messages with gitmoji emojis
#   sgc --preview                # fzf interactive diff preview before committing
#
# Env overrides:
#   GC_PROVIDER=claude sgc
#   GC_MODEL=github-copilot/gpt-5 sgc
#   GC_EMOJI=1 sgc
sgc() {
  local provider="${GC_PROVIDER:-opencode}"
  local model="${GC_MODEL:-github-copilot/gpt-4o}"
  local lang=""
  local emoji="${GC_EMOJI:-0}"
  local debug=0
  local force=0
  local preview=0

  # Parse flags
  while [[ $# -gt 0 ]]; do
    case "$1" in
      -p|--provider) provider="$2"; shift 2 ;;
      -m|--model)    model="$2";    shift 2 ;;
      -l|--lang)     lang="$2";     shift 2 ;;
      -e|--emoji)    emoji=1;       shift ;;
      -d|--debug)    debug=1;       shift ;;
      -f|--force)    force=1;       shift ;;
      --preview)     preview=1;     shift ;;
      -h|--help)
        echo "Usage: sgc [-p provider] [-m model] [-l lang] [-e] [-d] [-f] [--preview]"
        echo "  -l LANG    output language ISO 639-1 code (e.g. es, fr, ja)"
        echo "  -e         prefix commit messages with gitmoji emojis"
        echo "  -d         debug mode: show prompt and raw AI output"
        echo "  -f         force: skip cache and re-analyze changes"
        echo "  --preview  interactive fzf diff preview before committing"
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

  # Commitlint constraints (empty string if no config found)
  local commitlint_rules
  commitlint_rules=$(_gc_load_commitlint_rules)

  # Language instruction
  local lang_rule=""
  if [[ -n "$lang" ]]; then
    lang_rule=$'\n'"- Write all commit messages in the language with ISO 639-1 code: ${lang}"
  fi

  # Emoji instruction
  local emoji_rule=""
  [[ "$emoji" == "1" ]] && emoji_rule=$(_gc_emoji_rule)

  # ── Cache: fingerprint the exact content the AI would analyse ──────────────
  local git_root cache_dir cache_hash_file cache_json_file current_hash
  git_root=$(git rev-parse --show-toplevel 2>/dev/null)
  cache_dir="${XDG_CACHE_HOME:-$HOME/.cache}/sgc/$(echo "$git_root" | md5sum | cut -d' ' -f1)"
  cache_hash_file="${cache_dir}/last.hash"
  cache_json_file="${cache_dir}/last.json"

  current_hash=$(printf '%s\0%s\0%s\0%s\0%s\0%s' "$filtered_status" "$diff_content" "$untracked_content" "$lang" "$commitlint_rules" "$emoji" \
    | md5sum | cut -d' ' -f1)

  local stored_hash=""
  [[ -f "$cache_hash_file" ]] && stored_hash=$(cat "$cache_hash_file")
  local json=""
  if [[ "$force" == "0" ]] \
      && [[ -f "$cache_hash_file" && -f "$cache_json_file" ]] \
      && [[ "$stored_hash" == "$current_hash" ]]; then
    gum style --faint "↩ using cached commit plan (no changes since last run) — use -f to force re-analyze"
    json=$(cat "$cache_json_file")
  else
    local prompt
    prompt=$(cat <<EOF
You are a git expert. Analyze the following unstaged and untracked changes and group them into logical, atomic conventional commits.

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
- A file must appear in exactly one commit${lang_rule}
${emoji_rule}
${commitlint_rules}
CRITICAL OUTPUT RULES — follow exactly:
- Output ONLY a raw JSON array. Nothing else. No explanation, no markdown, no code fences.
- Use real double-quote characters in the JSON — do NOT backslash-escape them.
- Every object must have exactly two keys: "message" (string) and "files" (array of strings).

Required output format (copy this structure exactly):
[
  {"message": "feat(scope): description", "files": ["path/to/file.ext"]},
  {"message": "fix: another change", "files": ["other/file.ts", "another.ts"]}
]
EOF
)

    local tmpfile
    tmpfile=$(mktemp /tmp/sgc.XXXXXX)

    # Robust JSON parser/validator — written to a temp file to avoid heredoc stdin conflict
    local parser_script
    parser_script=$(mktemp /tmp/sgc-parser.XXXXXX.py)
    cat > "$parser_script" << 'PYEOF'
import json, re, sys

def try_parse(text):
    text = text.strip()
    # Strip markdown fences
    text = re.sub(r'^```(?:json)?\s*\n?', '', text, flags=re.MULTILINE)
    text = re.sub(r'\n?```\s*$', '', text, flags=re.MULTILINE)
    text = text.strip()
    # Find outermost JSON array
    m = re.search(r'\[.*\]', text, re.DOTALL)
    if not m:
        return None
    candidate = m.group()
    parsed = None
    for attempt in [candidate, candidate.replace('\\"', '"')]:
        try:
            parsed = json.loads(attempt)
            break
        except json.JSONDecodeError:
            continue
    if parsed is None:
        return None
    # Validate structure
    if not isinstance(parsed, list) or not parsed:
        return None
    for item in parsed:
        if not isinstance(item, dict):
            return None
        if not isinstance(item.get('message'), str) or not item['message'].strip():
            return None
        if not isinstance(item.get('files'), list) or not item['files']:
            return None
        if not all(isinstance(f, str) and f.strip() for f in item['files']):
            return None
    print(json.dumps(parsed))
    return True

if not try_parse(sys.stdin.read()):
    sys.exit(1)
PYEOF
    trap "rm -f $tmpfile $parser_script" EXIT INT

    local raw="" attempt_num=0 max_attempts=3
    local active_prompt="$prompt"

    while [[ $attempt_num -lt $max_attempts ]]; do
      attempt_num=$((attempt_num + 1))
      printf '%s' "$active_prompt" > "$tmpfile"

      if [[ "$debug" == "1" ]]; then
        gum style --faint "debug: attempt $attempt_num/$max_attempts — provider=$provider model=$model prompt=$(wc -c < $tmpfile | tr -d ' ') bytes"
        [[ $attempt_num -eq 1 ]] && { echo "--- prompt preview (first 500 chars) ---"; head -c 500 "$tmpfile"; echo ""; }
        echo "--- running $provider ---"
        case "$provider" in
          opencode) raw=$(opencode run --model "$model" -- "$active_prompt") ;;
          claude)   raw=$(claude --print "$active_prompt") ;;
          crush)    raw=$(crush "$active_prompt") ;;
          copilot)  raw=$(gh copilot explain "$active_prompt") ;;
        esac
        echo "--- raw output ---"; echo "$raw"; echo "---"
      else
        raw=$(gum spin --spinner dot --title "analyzing changes via ${provider}… (attempt ${attempt_num}/${max_attempts})" -- sh -c '
          case "$1" in
            opencode) opencode run --model "$2" -- "$3" 2>/dev/null ;;
            claude)   claude --print "$3" 2>/dev/null ;;
            crush)    crush "$3" 2>/dev/null ;;
            copilot)  gh copilot explain "$3" 2>/dev/null ;;
          esac
        ' _ "$provider" "$model" "$(< $tmpfile)")
      fi

      if [[ -z "$raw" ]]; then
        gum style --faint "sgc: no response from AI (attempt ${attempt_num}/${max_attempts})"
        [[ $attempt_num -lt $max_attempts ]] && continue || break
      fi

      json=$(python3 "$parser_script" <<< "$raw" 2>/dev/null)
      if [[ -n "$json" ]]; then
        break
      fi

      gum style --faint "sgc: response was not valid JSON — retrying (attempt ${attempt_num}/${max_attempts})…"
      # Correction prompt: send bad response back with explicit fix instructions
      active_prompt="Your previous response could not be parsed as valid JSON.

Your previous response was:
${raw}

CRITICAL: Fix it. Output ONLY a raw JSON array using real double-quote characters (\"). No markdown, no fences, no explanation, no escaped quotes.

Required format:
[
  {\"message\": \"type(scope): description\", \"files\": [\"path/to/file\"]}
]

Original task:
${prompt}"
    done

    rm -f "$tmpfile" "$parser_script"
    trap - EXIT INT

    if [[ -z "$json" ]]; then
      echo "sgc: failed to get valid JSON from AI after ${max_attempts} attempts" >&2
      [[ -n "$raw" ]] && echo "$raw" >&2
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

  # Let user pick which commits to run
  local selected
  if [[ "$preview" == "1" ]]; then
    # fzf with bat diff preview
    local json_preview_tmp
    json_preview_tmp=$(mktemp /tmp/sgc-preview.XXXXXX.json)
    printf '%s' "$json" > "$json_preview_tmp"
    trap "rm -f $json_preview_tmp" EXIT INT

    selected=$(printf '%s\n' "${display_lines[@]}" \
      | fzf --ansi --no-sort --multi \
            --prompt '  commit · ' --pointer '→' --marker '✓' \
            --preview "_sgc_preview_cmd '$json_preview_tmp' {n}" \
            --preview-window 'right:62%:wrap' \
            --bind 'ctrl-/:toggle-preview-focus' \
            --bind 'ctrl-u:preview-half-page-up' \
            --bind 'ctrl-d:preview-half-page-down' \
            --bind 'ctrl-a:select-all' \
            --header 'tab·select  ctrl-a·all  ctrl-/·focus  ctrl-d/u·scroll  enter·confirm')

    rm -f "$json_preview_tmp"
    trap - EXIT INT
  else
    # Build --selected flags to pre-check all options
    local selected_flags=()
    for line in "${display_lines[@]}"; do
      selected_flags+=(--selected "$line")
    done

    # gum choose (default): multi-select with space
    selected=$(printf '%s\n' "${display_lines[@]}" \
      | gum choose --no-limit \
          "${selected_flags[@]}" \
          --header "Space to select commits · Enter to confirm" \
          --cursor.foreground="212" \
          --selected.foreground="212")
  fi

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

    new_hash=$(printf '%s\0%s\0%s\0%s\0%s\0%s' "$new_status" "$new_diff" "$new_untracked" "$lang" "$commitlint_rules" "$emoji" \
      | md5sum | cut -d' ' -f1)
    mkdir -p "$cache_dir"
    printf '%s' "$new_hash"       > "$cache_hash_file"
    printf '%s' "$remaining_json" > "$cache_json_file"
  else
    # All commits accepted — invalidate cache fully
    rm -f "$cache_hash_file" "$cache_json_file"
  fi
}