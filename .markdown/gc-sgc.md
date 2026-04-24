# gc & sgc — AI Git Commit Tools

Shell functions that generate conventional commit messages from your changes using any AI provider CLI.
Defined in `git/.zsh/packages/git.zsh`.

---

## gc — single commit message generator

Generates a commit message for your **staged** changes. If nothing is staged, it prompts you to stage files first.

### Usage

```bash
gc                        # generate a message with the default provider
gc -p claude              # use the claude CLI
gc -p crush               # use the crush CLI
gc -p copilot             # use gh copilot
gc -m opencode/minimax-m2.5-free  # override the model (opencode only)
gc -g 3                   # generate 3 candidates and pick one
gc -l es                  # generate the message in Spanish
gc -e                     # prefix the message with a gitmoji emoji
gc hook install           # install the prepare-commit-msg hook in this repo
gc hook uninstall         # remove the gc-managed hook
gc hook status            # check whether the hook is active
```

### Flags

| Flag | Short | Description |
|---|---|---|
| `--provider` | `-p` | AI provider CLI: `opencode` (default), `claude`, `crush`, `copilot` |
| `--model` | `-m` | Model name, passed to opencode only |
| `--generate` | `-g` | Number of message candidates to generate and pick from |
| `--lang` | `-l` | Output language as ISO 639-1 code (`es`, `fr`, `ja`, `pt`, …) |
| `--emoji` | `-e` | Prefix the commit message with a gitmoji emoji |

### Environment overrides

```bash
GC_PROVIDER=claude gc
GC_MODEL=opencode/minimax-m2.5-free gc
GC_FALLBACK_MODELS=opencode/minimax-m2.5-free,opencode/ling-2.6-flash-free gc
GC_EMOJI=1 gc        # always use emojis without passing -e
```

### How it works

1. Checks for staged changes; if none, prompts to stage with `gum choose`
2. Loads ignore patterns from `.sgcignore` (or `~/.sgcignore`) and filters the diff
3. Compresses the diff — strips index hashes, collapses context lines, caps large hunks at 80 changed lines
4. Reads `.commitlintrc` (any format) from the repo root and injects your project's type/scope/length rules into the prompt
5. Sends the prompt to the selected AI provider
6. When `-g N` is used, presents N candidates via `gum choose`; otherwise pre-fills the zsh readline buffer with `git commit -m "…"` so you can review and edit before pressing Enter

---

## sgc — smart multi-commit generator

Analyzes **all unstaged changes and untracked files** at once, groups them into logical atomic commits, and lets you pick which ones to execute. Each selected commit is staged and committed automatically.

### Usage

```bash
sgc                       # analyze everything and suggest commits
sgc -p claude             # use the claude CLI
sgc -m opencode/minimax-m2.5-free  # override the model
sgc -l pt                 # generate commit messages in Portuguese
sgc -e                    # prefix all commit messages with gitmoji emojis
```

### Flags

| Flag | Short | Description |
|---|---|---|
| `--provider` | `-p` | AI provider CLI |
| `--model` | `-m` | Model name (opencode only) |
| `--lang` | `-l` | Output language ISO 639-1 code |
| `--emoji` | `-e` | Prefix all commit messages with gitmoji emojis |

### How it works

1. Collects all unstaged diffs and untracked file contents
2. Filters out ignored files via `.sgcignore`
3. Fingerprints the full context (status + diff + untracked + lang + emoji + commitlint rules) as an md5 hash
4. If the hash matches the last run, **returns the cached commit plan instantly** (no AI call)
5. Otherwise, sends everything to the AI and asks it to group changes into atomic commits
6. Presents the proposed commits with `gum choose` (multi-select, all pre-checked)
7. For each selected commit: stages only its files, then commits with the generated message
8. After committing, updates the cache with the **remaining** (unselected) commits so the next `sgc` run shows exactly them — no re-analysis needed

### Partial acceptance

If you have 3 suggested commits and only accept 1, the remaining 2 are preserved in the cache. The next `sgc` run shows them immediately (using the "↩ using cached commit plan" indicator) without calling the AI again.

---

## Emoji (gitmoji)

Pass `-e` / `--emoji` to prefix every generated message with the canonical gitmoji for its type:

| Type | Emoji |
|---|---|
| `feat` | ✨ |
| `fix` | 🐛 |
| `refactor` | ♻️ |
| `perf` | ⚡️ |
| `docs` | 📝 |
| `style` | 🎨 |
| `test` | 🧪 |
| `chore` | 🔧 |
| `ci` | 👷 |
| `build` | 📦 |

```bash
gc -e              # ✨ feat(gc): add emoji support
sgc -e             # all suggested commits are prefixed
GC_EMOJI=1 gc      # set as default via env var
```

---

## .sgcignore

Place a `.sgcignore` file in your repo root (or `~/.sgcignore` for a global default) to exclude files from AI analysis. Uses the same glob syntax as `.gitignore`.

```
# .sgcignore example
dist/
*.snap
*.svg
CHANGELOG.md
```

**Built-in defaults** (always applied, no config needed):

```
*-lock.*
*.lock
*.min.js
*.min.css
*.map
```

---

## Commitlint integration

When a commitlint config is present in the repo root, `gc` and `sgc` automatically read it and inject the constraints into the AI prompt. No extra flags needed.

**Supported config files** (searched in order):

```
.commitlintrc
.commitlintrc.json
.commitlintrc.yml / .commitlintrc.yaml
.commitlintrc.js / .commitlintrc.cjs
commitlint.config.js / .ts / .cjs / .mjs
package.json  (commitlint key)
```

**Extracted rules:**

| Rule | Effect on prompt |
|---|---|
| `type-enum` | Replaces the default type list with your exact allowed types |
| `scope-enum` | Lists valid scopes the AI must choose from |
| `header-max-length` / `subject-max-length` | Replaces the default 72-char limit |
| `subject-case` | Enforces casing (e.g. lower-case, never sentence-case) |
| `scope-case` | Enforces scope casing |

The extracted rules are included in the `sgc` cache fingerprint — changing your commitlint config invalidates the cache automatically.

---

## prepare-commit-msg hook

`gc hook install` writes a `prepare-commit-msg` hook into `.git/hooks/` of the current repo. Once installed, any `git commit` (from the CLI, VSCode Source Control, JetBrains, etc.) will automatically pre-populate the commit message editor with an AI-generated message.

The hook is **safe by default** — it only runs when:
- No `-m` message was supplied
- The commit is not a merge, squash, or amend
- There are staged changes

```bash
gc hook install     # install in current repo
gc hook uninstall   # remove (only removes the gc-managed section)
gc hook status      # check installation
```

---

## Providers

| Provider | Flag | Requirement |
|---|---|---|
| `opencode` | default | `opencode` CLI in PATH |
| `claude` | `-p claude` | `claude` CLI in PATH |
| `crush` | `-p crush` | `crush` CLI in PATH |
| `copilot` | `-p copilot` | `gh` CLI with Copilot extension |

Switch the default permanently:

```bash
export GC_PROVIDER=claude   # in ~/.zshrc or similar
```

Shell functions that generate conventional commit messages from your changes using any AI provider CLI.
Defined in `git/.zsh/packages/git.zsh`.

---

## gc — single commit message generator

Generates a commit message for your **staged** changes. If nothing is staged, it prompts you to stage files first.

### Usage

```bash
gc                        # generate a message with the default provider
gc -p claude              # use the claude CLI
gc -p crush               # use the crush CLI
gc -p copilot             # use gh copilot
gc -m opencode/minimax-m2.5-free  # override the model (opencode only)
gc -g 3                   # generate 3 candidates and pick one
gc -l es                  # generate the message in Spanish
gc hook install           # install the prepare-commit-msg hook in this repo
gc hook uninstall         # remove the gc-managed hook
gc hook status            # check whether the hook is active
```

### Flags

| Flag | Short | Description |
|---|---|---|
| `--provider` | `-p` | AI provider CLI: `opencode` (default), `claude`, `crush`, `copilot` |
| `--model` | `-m` | Model name, passed to opencode only |
| `--generate` | `-g` | Number of message candidates to generate and pick from |
| `--lang` | `-l` | Output language as ISO 639-1 code (`es`, `fr`, `ja`, `pt`, …) |

### Environment overrides

```bash
GC_PROVIDER=claude gc
GC_MODEL=opencode/minimax-m2.5-free gc
GC_FALLBACK_MODELS=opencode/minimax-m2.5-free,opencode/ling-2.6-flash-free gc
```

### How it works

1. Checks for staged changes; if none, prompts to stage with `gum choose`
2. Loads ignore patterns from `.sgcignore` (or `~/.sgcignore`) and filters the diff
3. Compresses the diff — strips index hashes, collapses context lines, caps large hunks at 80 changed lines
4. Reads `.commitlintrc` (any format) from the repo root and injects your project's type/scope/length rules into the prompt
5. Sends the prompt to the selected AI provider
6. When `-g N` is used, presents N candidates via `gum choose`; otherwise pre-fills the zsh readline buffer with `git commit -m "…"` so you can review and edit before pressing Enter

---

## sgc — smart multi-commit generator

Analyzes **all unstaged changes and untracked files** at once, groups them into logical atomic commits, and lets you pick which ones to execute. Each selected commit is staged and committed automatically.

### Usage

```bash
sgc                       # analyze everything and suggest commits
sgc -p claude             # use the claude CLI
sgc -m opencode/minimax-m2.5-free  # override the model
sgc -l pt                 # generate commit messages in Portuguese
```

### Flags

| Flag | Short | Description |
|---|---|---|
| `--provider` | `-p` | AI provider CLI |
| `--model` | `-m` | Model name (opencode only) |
| `--lang` | `-l` | Output language ISO 639-1 code |

### How it works

1. Collects all unstaged diffs and untracked file contents
2. Filters out ignored files via `.sgcignore`
3. Fingerprints the full context (status + diff + untracked + lang + commitlint rules) as an md5 hash
4. If the hash matches the last run, **returns the cached commit plan instantly** (no AI call)
5. Otherwise, sends everything to the AI and asks it to group changes into atomic commits
6. Presents the proposed commits with `gum choose` (multi-select, all pre-checked)
7. For each selected commit: stages only its files, then commits with the generated message
8. After committing, updates the cache with the **remaining** (unselected) commits so the next `sgc` run shows exactly them — no re-analysis needed

### Partial acceptance

If you have 3 suggested commits and only accept 1, the remaining 2 are preserved in the cache. The next `sgc` run shows them immediately (using the "↩ using cached commit plan" indicator) without calling the AI again.

---

## .sgcignore

Place a `.sgcignore` file in your repo root (or `~/.sgcignore` for a global default) to exclude files from AI analysis. Uses the same glob syntax as `.gitignore`.

```
# .sgcignore example
dist/
*.snap
*.svg
CHANGELOG.md
```

**Built-in defaults** (always applied, no config needed):

```
*-lock.*
*.lock
*.min.js
*.min.css
*.map
```

---

## Commitlint integration

When a commitlint config is present in the repo root, `gc` and `sgc` automatically read it and inject the constraints into the AI prompt. No extra flags needed.

**Supported config files** (searched in order):

```
.commitlintrc
.commitlintrc.json
.commitlintrc.yml / .commitlintrc.yaml
.commitlintrc.js / .commitlintrc.cjs
commitlint.config.js / .ts / .cjs / .mjs
package.json  (commitlint key)
```

**Extracted rules:**

| Rule | Effect on prompt |
|---|---|
| `type-enum` | Replaces the default type list with your exact allowed types |
| `scope-enum` | Lists valid scopes the AI must choose from |
| `header-max-length` / `subject-max-length` | Replaces the default 72-char limit |
| `subject-case` | Enforces casing (e.g. lower-case, never sentence-case) |
| `scope-case` | Enforces scope casing |

The extracted rules are included in the `sgc` cache fingerprint — changing your commitlint config invalidates the cache automatically.

---

## prepare-commit-msg hook

`gc hook install` writes a `prepare-commit-msg` hook into `.git/hooks/` of the current repo. Once installed, any `git commit` (from the CLI, VSCode Source Control, JetBrains, etc.) will automatically pre-populate the commit message editor with an AI-generated message.

The hook is **safe by default** — it only runs when:
- No `-m` message was supplied
- The commit is not a merge, squash, or amend
- There are staged changes

```bash
gc hook install     # install in current repo
gc hook uninstall   # remove (only removes the gc-managed section)
gc hook status      # check installation
```

---

## Providers

| Provider | Flag | Requirement |
|---|---|---|
| `opencode` | default | `opencode` CLI in PATH |
| `claude` | `-p claude` | `claude` CLI in PATH |
| `crush` | `-p crush` | `crush` CLI in PATH |
| `copilot` | `-p copilot` | `gh` CLI with Copilot extension |

Switch the default permanently:

```bash
export GC_PROVIDER=claude   # in ~/.zshrc or similar
```
