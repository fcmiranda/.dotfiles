# AGENTS.md

This repository is a GNU Stow-managed dotfiles worktree. Keep instructions here minimal and link to the existing docs for anything detailed.

## Working Model

- Treat each top-level directory as a stow package unless it is `.bare`, `.git`, `.github`, `.shell`, or `scripts`.
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