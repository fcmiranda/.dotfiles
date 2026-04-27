# Git Worktree Setup for Dotfiles

This repository uses a **bare clone + worktree** pattern to manage dotfiles. This is a common and clean approach — the bare repo holds only git internals, while worktrees provide normal working directories for each branch.

---

## How It Works

```
~/.dotfiles/          ← bare git repo (no working files, only git internals)
~/.dotfiles/main/     ← worktree for the `main` branch (actual dotfiles live here)
```

A **bare clone** (`git clone --bare`) stores only the `.git` contents without a working tree. Worktrees are then attached to provide checked-out branches as regular directories.

---

## Initial Setup (from scratch)

```bash
# 1. Clone the repo as a bare repository
git clone --bare https://github.com/fcmiranda/.dotfiles.git ~/.dotfiles

# 2. Create a worktree for the main branch
git -C ~/.dotfiles worktree add ~/.dotfiles/main main
```

---

## Working with the Dotfiles

Always run git commands from inside a worktree directory, or pass the git dir explicitly:

```bash
# From inside the worktree
cd ~/.dotfiles/main
git status
git add .
git commit -m "feat: update config"
git push

# Or from anywhere using --git-dir
git --git-dir=~/.dotfiles --work-tree=~/.dotfiles/main status
```

---

## Adding a New Branch as a Worktree

```bash
# Create a new worktree for an existing branch
git -C ~/.dotfiles worktree add ~/.dotfiles/<branch-name> <branch-name>

# Create a worktree with a new branch
git -C ~/.dotfiles worktree add -b <new-branch> ~/.dotfiles/<new-branch>
```

---

## Listing and Removing Worktrees

```bash
# List all worktrees
git -C ~/.dotfiles worktree list

# Remove a worktree (after deleting the directory)
rm -rf ~/.dotfiles/<branch-name>
git -C ~/.dotfiles worktree prune
```

---

## Why This Approach?

| Approach | Pros | Cons |
|---|---|---|
| Bare clone + worktrees | Clean separation; multiple branches as directories; no accidental `git` in `~` | Slightly more setup |
| Alias trick (`$HOME` as work-tree) | Simple | Pollutes `~` with git context; risky `git add .` |
| GNU Stow only | Package-based symlinks | No git worktree flexibility |

The bare clone pattern avoids the common pitfall of running `git` in `~` and accidentally staging unrelated files.
