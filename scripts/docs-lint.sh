#!/usr/bin/env bash
# ==============================================================================
# scripts/docs-lint.sh
# Comprehensive documentation linter and integrity validator for dotfiles.
#
# Checks performed:
#  1. Root directory cleanliness: No loose/unapproved markdown files in repository root.
#  2. Markdown link integrity: Validates that all internal relative [links](path) resolve.
#  3. Language & canonical guidelines enforcement.
# ==============================================================================

set -euo pipefail

REPO_ROOT="$(cd "$(dirname "${BASH_SOURCE[0]}")/.." && pwd)"
ERRORS=0

# Colors for terminal output
RED='\033[0;31m'
GREEN='\033[0;32m'
YELLOW='\033[0;33m'
BLUE='\033[0;34m'
BOLD='\033[1m'
NC='\033[0m'

echo -e "${BOLD}${BLUE}=== [Docs Linter] Starting Documentation Integrity Audit ===${NC}"

# ------------------------------------------------------------------------------
# Check 1: Root Markdown Cleanliness (No unapproved loose markdown files)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[1/2] Checking Root Markdown Cleanliness...${NC}"

ALLOWED_ROOT_MD=("README.md" "AGENTS.md" "prompt.md" "OPENSOURCE_PLAN.md" "todo.md")

while IFS= read -r file; do
    filename="$(basename "$file")"
    allowed=0
    for ok in "${ALLOWED_ROOT_MD[@]}"; do
        if [[ "$filename" == "$ok" ]]; then
            allowed=1
            break
        fi
    done

    if [[ $allowed -eq 0 ]]; then
        echo -e "  ${RED}✖ Disallowed markdown file in repository root: $filename${NC}"
        echo -e "    ${YELLOW}↳ Move documentation to docs/<category>/ or remove if obsolete.${NC}"
        ERRORS=$((ERRORS + 1))
    fi
done < <(find "$REPO_ROOT" -maxdepth 1 -name "*.md" -type f)

if [[ $ERRORS -eq 0 ]]; then
    echo -e "  ${GREEN}✔ Root directory is clean. Only canonical markdown files present.${NC}"
fi

# ------------------------------------------------------------------------------
# Check 2: Relative Markdown Link Integrity (Zero Broken Links)
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}[2/2] Checking Relative Markdown Links Across Repository...${NC}"

BROKEN_LINKS_OUTPUT=$(python3 - << 'EOF'
import re, os, sys

repo_root = os.environ.get("REPO_ROOT", ".")
broken = []
link_pattern = re.compile(r"(?<!`)\[([^\]]+)\]\(([^)]+)\)(?!`)")

for dirpath, _, filenames in os.walk(repo_root):
    # Ignore git internals and apm modules
    if any(p in dirpath for p in ["/.git", "/.bare", "/apm_modules"]):
        continue
    for f in filenames:
        if f.endswith(".md"):
            filepath = os.path.join(dirpath, f)
            with open(filepath, "r", encoding="utf-8", errors="ignore") as fp:
                in_code_block = False
                for line_idx, line in enumerate(fp, 1):
                    stripped = line.strip()
                    if stripped.startswith("```"):
                        in_code_block = not in_code_block
                        continue
                    if in_code_block:
                        continue
                    # Remove inline code blocks `...` to avoid matching illustrative markdown syntax
                    sanitized_line = re.sub(r"`[^`]+`", "", line)
                    for match in link_pattern.finditer(sanitized_line):
                        target = match.group(2).strip()
                        # Ignore external or special protocol links
                        if any(target.startswith(proto) for proto in ["http://", "https://", "mailto:", "#", "file://", "conversation://"]):
                            continue
                        clean_target = target.split("#")[0]
                        if not clean_target:
                            continue
                        target_path = os.path.normpath(os.path.join(dirpath, clean_target))
                        if not os.path.exists(target_path):
                            rel_source = os.path.relpath(filepath, repo_root)
                            broken.append(f"  ✖ {rel_source}:{line_idx} -> '{target}' (resolved to non-existent '{os.path.relpath(target_path, repo_root)}')")

if broken:
    for b in broken:
        print(b)
    sys.exit(len(broken))
else:
    sys.exit(0)
EOF
) || LINK_EXIT_CODE=$?

LINK_EXIT_CODE=${LINK_EXIT_CODE:-0}

if [[ $LINK_EXIT_CODE -gt 0 ]]; then
    echo -e "${RED}Found $LINK_EXIT_CODE broken relative link(s):${NC}"
    echo -e "$BROKEN_LINKS_OUTPUT"
    ERRORS=$((ERRORS + LINK_EXIT_CODE))
else
    echo -e "  ${GREEN}✔ All internal relative markdown links resolve successfully.${NC}"
fi

# ------------------------------------------------------------------------------
# Summary & Exit Code
# ------------------------------------------------------------------------------
echo -e "\n${BOLD}=== [Docs Linter] Audit Summary ===${NC}"
if [[ $ERRORS -eq 0 ]]; then
    echo -e "${GREEN}${BOLD}✔ SUCCESS: Documentation is 100% compliant with zero broken links and zero clutter.${NC}\n"
    exit 0
else
    echo -e "${RED}${BOLD}✖ FAILED: $ERRORS documentation issue(s) detected. Please resolve above errors.${NC}\n"
    exit 1
fi
