# sgc interactive preview — design plan (v2)

## Goal

Add a `-p / --preview` flag to `sgc` that opens an interactive two-panel UI before
committing, letting the user browse proposed commits and inspect their diffs.

---

## Available tools (installed)

| Tool | Version | Role |
|---|---|---|
| fzf | 0.70.0 | fuzzy list + preview pane |
| lazygit | 0.60.0 | full git TUI, custom commands support |
| bat | 0.26.1 | syntax-highlighted file/diff rendering |
| go | 1.26.1 | optional: custom TUI binary |
| delta | ✗ | not installed |

---

## Layout

```
 Commits                      │  Files & diff
──────────────────────────────┼──────────────────────────────────────────
 → feat(test): add greeting   │  ● test_temp.js  (+12 / -0)
 -  chore: remove initial     │  ──────────────────────────────────────
                              │  @@ -0,0 +1,12 @@
                              │  +const greet = (name) => {
                              │  +  console.log(`Hello, ${name}!`)
                              │  +}
                              │
                              │           [ctrl-/ focus · ↑↓ scroll]
```

---

## Implementation options

### Option A — lazygit custom command (simplest integration)

lazygit v0.60 supports `customCommands` — keybindings that run shell scripts and
optionally reload the UI. The integration works as follows:

```
User opens lazygit → presses keybind (e.g. <c-a>) → sgc runs in a popup
→ user selects commits → commits are made → lazygit refreshes
```

lazygit config (`~/.config/lazygit/config.yml`):
```yaml
customCommands:
  - key: '<c-a>'
    context: 'files'
    description: 'AI commit (sgc)'
    command: 'sgc'
    subprocess: true
    loadingText: 'Running sgc...'
```

**Pros:**
- Diff preview is lazygit itself — already the best git UI available
- Zero preview code to write
- User stays in lazygit after commits are made
- `subprocess: true` gives sgc a real TTY (gum/fzf work correctly)

**Cons:**
- The sgc commit-list preview is still `gum choose` (no diff inline)
- The lazygit keybind is opt-in and separate from `sgc -p`
- Cannot show the AI-planned commit groupings inside lazygit's own panels

**This is the best entry point for lazygit users regardless of which preview option
is chosen below — add it alongside any other option.**

---

### Option B — fzf `--preview` + bat (recommended for `sgc -p`)

fzf 0.70 natively supports two-panel layout with togglable focus. bat provides
syntax-highlighted diff rendering (delta is not installed).

| Feature | How |
|---|---|
| Two-panel layout | `--preview-window=right:60%` |
| Focus toggle | `--bind 'ctrl-/:toggle-preview-focus'` |
| Preview scrolling | built-in when preview is focused |
| Syntax-highlighted diff | `git diff -- <files> \| bat --language=diff --style=plain` |
| Multi-select | `--multi` (already used in sgc) |

The preview command receives the selected commit index and runs:
```sh
_sgc_preview_cmd <json> <index>
# → extracts files[index] from JSON
# → runs: git diff -- <files> | bat --language=diff --style=plain --color=always
```

**Pros:** no binary, already in dotfiles toolchain, covers all layout requirements.  
**Cons:** fzf layout is fixed; cannot edit commit messages inline.

---

### Option C — lazygit temp-branch preview

Stage the AI-proposed commits onto a **temporary branch** (one real commit per
planned commit), open lazygit pointed at that branch, then apply or discard:

```
sgc plans [A, B, C]
  → git stash
  → git checkout -b sgc/preview-<hash>
  → stage + commit A, B, C (real commits)
  → lazygit (user reviews full log + diffs natively)
  → on confirm: git checkout original-branch + git cherry-pick A B C
  → on abort:   git checkout original-branch, drop branch + restore stash
```

**Pros:**
- Full lazygit experience: log, diff, file tree, blame — no custom code
- User can amend commit messages directly inside lazygit before confirming
- The most powerful review experience possible

**Cons:**
- Complex state management (stash, temp branch, cherry-pick, cleanup on abort)
- Requires lazygit to signal back "confirmed" vs "aborted" (can use exit code or a
  sentinel file)
- Risk of leaving repo in intermediate state if something crashes

---

### Option D — Go TUI (bubbletea + lipgloss)

A small Go binary (`~200 LOC`) with full control over layout, borders, and key
bindings. Only justified if Options B/C are insufficient.

**Verdict: overkill for this use case. Revisit if inline message editing is needed.**

---

## Recommendation

| Need | Choice |
|---|---|
| Lazygit users want a keybind to trigger sgc | **Option A** (always add this) |
| `sgc -p` quick inline preview before committing | **Option B** (fzf + bat) |
| Full review + message editing inside lazygit | **Option C** (temp branch) |

**Implement A + B as the default scope.** Option C is a separate feature (`sgc -P` /
`sgc --lazygit`) worth a follow-up iteration.

---

## Implementation plan (Option A + B)

### A — lazygit custom command

1. Add `customCommands` entry to `~/.config/lazygit/config.yml` (or the stowed
   dotfiles equivalent).
2. Keybind `<c-a>` on the `files` context runs `sgc` as subprocess.
3. No changes to `git.zsh`.

### B — `sgc -p` fzf preview

1. **Add `-p / --preview` flag** to `sgc` flag parser.

2. **Write `_sgc_preview_cmd`** helper:
   - Args: `<json_file_path> <index>`
   - Extracts `files[index]` from JSON via python3
   - Prints file summary header (`● file.ts  +N / -N`)
   - Runs `git diff -- <files> | bat --language=diff --style=grid --color=always`

3. **Replace `gum choose`** with fzf when `--preview` is active:
   ```zsh
   selected=$(printf '%s\n' "${labels[@]}" \
     | fzf --ansi --no-sort --multi \
           --prompt '  commit · ' --pointer '→' --marker '✓' \
           --preview "_sgc_preview_cmd $json_tmpfile {n}" \
           --preview-window 'right:62%:wrap' \
           --bind 'ctrl-/:toggle-preview-focus' \
           --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' \
           --header 'tab·select  ctrl-/·focus panel  enter·confirm')
   ```

4. **Wire indices** back into the existing commit-execution loop (unchanged).

5. **Graceful fallback** — no `--preview` flag → identical to current behaviour.

---

## Files to change

| File | Change |
|---|---|
| `git/.zsh/packages/git.zsh` | add `-p` flag, `_sgc_preview_cmd`, swap gum for fzf |
| `lazygit/.config/lazygit/config.yml` | add `customCommands` sgc keybind (new stow pkg if needed) |
