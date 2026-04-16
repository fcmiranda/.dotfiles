# gc & sgc — AI-Powered Git Commit Helpers

> Shell functions defined in `git/.zsh/packages/git.zsh`, built on top of conventional commits and any AI provider available in your terminal.

---

## Table of Contents

- [Overview](#overview)
- [gc — Generate a commit message](#gc--generate-a-commit-message)
- [sgc — Smart multi-commit planner](#sgc--smart-multi-commit-planner)
- [Shared Infrastructure](#shared-infrastructure)
- [Configuration](#configuration)
- [Comparison with Alternatives](#comparison-with-alternatives)

---

## Overview

| Feature | `gc` | `sgc` |
|---|---|---|
| Scope | Staged diff → one commit | All unstaged changes → N atomic commits |
| Interaction | Auto-fills readline buffer | Interactive multi-select via `gum` |
| Provider support | opencode, claude, crush, copilot | same |
| Commitlint aware | yes | yes |
| Gitmoji | optional (`-e`) | optional (`-e`) |
| Multi-language | optional (`-l`) | optional (`-l`) |
| Result caching | no | yes (content-hash based) |

---

## gc — Generate a commit message

Analyses the **staged** diff and outputs a single [Conventional Commit](https://www.conventionalcommits.org/) message. The message is pre-filled into the zsh readline buffer so you can review or edit before pressing Enter.

### Usage

```zsh
gc                          # default provider (opencode), single message
gc -p claude                # use claude CLI
gc -p crush                 # use crush CLI
gc -p copilot               # use gh copilot CLI
gc -m github-copilot/gpt-4o # override model (opencode only)
gc -g 3                     # generate 3 candidates, pick one interactively
gc -l es                    # commit message in Spanish
gc -e                       # prepend a gitmoji emoji
gc hook install             # install prepare-commit-msg hook in the repo
gc hook uninstall           # remove the gc-managed hook
gc hook status              # show hook installation status
```

### Flags

| Flag | Description |
|---|---|
| `-p / --provider` | AI backend: `opencode` (default), `claude`, `crush`, `copilot` |
| `-m / --model` | Model ID passed to opencode (e.g. `github-copilot/gpt-4o`) |
| `-g N / --generate N` | Generate N distinct candidates; presents a `gum choose` picker |
| `-l / --lang` | ISO 639-1 language code for the output message |
| `-e / --emoji` | Prepend a gitmoji matching the commit type |

### Environment overrides

```zsh
GC_PROVIDER=claude gc
GC_MODEL=github-copilot/gpt-5 gc
GC_EMOJI=1 gc
```

### Workflow

1. If nothing is staged, `gc` detects unstaged/untracked files and prompts via `gum choose`: **Add all files** or **Select files** (fuzzy filter).
2. The staged diff is filtered through `.sgcignore` rules (lock files, minified assets, etc.) and compressed to reduce token count without losing signal.
3. If a `commitlint` config exists in the repo root, its rules (allowed types, scopes, max length, casing) are injected into the prompt.
4. The AI prompt enforces Conventional Commits format, 72-char subject limit, and optional gitmoji/language rules.
5. The result is printed and pre-filled into the readline buffer: `git commit -m "feat(scope): ..."`.

### Git hook integration

```zsh
gc hook install    # writes prepare-commit-msg to .git/hooks/
gc hook uninstall  # removes only the gc-managed block, leaving other hooks intact
gc hook status     # check if installed
```

When installed, the hook runs `gc` automatically whenever `git commit` is called without a `-m` message (e.g. bare `git commit`).

---

## sgc — Smart multi-commit planner

Analyses **all unstaged and untracked changes** at once and asks the AI to group them into logical, atomic commits. You then select which ones to execute via a multi-select `gum` UI.

### Usage

```zsh
sgc                          # default provider
sgc -p claude                # use claude CLI
sgc -m github-copilot/gpt-4o # override model
sgc -l es                    # messages in Spanish
sgc -e                       # gitmoji prefixes
```

### Workflow

1. Collects all unstaged diffs and untracked file contents (filtered through `.sgcignore`).
2. Sends a single prompt asking the AI to group changes into atomic commits, each with a `message` and a `files` list.
3. Result is cached by a content hash — if you re-run `sgc` without changing any files, it reuses the previous plan instantly.
4. Presents a `gum choose --no-limit` picker (all pre-selected). Space to toggle, Enter to confirm.
5. For each selected commit: stages the specified files and runs `git commit -m "..."`.
6. Updates the cache to retain any un-selected commits for the next run.

### Caching

The cache lives in `${XDG_CACHE_HOME:-~/.cache}/sgc/<repo-hash>/`. It stores:

- `last.hash` — MD5 of the content fingerprint (status + diff + untracked + options)
- `last.json` — the AI-generated commit plan

If the working tree changes between runs, the cache is invalidated and a fresh AI call is made.

---

## Shared Infrastructure

These internal helpers are used by both `gc` and `sgc`:

| Helper | Purpose |
|---|---|
| `_gc_load_ignore_patterns` | Loads `.sgcignore` (repo-local) or `~/.sgcignore` (global) plus built-in defaults |
| `_gc_filter_ignored_files` | Filters filenames via Python `fnmatch`, matching both basename and full path |
| `_gc_filter_diff_by_ignore` | Strips ignored files' hunks from a unified diff |
| `_gc_compress_diff` | Reduces token count: strips index/mode metadata, trims context lines, caps large hunks at 80 changed lines |
| `_gc_load_commitlint_rules` | Parses commitlint config (JSON/YAML/JS) and emits constraint lines for the prompt |
| `_gc_emoji_rule` | Returns the gitmoji instruction block mapping types to emojis |
| `_gc_hook_script` | Emits the `prepare-commit-msg` hook body |
| `_gc_hook` | Manages hook install/uninstall/status |

### `.sgcignore`

Create a `.sgcignore` file in your repo root (or `~/.sgcignore` globally) to exclude files from AI analysis. Same glob syntax as `.gitignore` basenames.

Built-in defaults always applied:

```
*-lock.*
*.lock
*.min.js
*.min.css
*.map
```

---

## Configuration

### Commitlint integration

If your repo has a commitlint config (`commitlint.config.js`, `.commitlintrc.json`, `.commitlintrc.yml`, etc., or a `commitlint` key in `package.json`), `gc`/`sgc` will automatically:

- Restrict types to the allowed `type-enum` list
- Restrict scopes to the allowed `scope-enum` list
- Enforce subject/header max-length
- Enforce subject-case and scope-case rules

No setup required — it's detected automatically.

### Gitmoji map

| Type | Emoji |
|---|---|
| feat | ✨ |
| fix | 🐛 |
| refactor | ♻️ |
| perf | ⚡️ |
| docs | 📝 |
| style | 🎨 |
| test | 🧪 |
| chore | 🔧 |
| ci | 👷 |
| build | 📦 |
| revert | ⏪️ |
| security | 🔒️ |

---

## Comparison with Alternatives

| Feature | `gc` / `sgc` | [opencommit](https://github.com/di-sukharev/opencommit) | [aicommits](https://github.com/Nutlope/aicommits) | [commitgpt](https://github.com/RomanHotsiy/commitgpt) | [cz-git](https://github.com/Zhengqbbb/cz-git) |
|---|---|---|---|---|---|
| **Language** | zsh (no install) | Node.js global CLI | Node.js global CLI | Node.js global CLI | Node.js (commitizen adapter) |
| **Setup** | Source the file | `npm i -g opencommit` | `npm i -g aicommits` | `npm i -g commitgpt` | `npm i -g cz-git` |
| **Provider flexibility** | opencode, claude, crush, copilot | OpenAI, Anthropic, Azure, Ollama | OpenAI | OpenAI | OpenAI (via commitizen) |
| **Local/offline models** | via opencode or crush | Ollama support | no | no | no |
| **Multi-commit planning** | `sgc` splits changes into atomic commits | no | no | no | no |
| **Commitlint aware** | auto-detected from repo config | yes (oc config) | no | no | yes (native) |
| **Result caching** | yes (sgc, content-hash) | no | no | no | no |
| **Staged-only / all changes** | both (`gc` = staged, `sgc` = all) | staged only | staged only | staged only | staged only |
| **Interactive file picker** | yes (gum) | no | no | no | no |
| **Candidate selection** | yes (`gc -g N`) | yes (`oco -g N`) | no | no | no |
| **Gitmoji** | optional (`-e`) | optional | no | no | optional |
| **Multi-language output** | yes (`-l ISO`) | yes (`oco config set language`) | no | no | no |
| **Git hook** | `gc hook install` | `oco hook set` | no | no | via commitizen |
| **Diff compression** | yes (custom Python pipeline) | no | no | no | no |
| **File ignore rules** | `.sgcignore` / `~/.sgcignore` | `.opencommitignore` | no | no | no |
| **Readline pre-fill** | yes (review before committing) | commits directly | commits directly | commits directly | via prompt |
| **Dependencies** | `gum`, `python3`, one AI CLI | Node.js, API key | Node.js, API key | Node.js, API key | Node.js, commitizen |

### Key differentiators

**`gc` vs opencommit**
Both follow the same spirit (staged diff → Conventional Commit). `gc` lives entirely in your shell with no Node.js dependency, supports any AI CLI (including fully local models via `crush`/opencode), and pre-fills readline instead of committing directly — giving you a review step. opencommit has a wider provider matrix and a richer config system.

**`sgc` — unique capability**
No mainstream tool offers automated multi-commit splitting. `sgc` analyses the full working tree and proposes an atomic commit plan, which you approve interactively. This is especially useful after long coding sessions where you want a clean history without manually staging hunks.

**Diff compression**
`gc`/`sgc` run the diff through a custom Python pipeline that strips git metadata noise, trims repeated context lines, and caps large hunks — significantly reducing token usage and cost on large changesets, while preserving all signal the AI needs.

**No global install, no Node.js**
Everything is plain zsh + Python 3 (stdlib only). If you already have `gum` and one AI CLI in your PATH, `gc`/`sgc` work immediately.
