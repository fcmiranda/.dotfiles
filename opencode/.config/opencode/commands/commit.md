---
description: Generate a commit message from staged changes
model: opencode/minimax-m2.5-free
---

Analyze the following staged git diff and generate a concise, conventional commit message.

Rules:
- Use the conventional commits format: `<type>(<optional scope>): <description>`
- Valid types: feat, fix, refactor, chore, docs, style, test, perf, ci, build
- Keep the subject line under 72 characters
- If the changes are complex, add a short body after a blank line explaining the "why"
- Output ONLY the commit message, nothing else

Staged diff:
!`git diff --staged`
