# `zcd` — Alternative Tool Architectures

> Can `yazi`, `broot`, or another modern TUI fully replace the current fzf-based `zcd`?
> This document evaluates each tool against `zcd`'s feature set and proposes concrete alternative architectures.

---

## The Core Tension

`zcd`'s UX flow is:

```
frecency flat list  ──fuzzy filter──▶  select path    (95 % of use)
                          │
                        TAB
                          │
                    navigate mode  ──▶  browse into tree, then select
```

Every native TUI file manager (yazi, broot, lf, nnn, ranger) uses the **opposite** model:

```
root directory  ──tree navigate──▶  select path
                       │
                   fuzzy search within current tree
```

`zcd` is **list-first** (frecency-ranked flat list → fuzzy narrow → done).
Native tools are **tree-first** (start from a dir root, explore downward).

That inversion is the key to understanding which tools can substitute what.

---

## Tool-by-Tool Analysis

### `yazi` (Rust file manager)

| Feature | yazi support |
|---------|-------------|
| Frecency-ordered flat list as starting data | ✗ — always starts from a directory root |
| Fuzzy-filter across flat list | ✗ — search scopes to the current tree |
| TAB toggle: flat list ↔ tree navigation | ✗ — single navigate-only paradigm |
| Tree navigation (up/down/into/back) | ✅ — best-in-class |
| Preview pane (dirs + files + images) | ✅ — best-in-class, supports images |
| Clipboard copy | ✅ via `ya emit copy` |
| ZLE shell integration / cd-on-exit | ✅ via `--chooser-file` |
| Zoxide frecency awareness | ✅ via `zoxide.yazi` plugin (but used for jump-to, not as initial list) |
| Programmable key bindings | ✅ via `keymap.toml` |
| `reload` / `transform` / `rebind` equivalent | ✗ — no fzf-style dynamic action composition |

**Verdict:** yazi cannot replace the frecency flat-list UX. It excels at tree navigation but that is only half of what `zcd` does. It is the **best replacement for the navigate mode** specifically.

---

### `broot` (Rust navigator)

| Feature | broot support |
|---------|--------------|
| Frecency-ordered flat list as starting data | ✗ — scans from a root dir, can sort by access count but not zoxide scores |
| Fuzzy-filter across flat list | ✅ — fuzzy search across the entire tree from any root |
| Tree navigation | ✅ — its primary UI |
| Preview pane | ✅ via `--preview` or `panel_content` |
| Clipboard copy | ✅ via custom verb |
| ZLE shell integration / cd-on-exit | ✅ core feature (`br` shell wrapper writes path, outer shell cd's) |
| Zoxide integration | ✗ — none natively; `br` can call `zoxide add` as a post-hook |
| Custom verbs / scripting | ✅ — powerful verb system |
| Programmatic list injection (like fzf `reload`) | ✗ — always filesystem-backed |

**Verdict:** broot is the closest single-tool replacement but it **fundamentally cannot start from a zoxide frecency list**. The fuzzy search applies to a filesystem tree, not to a ranked flat list. This breaks the core value proposition of `zcd`.

---

### `zoxide zi` (built-in interactive mode)

`zoxide` ships its own interactive mode: `zi` = `zoxide query --interactive`. It pipes the frecency list into `fzf` with no extra features. No preview, no navigate mode, no source toggle. It covers maybe 40 % of `zcd`'s behaviour, which is why `zcd` exists.

---

### `skim` / `tv` / `zellij` / other fzf alternatives

These do not improve the situation for `zcd`:

- **skim** — a Rust fzf clone. Supports `--preview` and `bind`, but `transform:` / `reload` / `rebind`/`unbind` are not implemented. Would require the same workarounds as fzf < 0.38.
- **television (tv)** — powerful source-based picker, but sources are static (no live reload, no in-session state mutation). No `transform:` equivalent.
- **atuin** — shell history search only, unrelated.

**Why `fzf` is irreplaceable here:** the specific combination of `transform:` (run a program and use its stdout as the next action), `reload` (replace the list in place), and `rebind`/`unbind` (dynamically enable/disable keys) is unique to `fzf`. No other picker exposes all three.

---

## Proposed Alternative Architectures

### Architecture A — Keep `fzf`, apply modernization plan *(recommended path)*

No tool change. Apply the improvements from `zcd-modernization-plan.md`:
- Python → awk
- xclip → wl-copy
- 11× mktemp → `mktemp -d` + `trap`
- `--shell zsh` flag

**Pros:** single coherent TUI, seamless TAB toggle, all features intact, minimal change.
**Cons:** the navigate mode (custom stack in temp files) is still weaker than a real file manager.

---

### Architecture B — fzf frecency picker → yazi navigate handoff *(best feature upgrade)*

Redesign `zcd` as **two phases** with `--expect` as the handoff signal.

```zsh
zcd-v2() {
    # Phase 1: frecency + fuzzy in fzf (fast path, covers 95% of use)
    local tmp_chose result exit_key dir

    result=$(
        ( zoxide query -l; fd -td -H -E.git --absolute-path 2>/dev/null ) \
        | awk '!seen[$0]++' \
        | awk -v cwd="$PWD" '{ ... relpath ... }' \
        | fzf --ansi \
              --delimiter=$'\t' --with-nth=2 \
              --expect=ctrl-n \
              --prompt='▌ FRECENCY  ' \
              --header='ENTER: cd  │  CTRL-N: open in yazi  │  CTRL-Y: copy' \
              --preview='[[ -d {1} ]] && eza --tree --level=2 --icons --color=always {1} || bat --style=numbers --color=always {1}' \
              --preview-window=right:60% \
              --bind='ctrl-y:execute-silent(echo -n {1} | wl-copy)' \
              --bind='ctrl-/:toggle-preview'
    )

    exit_key=$(head -1 <<< "$result")
    dir="${ $( tail -1 <<< "$result" ) %%$'\t'*}"

    if [[ "$exit_key" == "ctrl-n" && -n "$dir" ]]; then
        # Phase 2: hand off to yazi for tree navigation
        tmp_chose=$(mktemp)
        yazi --chooser-file="$tmp_chose" "$dir"
        dir=$(cat "$tmp_chose")
        rm -f "$tmp_chose"
    fi

    [[ -n "$dir" ]] && echo "$dir"
}
```

**What this eliminates:**
- The entire dual-mode state machine (no `_modefile`, `_togglescript`, `_stack`, `_curdir`, `_sortfile`)
- `_rightaction`, `_leftaction`, `_rightscript`, `_leftscript` temp files
- The printable-key blocking / `rebind`/`unbind` dance
- 7 of the 11 mktemp calls

**What this gains:**
- yazi's navigate UX is far superior to the custom stack (better keybindings, visual breadcrumbs, multi-pane, image preview)
- The code drops from ~200 lines to ~60
- No fzf version dependency (`transform:` not required)

**Trade-offs:**
- The TAB toggle is no longer seamless; the user exits fzf → yazi opens (two TUI transitions)
- Loses: source toggle (CTRL-Z/CTRL-A) inside the picker; can add a simpler `-z` flag pre-launch
- Loses: in-picker sort toggle; less important if yazi handles navigation
- Requires `yazi` ≥ 0.3 (for `--chooser-file`)

---

### Architecture C — broot only *(for users who don't need frecency)*

Replace `zcd` entirely with a tuned `broot` invocation:

```zsh
zcd-broot() {
    local tmp=$(mktemp)
    br --only-folders --conf ~/.config/broot/zcd.toml --out "$tmp"
    local dir=$(cat "$tmp"); rm -f "$tmp"
    [[ -n "$dir" ]] && echo "$dir"
}
```

With `zcd.toml` configuring:
- `default_flags = "--only-folders --sizes"`
- A verb `cd` that writes the path to `--out`
- A verb `zoxide-add` that calls `zoxide add {directory}`
- Sort by last-access to approximate frecency

**Pros:** native tree navigation, no state management, zero fzf dependency.  
**Cons:** no true zoxide frecency ordering; starts from a root, not from a ranked list; you lose the "type two letters, arrive at the right directory" fast path that is the whole point of `zcd`.

---

## Decision Matrix

| Requirement | Arch A (fzf modern) | Arch B (fzf + yazi) | Arch C (broot) |
|------------|--------------------|--------------------|----------------|
| Frecency flat list as entry point | ✅ | ✅ | ✗ |
| Fuzzy filter across frecency list | ✅ | ✅ | partial |
| Seamless filter ↔ navigate toggle | ✅ | ✗ (two steps) | ✅ (one mode) |
| Navigate quality | fair | ✅ (yazi) | ✅ (broot) |
| Code complexity | high | **low** | low |
| Image preview | ✗ | ✅ (yazi) | ✗ |
| ZLE cd/insert behaviour | ✅ | ✅ | needs work |
| `zoxide add` on navigate | ✅ | ✅ | via verb |
| fzf ≥ 0.38 required | ✅ | ✗ | ✗ |

---

## Recommendation

| If you want… | Choose |
|-------------|--------|
| Zero behaviour change, cleaner internals | **Architecture A** |
| Less code, better navigate UX, image preview, OK with two-step handoff | **Architecture B** |
| No fzf at all, pure native tool | **Architecture C** (but accept losing frecency-first UX) |

Architecture B is the most interesting rewrite: the fzf portion becomes a simple ~40-line frecency picker (no state management), and yazi provides a far better navigate experience than anything achievable inside fzf's bind system. The cost is the seamless TAB toggle — one TUI must close before the other opens.

Architecture A remains the right choice if the single-TUI seamless feel is non-negotiable.

---

## New Dependency Table for Architecture B

| Tool | Purpose |
|------|---------|
| `zoxide` | Frecency list |
| `fd` | Filesystem scan |
| `fzf` | Frecency fuzzy picker (no `transform:` required; any modern version) |
| `awk` | Inline relative-path computation (replaces python3) |
| `yazi` (≥ 0.3) | Navigate mode via `--chooser-file` |
| `eza` | Preview in fzf phase (dirs) |
| `bat` | Preview in fzf phase (files) |
| `wl-copy` | Clipboard (Wayland) |
| `zsh` | Shell host |

---

## Current `zcd` Feature Audit (post-improvements)

The implementation has grown significantly beyond a simple frecency picker. Here is the full feature inventory as it stands today:

### Sources
| Feature | `zcd` |
|---------|-------|
| Zoxide frecency list | ✅ CTRL-Z |
| All dirs (zoxide + fd) | ✅ CTRL-A |
| Smart search (frecency → contents → `$HOME`) | ✅ CTRL-G |
| Auto-selects source based on launch context (`$HOME` → smart, elsewhere → all) | ✅ |
| Source toggle resets navigation state atomically | ✅ |

### Filter mode
| Feature | `zcd` |
|---------|-------|
| Fuzzy filter across flat frecency list | ✅ |
| Relative path display (from launch dir) | ✅ |
| Path-aware fzf scoring (`--scheme=path`) | ✅ |
| Emission-order tiebreak (preserves frecency rank) | ✅ |
| Sort toggle: folders-first ↔ alphabetical | ✅ CTRL-S |
| Clipboard copy of selected path | ✅ CTRL-Y (wl-copy, Wayland-native) |

### Navigate mode
| Feature | `zcd` |
|---------|-------|
| TAB toggle: flat list ↔ tree browse | ✅ |
| Browse into dir | ✅ → / l |
| Go back (history stack) | ✅ ← / h |
| Move up / down | ✅ ↑↓ / k j |
| Printable key blocking while navigating | ✅ (rebind/unbind per toggle) |
| Navigate mode shows match count + query in label | ✅ (live via `result` event) |

### Preview
| Feature | `zcd` |
|---------|-------|
| Directory preview (`eza --tree`) | ✅ |
| File preview (`bat`) | ✅ |
| Toggle preview on/off | ✅ CTRL-/ |
| Toggle pane focus: results ⇄ preview | ✅ CTRL-P |
| Scroll preview | ✅ CTRL-↓/↑ |
| F1 help overlay (replaces preview content) | ✅ |

### Theming
| Feature | `zcd` |
|---------|-------|
| Per-pane border colors (input/results/preview distinct) | ✅ |
| Catppuccin Mocha palette by default | ✅ |
| Named theme variables (`input_color`, `result_color`, `preview_color`) | ✅ |
| Mode-aware accent colors (filter = teal, navigate = yellow) | ✅ (labels + prompts) |
| Pointer color matches preview border | ✅ |
| Icons configurable via named variables | ✅ |

### Shell integration
| Feature | `zcd` |
|---------|-------|
| ZLE widget, bound to Alt-J | ✅ |
| `cd` on directory selection | ✅ |
| Insert path at cursor on file selection | ✅ |
| `zoxide add` on cd | ✅ |

---

## `zcd` vs the Alternatives — Updated Comparison

### Why `zcd` wins for the frecency-first workflow

| Capability | `zcd` | `yazi` | `broot` | `zoxide zi` |
|-----------|-------|--------|---------|-------------|
| Frecency flat list as entry point | ✅ | ✗ | ✗ | ✅ (basic) |
| Multi-source toggle in-session | ✅ | ✗ | ✗ | ✗ |
| Seamless filter ↔ tree in one TUI | ✅ | ✗ | ✗ | ✗ |
| Fuzzy filter across whole frecency list | ✅ | ✗ | partial | ✅ (basic) |
| Tree navigation | ✅ (fzf-based) | ✅ best | ✅ good | ✗ |
| Per-pane theming | ✅ | ✅ | limited | ✗ |
| Preview (dirs + files) | ✅ | ✅ + images | ✅ | ✗ |
| Help overlay | ✅ | ✅ | ✅ | ✗ |
| Copy path to clipboard | ✅ | ✅ | ✅ | ✗ |
| Relative path display | ✅ | ✗ | ✗ | ✗ |
| Smart search (frecency → contents → `$HOME`) | ✅ | ✗ | ✗ | ✗ |
| Single-file, no config, shell-native | ✅ | ✗ (`~/.config/yazi/`) | ✗ (`~/.config/broot/`) | ✅ |
| ZLE cd/insert widget | ✅ | ✅ | ✅ | ✅ |

**The decisive advantage:** no other tool offers the combination of *frecency flat list as the first screen* + *in-session source switching* + *seamless TAB into tree navigation* — all in a single TUI without config files or separate processes. `zcd` directly answers the question "where do I spend most of my time?" before you type a single character.

---

## What Could Still Be Improved

### High priority

| Improvement | Detail |
|-------------|--------|
| **Replace 18 `mktemp` calls with `mktemp -d` + `trap`** | A single temp dir + `trap ... EXIT` eliminates per-file leaks, simplifies cleanup to one `rm -rf`, and removes the 18-variable `rm -f` line |
| **Replace Python relpath script with awk** ✅ | `python3` adds ~80 ms cold-start per reload; awk is a shell built-in alternative with zero startup cost |
| **Preview scrolling via CTRL-D/U** | Comment says CTRL-D/U but binds use `ctrl-down`/`ctrl-up`; align keys or add both |
| **F1 help should temporarily show preview window if hidden** | Currently if preview is hidden (`CTRL-/`), pressing F1 does nothing visible |

### Medium priority

| Improvement | Detail |
|-------------|--------|
| **Navigate mode should restore last query on TAB-back** | After TAB → navigate → TAB → filter, the search query is cleared; `change-query({q})` could restore it |
| **CTRL-Y should work in navigate mode** | Currently the copy bind works but navigate mode blocks it if the path cell isn't focused |
| **Image preview** | `chafa` or `kitten icat` could render images in the preview pane for the file branch |
| **`--shell zsh` flag for fzf** | Makes `--preview` and `--bind` commands run under zsh instead of sh, enabling zsh syntax |

### Low priority / cosmetic

| Improvement | Detail |
|-------------|--------|
| **Theme variables defined inside the function** | Re-evaluated on every call; could be module-level constants |
| **`_h_all/_h_zo/_h_smart` are aliases of `_h1_*`** | The `_h_*` indirection is now unused (headers no longer have a second line); remove |
| **`_list_label_on` and `_list_label_nav_tmpl` defined but never used** | Dead variables left from an older iteration |
