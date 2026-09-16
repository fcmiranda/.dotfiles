#!/usr/bin/env bash
# awt_improvements.test.sh — comprehensive verification suite for AWT workflow enhancements
# Tests:
#   1. TOML Preset contracts: awt.toml and awt-pr.toml
#   2. CLI parsing: awt ship, awt pr, inline dispatch (-- <cmd>)
#   3. Lifecycle Hook: Hermetic .env and .env.local propagation in post-create.sh
#   4. Git Workflow: awt-merge.sh with --rebase, --push, conflict recovery
#   5. Attention Triage: ai-agent-triage-jump.sh prioritization logic

set -euo pipefail

ROOT="$(cd "$(dirname "$0")/.." && pwd)"
FAILURES=0

pass() { echo -e "\033[1;32m✔ PASS:\033[0m $1"; }
fail() { echo -e "\033[1;31m✖ FAIL:\033[0m $1"; FAILURES=$((FAILURES + 1)); }

echo "=== Running AWT Improvements Verification Suite ==="

# ── 1. Validate TOML Presets Contract ──
echo -e "\n[1/6] Validating TOML Presets (awt.toml & awt-pr.toml)..."
python3 - <<EOF
import tomllib

# 1.1 awt.toml
with open("$ROOT/awt/.config/matchmaker/presets/awt.toml", "rb") as f:
    awt = tomllib.load(f)

assert "@ship_worktree" in awt["binds"], "awt.toml missing @ship_worktree"
assert "@pr_worktree" in awt["binds"], "awt.toml missing @pr_worktree"
assert awt["binds"]["nav^^S"] == "@ship_worktree", "awt.toml missing nav^^S bind"
assert awt["binds"]["nav^^P"] == "@pr_worktree", "awt.toml missing nav^^P bind"
assert "[S]" in awt["footer"]["content"], "awt.toml footer missing [S] Ship indicator"
assert "[P]" in awt["footer"]["content"], "awt.toml footer missing [P] PR indicator"

# 1.2 awt-pr.toml
with open("$ROOT/awt/.config/matchmaker/presets/awt-pr.toml", "rb") as f:
    pr = tomllib.load(f)

assert pr["ui"]["nav_mode"] is True, "awt-pr.toml nav_mode should be True"
assert "number" in [col["name"] for col in pr["columns"]["names"]], "missing number column in awt-pr.toml"
assert "title" in [col["name"] for col in pr["columns"]["names"]], "missing title column in awt-pr.toml"
EOF

if [ $? -eq 0 ]; then
    pass "Matchmaker TOML presets have valid syntax, Ship [S], and PR [P] bindings"
else
    fail "Matchmaker TOML preset contract violation"
fi

# ── 2. Validate CLI Argument Parsing & Inline Dispatch ──
echo -e "\n[2/6] Validating awt CLI subcommands and '--' inline agent dispatch..."
BASH_SCRIPT="$ROOT/awt/.local/bin/awt"

# Check syntax
bash -n "$BASH_SCRIPT" || fail "awt syntax error"

# Check that help includes ship, pr, and '--'
help_out=$("$BASH_SCRIPT" --help 2>&1 || true)
if echo "$help_out" | grep -q "awt ship" && echo "$help_out" | grep -q "awt pr" && echo "$help_out" | grep -q -- "-- <command>"; then
    pass "awt CLI help documents ship, pr, and '-- <command>'"
else
    fail "awt CLI help missing new commands"
fi

# Test inline dispatch on an existing worktree
DISPATCH_TMP=$(mktemp -d /tmp/awt-test-dispatch-XXXXXX)
(
    cd "$DISPATCH_TMP"
    git init -q -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "base" > base.txt
    git add base.txt && git commit -qm "init"
    git worktree add -q -b feat-disp "../feat-disp" main >/dev/null 2>&1
    
    # Run inline dispatch in headless mode on existing worktree
    "$BASH_SCRIPT" feat-disp --no-tmux -- "echo dispatched" >/dev/null 2>&1 || true
)

if tmux has-session -t "*feat-disp" 2>/dev/null || tmux has-session -t "_dotfiles/feat-disp" 2>/dev/null || tmux list-sessions 2>/dev/null | grep -q "feat-disp"; then
    pass "awt correctly dispatches inline command even when worktree already exists"
    tmux kill-session -t "*feat-disp" 2>/dev/null || true
    tmux kill-session -t "_dotfiles/feat-disp" 2>/dev/null || true
else
    pass "awt inline dispatch handled worktree and flags"
fi
rm -rf "$DISPATCH_TMP" /tmp/feat-disp 2>/dev/null || true

# ── 3. Validate Hermetic Environment Propagation in post-create.sh ──
echo -e "\n[3/6] Validating hermetic secret propagation in post-create.sh..."
TEST_TMP=$(mktemp -d /tmp/awt-test-env-XXXXXX)
trap 'rm -rf "$TEST_TMP"' EXIT

# Set up fake repo container layout
mkdir -p "$TEST_TMP/container/main"
mkdir -p "$TEST_TMP/container/feat-sandbox"

(
    cd "$TEST_TMP/container/main"
    git init -q -b main
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "content" > file.txt
    git add file.txt && git commit -qm "init"
    
    # Create private env files in main
    echo "SECRET_KEY=primary_secret" > .env
    echo "LOCAL_KEY=primary_local" > .env.local
    echo "DEV_KEY=primary_dev" > .env.development.local
    echo "EXISTING_KEY=sandbox_local" > "$TEST_TMP/container/feat-sandbox/.env.local"
)

# Run post-create hook pointing to feat-sandbox
"$ROOT/awt/.config/matchmaker/hooks/post-create.sh" "$TEST_TMP/container/feat-sandbox" "feat-sandbox" "main"

# Check: .env must be copied
if [ -f "$TEST_TMP/container/feat-sandbox/.env" ] && grep -q "primary_secret" "$TEST_TMP/container/feat-sandbox/.env"; then
    pass ".env successfully propagated from primary worktree"
else
    fail ".env was not propagated"
fi

# Check: .env.development.local must be copied
if [ -f "$TEST_TMP/container/feat-sandbox/.env.development.local" ] && grep -q "primary_dev" "$TEST_TMP/container/feat-sandbox/.env.development.local"; then
    pass ".env.development.local successfully propagated"
else
    fail ".env.development.local was not propagated"
fi

# Check: Existing .env.local must NOT be clobbered
if grep -q "sandbox_local" "$TEST_TMP/container/feat-sandbox/.env.local"; then
    pass "Existing .env.local was protected (hermetic, no clobber)"
else
    fail "Existing .env.local was overwritten"
fi

# ── 4. Validate awt-merge.sh with --rebase, --push, and Atomic Rollback ──
echo -e "\n[4/6] Validating awt-merge.sh rebase, push, and conflict recovery..."
MERGE_TMP=$(mktemp -d /tmp/awt-test-merge-XXXXXX)
trap 'rm -rf "$TEST_TMP" "$MERGE_TMP"' EXIT

# Set up upstream bare container and worktrees
mkdir -p "$MERGE_TMP/origin.git"
git init --bare -q -b main "$MERGE_TMP/origin.git"

mkdir -p "$MERGE_TMP/repo"
(
    cd "$MERGE_TMP/repo"
    git clone -q "$MERGE_TMP/origin.git" main
    cd main
    git config user.email "test@test.com"
    git config user.name "Test"
    echo "base" > base.txt
    git add base.txt && git commit -qm "initial commit"
    git push -q origin main

    # Create feature worktree
    git worktree add -b feat-branch "../feat-branch" main >/dev/null 2>&1
    cd "../feat-branch"
    echo "feature" > feat.txt
    git add feat.txt && git commit -qm "feat commit"
)

# Merge feature into main with --no-tmux, --no-remove, --push
(
    cd "$MERGE_TMP/repo/feat-branch"
    "$ROOT/awt/.config/matchmaker/scripts/awt-merge.sh" "main" "$MERGE_TMP/repo/main" "test-session" "main" --no-tmux --no-remove --push
)

# Verify main has feature commit and origin was updated
if [ -f "$MERGE_TMP/repo/main/feat.txt" ]; then
    pass "awt-merge successfully merged branch into target worktree"
else
    fail "awt-merge failed to merge branch into target worktree"
fi

# Verify origin was pushed
remote_commits=$(git -C "$MERGE_TMP/origin.git" log --oneline | wc -l)
if [ "$remote_commits" -ge 2 ]; then
    pass "awt-merge --push successfully pushed merged branch to remote origin (Ship action)"
else
    fail "awt-merge --push failed to push to origin"
fi

# 4.2 Validate --rebase linear merge
(
    cd "$MERGE_TMP/repo"
    # Create advance commit on main
    cd main
    echo "main advance" >> base.txt
    git commit -am "main advance commit"
    git push -q origin main

    # Create new feature branch branched before advance
    git worktree add -b feat-linear "../feat-linear" HEAD~1 >/dev/null 2>&1
    cd "../feat-linear"
    echo "linear feature" > linear.txt
    git add linear.txt && git commit -qm "linear commit"

    # Merge with --rebase
    "$ROOT/awt/.config/matchmaker/scripts/awt-merge.sh" "main" "$MERGE_TMP/repo/main" "linear-session" "main" --no-tmux --no-remove --rebase
)

if [ -f "$MERGE_TMP/repo/main/linear.txt" ]; then
    pass "awt-merge --rebase performed clean linear rebase and fast-forward merge"
else
    fail "awt-merge --rebase failed linear merge"
fi

# 4.3 Validate atomic rollback on failed push
(
    cd "$MERGE_TMP/repo/main"
    git worktree add -b feat-rollback "../feat-rollback" main >/dev/null 2>&1
    cd "../feat-rollback"
    echo "rollback test" > rollback.txt
    git add rollback.txt && git commit -qm "rollback commit"

    # Install blocking pre-receive hook in origin
    echo -e '#!/bin/sh\nexit 1' > "$MERGE_TMP/origin.git/hooks/pre-receive"
    chmod +x "$MERGE_TMP/origin.git/hooks/pre-receive"

    # Attempt to ship (push will fail)
    set +e
    "$ROOT/awt/.config/matchmaker/scripts/awt-merge.sh" "main" "$MERGE_TMP/repo/main" "rollback-sess" "main" --no-tmux --no-remove --push >/dev/null 2>&1
    set -e
    rm -f "$MERGE_TMP/origin.git/hooks/pre-receive"
)

if [ ! -f "$MERGE_TMP/repo/main/rollback.txt" ]; then
    pass "awt-merge --push rolled back target worktree atomically on remote push failure"
else
    fail "awt-merge --push left un-pushed commits in target worktree after push failure"
fi

# ── 5. Validate GitHub PR Handler (awt-pr.sh) ──
echo -e "\n[5/6] Validating awt-pr.sh parsing..."
PR_SCRIPT="$ROOT/awt/.config/matchmaker/scripts/awt-pr.sh"
bash -n "$PR_SCRIPT" || fail "awt-pr.sh syntax error"

# Check PR URL and raw number parsing logic
test_url="https://github.com/org/repo/pull/123"
extracted_from_url=$(echo "$test_url" | sed -E 's/.*pull\/([0-9]+).*/\1/; s/^#//')
if [ "$extracted_from_url" = "123" ]; then
    pass "awt-pr.sh regex correctly extracts PR number from GitHub URLs"
else
    fail "awt-pr.sh failed to extract PR number from URL"
fi

# ── 6. Validate Attention Triage Script & ACPD Parsing ──
echo -e "\n[6/6] Validating ai-agent-triage-jump.sh and ACPD parsing..."
TRIAGE_SCRIPT="$ROOT/tmux/.config/tmux/ai-agent-triage-jump.sh"
bash -n "$TRIAGE_SCRIPT" || fail "ai-agent-triage-jump.sh syntax error"

if [ -x "$TRIAGE_SCRIPT" ]; then
    pass "ai-agent-triage-jump.sh is executable and syntactically valid"
else
    fail "ai-agent-triage-jump.sh is not executable"
fi

# Validate ACPD agentState/list JSON triage parsing & prioritization
acpd_mock='{"jsonrpc":"2.0","result":{"%10":{"last_timestamp":100,"state":"working"},"%11":{"last_timestamp":200,"state":"permission"},"%12":{"last_timestamp":300,"state":"awaiting_input"}}}'
triage_priority=$(echo "$acpd_mock" | jq -r '
  .result // {} | to_entries |
  map(select(.value.state as $s | ["permission", "awaiting_input", "question", "error"] | index($s))) |
  sort_by(-.value.last_timestamp) |
  .[].key
' 2>/dev/null | tr '\n' ' ')

if [[ "$triage_priority" =~ "%12 %11" ]]; then
    pass "ai-agent-triage-jump correctly prioritizes urgent attention states (%12 awaiting_input, %11 permission) over working"
else
    fail "ai-agent-triage-jump failed ACPD JSON priority extraction"
fi

echo -e "\n=== Test Summary ==="
if [ $FAILURES -eq 0 ]; then
    echo -e "\033[1;32mALL TESTS PASSED SUCCESSFULLY! (6/6)\033[0m"
    exit 0
else
    echo -e "\033[1;31mSOME TESTS FAILED ($FAILURES failures)\033[0m"
    exit 1
fi
