# AGENTS.md

This repository is a GNU Stow-managed dotfiles worktree. Keep instructions here minimal and link to the existing docs for anything detailed.

## Working Model

- Treat each top-level directory as a stow package unless it is `.bare`, `.git`, `.github`, `.shell`, `scripts`, or `docs`.
- Preserve the mirrored home-directory layout inside each package, for example `nvim/.config/nvim/...` maps to `~/.config/nvim/...`.
- `stow-lock.json` is generated state. Do not edit it manually.
- The primary worktree is the only tree that should be stowed to `$HOME`. Feature worktrees are sandboxes and should not be stowed.

See [git-worktree-guide.md](git-worktree-guide.md) and [GIT_WORKTREE_SETUP.md](GIT_WORKTREE_SETUP.md) for the worktree model.

## Validation

- Run `./stow.sh -n` after changes that may affect symlinks.
- Run `./stow.sh -r <package>` only when you add new files to an existing package or add a new package directory.
- Use `./stow.sh -s` to inspect stowed packages.
- If you need to verify a live target, use `readlink` on the path in `$HOME`.

## Install Workflow

- `.shell/install/install.zsh` is the source of truth for package and plugin installation.
- Put custom package installers in `.shell/install/packages/<name>.zsh`.
- Put plugin installers in `.shell/install/plugins/<name>.zsh`.
- Those installer scripts are sourced, so use `return` for early exits instead of `exit`.

See [.shell/install/README.md](.shell/install/README.md) for the current bootstrap notes.

## Agent Guidance

- Prefer small, package-local edits over repo-wide reorganization.
- When adding a new managed file, place it in the correct stow package first, then restow that package if needed.
- When a task mentions adopting an existing file into dotfiles, check [utils/.local/bin/stow-it](utils/.local/bin/stow-it).
- If you are asked to commit, follow the conventional commit rules in [.commitlintrc.json](.commitlintrc.json) and the helper workflow in [git/GC_SGC.md](git/GC_SGC.md).
- Link to existing docs instead of copying their content into new instruction files.

## Useful References

- [git-worktree-guide.md](git-worktree-guide.md)
- [GIT_WORKTREE_SETUP.md](GIT_WORKTREE_SETUP.md)
- [.shell/install/README.md](.shell/install/README.md)
- [.commitlintrc.json](.commitlintrc.json)
- [git/GC_SGC.md](git/GC_SGC.md)
- [stow.sh](stow.sh)
- [utils/.local/bin/stow-it](utils/.local/bin/stow-it)

<!-- ai-memory:start -->
## Long-term memory (ai-memory)

This project uses [ai-memory](https://github.com/akitaonrails/ai-memory)
for cross-session continuity.

**Default to the current project - always.** Every ai-memory tool
auto-scopes to the project resolved from your session's working
directory. **Do NOT pass `project`, `workspace`, or `cwd` arguments unless
the user explicitly references a *different* project by name** (e.g. "what
did we decide in the `other-app` project?"). Phrases like "this project",
"here", "we", "our work", and "where did we leave off" all mean the
*current* project, so call tools with no scoping args.

This default assumes the MCP client can identify the current agent
session. Static MCP clients in parallel sessions for the same user cannot
forward the real agent session id automatically; pass explicit
`workspace` + `project` / `scopes`, or use a session-aware bridge that
forwards the lifecycle-hook session id on MCP calls.

**Lifecycle hooks already capture sanitized, bounded prompt and tool-lifecycle
observations automatically.** They are not complete native transcripts;
managed `ai-memory run` launches add the portable visible-event ledger. Do not
manually write routine notes. Only write durable memory when the user explicitly asks
to remember or annotate something permanently.

### Use the installed ai-memory Agent Skills

Detailed tool-routing guidance lives in the installed ai-memory Agent
Skills. When a task matches an installed ai-memory Agent Skill, load and
follow that skill before calling ai-memory tools. The skills cover memory
retrieval, handoffs, durable pages, learning maintenance, and routing
install or refresh work.

### When you write a project rule, write it here

If you're about to write a durable project rule ("always X", "never
Y", "all PRs must ..."), write it in the project's canonical agent instruction file.
Many projects use CLAUDE.md for Claude Code and
AGENTS.md for Codex / OpenCode / Cursor / Gemini CLI / Grok Build CLI / Kimi Code,
but if the project says one file is canonical, use that file.

If the rule is a standing *user/team* preference that should apply to
every project (tech choices, code style, personal conventions), save it
to ai-memory's reserved global scope instead — the durable-pages skill
covers how. Default memory reads surface global-scope pages in every
project automatically.

### Refreshing this snippet

This block is maintained by ai-memory. Two ways to refresh it with the
latest binary's recommended copy:

- **From the agent** (no terminal needed): ask "refresh the ai-memory
  routing in this project". The agent calls `memory_install_self_routing`,
  picks the right filename for itself (Claude Code -> `CLAUDE.md`; Codex /
  OpenCode / Cursor / Gemini / Grok -> `AGENTS.md`; Kimi Code -> `AGENTS.md`),
  uses its Write / Edit tool to replace or append the returned
  `markered_block` while preserving
  non-ai-memory user content, then writes or updates each returned
  `managed_skills` item under the selected skill root from `target_hints`
  using its `relative_path`.
- **From the CLI**: `ai-memory install-instructions` (defaults to
  `CLAUDE.md`; pass `--target AGENTS.md` for non-Claude agents or projects
  that use `AGENTS.md` as the canonical instruction file).

Both are idempotent: re-runs replace the block delimited by the ai-memory
start/end HTML-comment markers, without disturbing the rest of the file.
<!-- ai-memory:end -->
