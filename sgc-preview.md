# sgc interactive preview — design plan (v3)

## Goal

Add a `-p / --preview` flag to `sgc` that opens an interactive two-panel UI before
committing, letting the user browse proposed commits and inspect their diffs.

---

## Available tools (installed)

| Tool | Version | Role |
|---|---|---|
| fzf | 0.70.0 | fuzzy list + preview pane |
| lazygit | 0.60.0 | full git TUI, custom commands support |
| bat | 0.26.1 | syntax-highlighted diff rendering |
| go | 1.26.1 | optional: custom TUI binary |
| delta | ✗ | not installed |

---

## External tool comparison

### lazygitrs (Rust rewrite of lazygit)

> https://github.com/blankeos/lazygitrs

A personal Rust rewrite of lazygit with built-in AI commit generation, native
side-by-side diffs, and better navigation UX. Actively developed (v0.0.13, Apr 2026).

**Relevant capabilities:**
- Native `generateCommand` config for AI commit messages — already supports opencode:
  ```yaml
  git:
    commit:
      generateCommand: "opencode run 'Generate a conventional commit message for this diff.'"
  ```
- Side-by-side diffs with syntax highlighting out of the box — no delta/bat needed
- Better diff navigation: `hjkl`, `[]` old/new only views, `{}` hunk travel, mouse scroll
- Command palette, interactive rebase, 30+ themes (sourced from OpenCode)
- 3.24× faster startup than lazygit

**Pros for our use case:**
- Best native diff viewing experience of all options
- Already knows about opencode (uses it in its own README)
- No diff renderer to configure — it's built in

**Cons:**
- Requires replacing lazygit entirely — config drift from upstream is intentional
- `generateCommand` is single-commit only (stages → generate one message → commit)
  It cannot model sgc's core feature: grouping ALL unstaged changes into multiple
  atomic commits with distinct file groupings
- "For me" project — no community guarantees, may break with upstream lazygit config
- Requires Rust/cargo or a prebuilt binary — not in current dotfiles

**Verdict:** Worth watching. Migrate to lazygitrs if you want the best single-commit
AI UX. Does NOT replace sgc's multi-commit grouping workflow.

---

### lgaicm (LazyGit AI Commit Message)

> https://github.com/rakotomandimby/lgaicm

A shell script that hooks into lazygit via `customCommands`. Generates 5–7 AI commit
message suggestions using Google Gemini, then commits the selected one.

**How it works:**
1. User stages files in lazygit, presses `ctrl-a`
2. lazygit runs `lgaicm suggest --type <type>` as subprocess
3. Script calls Gemini API with `git diff --cached`, gets JSON array of suggestions
4. User picks one from a `select` menu
5. lazygit calls `lgaicm commit --file <msg_file>` to finalize

**Pros:**
- Pure shell — zero dependencies beyond `bash`, `curl`, `jq`
- Clean separation: suggest phase → select → commit phase
- Multi-suggestion (5–7 options), supports multi-line commit bodies
- Directly informs our Option A design

**Cons:**
- Hard-coded to Google Gemini — not provider-agnostic
- Generates one message per staged snapshot, not multi-commit grouping
- No diff preview in the selection UI — you pick messages blind
- Requires `GOOGLEAI_API_KEY` — separate credential to manage

**Verdict:** The architecture (suggest + customCommand + select) is the right pattern
for lazygit integration. We already do this better with sgc (multi-provider,
multi-commit planning, caching, retry logic). lgaicm validates the approach but we
don't need to adopt it.

---

### lazygit issue #3212 — native AI commit generation

> https://github.com/jesseduffield/lazygit/issues/3212

Feature request (2024) asking for native AI commit message generation inside lazygit.
**Status: closed** — lazygit addressed it by shipping the `git.commit.generateCommand`
config key, which runs an arbitrary shell command and puts its stdout into the commit
message box.

```yaml
# lazygit config
git:
  commit:
    generateCommand: "opencode run 'Generate a conventional commit message for this diff.'"
```

This is how both lazygitrs and lgaicm hook in. The UX: user stages files, presses `C`
(or configured key) to open commit editor, presses the AI keybind, message is filled.

**Implications for our design:**
- `gc` (single commit) could plug into this natively — no customCommand needed
- `sgc` cannot use `generateCommand` — it creates multiple commits, not one message
- The lazygit community considers this solved via `generateCommand`; a deeper
  multi-commit planning UI has no upstream path in lazygit

---

## Design options (updated)

### Option A — lazygit customCommand for sgc (zero preview code)

```yaml
# ~/.config/lazygit/config.yml
customCommands:
  - key: '<c-a>'
    context: 'files'
    description: 'AI atomic commits (sgc)'
    command: 'sgc'
    subprocess: true
    loadingText: 'sgc: analyzing changes…'
  - key: '<c-g>'
    context: 'files'
    description: 'AI single commit (gc)'
    command: 'gc'
    subprocess: true
    loadingText: 'gc: generating commit message…'
```

User flow: open lazygit → `ctrl-a` → sgc plans + commits → lazygit refreshes.
Diff preview = lazygit's own panels (best diff UI available, especially with
lazygitrs in the future).

| | |
|---|---|
| Diff quality | ★★★★★ (lazygit native) |
| Setup effort | ★★★★★ (config only) |
| Multi-commit support | ★★★★★ |
| Diff visible before commit | ✗ (you see diff in lazygit, but not per-proposed-group) |
| Inline message editing | ✗ |

---

### Option B — fzf + bat preview (`sgc -p`) — **recommended**

fzf 0.70 with `--preview-window` and bat for diff rendering. Covers the full
two-panel layout with togglable focus and scrolling. No new tools needed.

```
 Commits                      │  ● git/.zsh/packages/git.zsh  +48 / -12
──────────────────────────────┤  ──────────────────────────────────────
 → feat(gc): add --debug flag │  @@ -810,6 +810,7 @@
 -  fix: heredoc stdin bug    │   local provider="${GC_PROVIDER:-opencode}"
 -  chore: remove test file   │  +  local debug=0
                              │
                              │  @@ -929,10 +930,24 @@
                              │  -  raw=$(gum spin…
                              │  +  if [[ "$debug" == "1" ]]; then
                              │
                              │           [ctrl-/ focus · ctrl-d/u scroll]
```

| | |
|---|---|
| Diff quality | ★★★★☆ (bat, no side-by-side) |
| Setup effort | ★★★★★ (zsh only) |
| Multi-commit support | ★★★★★ |
| Diff visible before commit | ✓ per proposed commit group |
| Inline message editing | ✗ |
| Focus toggle | ✓ ctrl-/ |
| Scrolling | ✓ ctrl-d/u |

---

### Option C — lazygit temp-branch preview (`sgc --lazygit`)

Create real commits on a temp branch, open lazygit, cherry-pick on confirm.

| | |
|---|---|
| Diff quality | ★★★★★ (lazygit native) |
| Setup effort | ★★☆☆☆ (complex state mgmt) |
| Multi-commit support | ★★★★★ |
| Diff visible before commit | ✓ full lazygit log + diff |
| Inline message editing | ✓ amend in lazygit |
| Risk of broken state | high (stash + branch + cherry-pick) |

---

### Option D — lazygitrs migration

Replace lazygit with lazygitrs. Wire `generateCommand` to `gc` for single commits.
Run `sgc` via `customCommands` (same as Option A). Gain side-by-side diffs, better
navigation, theme picker.

| | |
|---|---|
| Diff quality | ★★★★★ (native side-by-side) |
| Setup effort | ★★★☆☆ (new binary, config migration) |
| Multi-commit support | ★★★★★ (via customCommand) |
| Maintained | personal project, may drift |

---

### Option E — Go TUI (bubbletea)

Custom binary with full layout control. Only justified if B/C/D are insufficient.

**Verdict: overkill. Revisit if inline editing or reordering commits is needed.**

---

## TUI specialist comparison matrix

| Option | Diff quality | No new deps | Multi-commit | Before-commit preview | Inline edit | Complexity |
|---|---|---|---|---|---|---|
| A — lazygit customCmd | ★★★★★ | ✓ | ✓ | ✗ | ✗ | low |
| B — fzf + bat | ★★★★☆ | ✓ | ✓ | ✓ | ✗ | low |
| C — temp branch + lazygit | ★★★★★ | ✓ | ✓ | ✓ | ✓ | high |
| D — lazygitrs migration | ★★★★★ | new binary | ✓ | ✓ | ✓ | medium |
| E — Go TUI | ★★★☆☆ | new binary | ✓ | ✓ | ✓ | high |
| lgaicm pattern | ★★★★★ | ✗ (Gemini) | ✗ | ✗ | ✗ | low |
| lazygitrs generateCmd | ★★★★★ | new binary | ✗ | ✗ | ✓ | medium |

---

## Recommendation

**Implement A + B now. Consider D (lazygitrs) as a longer-term migration.**

| Scenario | Choice |
|---|---|
| You live in lazygit and want to trigger sgc/gc with a key | **A** — add `customCommands` to lazygit config |
| You want `sgc -p` inline diff preview before committing | **B** — fzf + bat, zero new deps |
| You want full review + amend messages before committing | **C** — later, as `sgc --lazygit` |
| You want the best diff UX and are OK switching git TUIs | **D** — lazygitrs migration |

**Why not lgaicm:** we already do everything lgaicm does, better. It validates the
`customCommand` approach but is Gemini-only and single-commit only.

**Why not lazygitrs `generateCommand`:** it covers `gc` (single commit) but cannot
model sgc's multi-commit grouping. The two tools are complementary, not substitutes.

**Key insight:** sgc's unique value — analyzing ALL changes and grouping them into
atomic commits — has no equivalent in any of the tools reviewed. The preview UX
should reinforce that distinction, not replace it with a single-commit flow.

---

## Implementation plan (A + B)

### A — lazygit customCommands

1. Add stow package `lazygit/` to dotfiles with `~/.config/lazygit/config.yml`.
2. Add `customCommands` entries for `sgc` (`ctrl-a`) and `gc` (`ctrl-g`) on `files` context.
3. `subprocess: true` ensures gum/fzf get a real TTY.

### B — `sgc -p` fzf preview

1. **Add `-p / --preview` flag** to `sgc` flag parser.

2. **Write `_sgc_preview_cmd`** — called by fzf for each highlighted commit:
   - Args: `<json_tmpfile_path> <0-based-index>`
   - Extract `files[index]` via python3
   - Print file summary: `● path/to/file.ts  +N / -N`
   - Run `git diff -- <files> | bat --language=diff --style=grid --color=always`

3. **Replace `gum choose`** with fzf when `--preview` is active:
   ```zsh
   selected=$(printf '%s\n' "${labels[@]}" \
     | fzf --ansi --no-sort --multi \
           --prompt '  commit · ' --pointer '→' --marker '✓' \
           --preview "_sgc_preview_cmd '$json_tmp' {n}" \
           --preview-window 'right:62%:wrap' \
           --bind 'ctrl-/:toggle-preview-focus' \
           --bind 'ctrl-u:preview-half-page-up,ctrl-d:preview-half-page-down' \
           --header 'tab·select  ctrl-/·focus  enter·confirm')
   ```

4. **Wire indices** back into existing commit-execution loop (unchanged).

5. **Graceful fallback** — no `--preview` → identical to today.

---

## Files to change

| File | Change |
|---|---|
| `git/.zsh/packages/git.zsh` | add `-p` flag, `_sgc_preview_cmd` helper, swap gum for fzf |
| `lazygit/.config/lazygit/config.yml` | new stow package with `customCommands` for sgc + gc |
