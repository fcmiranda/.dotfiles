# Navigation & Completion Analysis

> Stack: zsh + vi-mode + autosuggestions + fzf + fzf-tab + zoxide + atuin + yazi + sesh + tmux
> Last updated: 2026-04-17 — reflects all implemented improvements

---

## 1. Architecture

```
┌─────────────────────────────────────────────────────────────────┐
│  PROMPT INPUT                                                   │
│                                                                 │
│  Ghost text ◄─── zsh-autosuggestions                           │
│                  strategy: history → completion fallback        │
│                                                                 │
│  Tab ──────────► _smart_tab widget                             │
│                  ├─ buffer="j"          → zcd (zoxide nav)     │
│                  ├─ LBUFFER ends " "    → fzf-tab complete     │
│                  ├─ $POSTDISPLAY set    → autosuggest-accept   │
│                  └─ (else)             → fzf-tab complete      │
│                                                                 │
│  ↑/↓  CTRL-K/J ► history-beginning-search (prefix-filtered)   │
│  CTRL-R ────────► atuin (SQLite, cross-session, fuzzy)         │
│  ALT-f ─────────► autosuggest-forward-word (one word at a time)│
│  ALT-J ─────────► zcd (zoxide + fd, multi-mode navigator)      │
│  ALT-C ─────────► fzf cd (plain fd, no zoxide ranking)         │
│  CTRL-T ────────► fzf paste file/dir path                      │
│  **<Tab> ───────► fzf inline expansion (already active)        │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  HISTORY LAYER                                                  │
│                                                                 │
│  ~/.zsh_history   HISTSIZE/SAVEHIST=50000                       │
│  INC_APPEND + SHARE_HISTORY → real-time cross-session sync     │
│  Atuin SQLite  → CTRL-R, independent of zsh history            │
│  Both sources  → arrows use zsh history; CTRL-R uses atuin     │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  FILE SYSTEM LAYER                                              │
│                                                                 │
│  yazi / y() ────► TUI file manager, cd synced back to shell    │
│  zcd ────────────► fzf+zoxide navigator (4 modes)              │
│  fcd / fe ──────► fzf utility functions (cd / open in editor)  │
└─────────────────────────────────────────────────────────────────┘

┌─────────────────────────────────────────────────────────────────┐
│  SESSION LAYER (tmux)                                           │
│                                                                 │
│  sesh ──────────► unified picker: sessions + windows + zoxide  │
│  CTRL-Space K/P/T → popup session switchers                    │
│  CTRL-Space Y/G/N/B → popup yazi/lazygit/nvim/btop             │
│  CTRL-0..9 ─────► direct window select (no prefix)             │
└─────────────────────────────────────────────────────────────────┘
```

---

## 2. Complete Keybind Reference

### Shell prompt — vi insert mode

| Trigger | Condition | Effect |
|---|---|---|
| `Tab` | buffer = `j` | zcd navigator |
| `Tab` | LBUFFER ends with space | fzf-tab completion |
| `Tab` | `$POSTDISPLAY` non-empty | accept autosuggestion |
| `Tab` | else (no ghost text, no space) | fzf-tab completion |
| `ALT-f` | ghost text visible | accept one word of suggestion |
| `ALT-→` | ghost text visible | accept one word of suggestion |
| `ALT-J` | always | zcd navigator |
| `ALT-C` | always | fzf cd (plain fd, no zoxide) |
| `CTRL-T` | always | fzf paste file or dir path |
| `CTRL-R` | always | atuin history search |
| `↑` / `CTRL-K` | always | history-beginning-search-backward (prefix-filtered) |
| `↓` / `CTRL-J` | always | history-beginning-search-forward (prefix-filtered) |
| `CTRL-←` | always | backward-word |
| `CTRL-→` | always | forward-word |
| `CTRL-Backspace` | always | backward-kill-word |

> **`**<Tab>` inline expansion** is also active everywhere:
> `vim **<Tab>` → fzf file picker; `cd ~/proj/**<Tab>` → fzf scoped to that dir

### Inside zcd (ALT-J / `j`+Tab)

| Key | Mode | Effect |
|---|---|---|
| `Tab` | any | Toggle filter ↔ navigate |
| `CTRL-G` | any | Smart mode (frecency → contents → $HOME) |
| `CTRL-A` | any | All dirs (zoxide + fd) |
| `CTRL-Z` | any | Zoxide-only source |
| `CTRL-/` | any | Toggle preview pane |
| `CTRL-Y` | any | Copy path to clipboard |
| `CTRL-S` | any | Toggle sort order |
| `→` / `l` | navigate | Enter directory |
| `←` / `h` | navigate | Go back |
| `↓` / `j` | navigate | Move down |
| `↑` / `k` | navigate | Move up |
| `F1` | any | Show all shortcuts help |
| `ENTER` | any | cd + zoxide add |
| `ESC` | any | Cancel |

### Inside yazi (`y`)

| Key | Effect |
|---|---|
| `CTRL-T` | fd+fzf file picker → reveal in yazi |
| `ALT-C` | fd+fzf dir picker → cd + zoxide add |
| `CTRL-J` | zoxide list → fzf → cd |

### vi normal/visual mode — text objects

| Object | Effect |
|---|---|
| `ib` / `ab` | inside / around innermost bracket `( [ { <` |
| `iq` / `aq` | inside / around innermost quote `" ' \`` |

### Tmux (prefix = `CTRL-Space`)

| Key | Effect |
|---|---|
| `K` | Sesh picker (gum, minimal) |
| `P` | Sesh picker (fzf popup 80%) |
| `T` | Sesh picker (fzf-tmux 80%×70%) |
| `Y` | Yazi popup (90%) |
| `G` | Lazygit popup (90%) |
| `N` | Nvim popup (90%) |
| `B` | Btop popup (90%) |
| `\|` / `-` | Split vertical / horizontal |
| `l` / `h` | Next / previous window |
| `Tab` | Last window |
| `x` | Kill pane |
| `CTRL-0..9` | Direct window select (no prefix needed) |

---

## 3. History System — Dual Layer

One of the most important architectural decisions is having **two separate history stores** that serve different roles:

```
zsh native history (~/.zsh_history)       atuin (~/.local/share/atuin/history.db)
─────────────────────────────────────     ────────────────────────────────────────
↑/↓ arrows (prefix-filtered)              CTRL-R (fuzzy, full-text)
autosuggestions ghost text                timestamps, exit codes, cwd context
history-beginning-search                  deduplication across machines (sync)
cross-session via SHARE_HISTORY           session/host/dir filter modes
50,000 entry limit                        unlimited SQLite
```

Key `setopt` flags in `history.zsh`:
- `INC_APPEND_HISTORY` — writes every command immediately (not on shell exit)
- `SHARE_HISTORY` — all open terminals read/write the same file in real time
- `HIST_IGNORE_ALL_DUPS` — deduplicates, keeps most recent occurrence
- `HIST_IGNORE_SPACE` — prefix command with space to keep it out of history
- `EXTENDED_HISTORY` — stores `: <timestamp>:<duration>;<command>` format

---

## 4. Tab Decision Tree

```
Tab pressed
│
├─ BUFFER == "j"
│   └─► zcd (zoxide navigator, full multi-mode UI)
│
├─ LBUFFER ends with " "
│   └─► fzf-tab (argument completion with eza/bat preview)
│       examples: "git " → branch/subcommand list
│                 "cd "  → directory list with tree preview
│                 "vim " → file list with bat preview
│
├─ $POSTDISPLAY non-empty  (ghost text is visible)
│   └─► autosuggest-accept (accept entire ghost text)
│       → then use ALT-f to have accepted only one word
│
└─ (else: typed "git com", no ghost text yet)
    └─► fzf-tab (treat as completion request)
        → triggers zsh completion engine + fzf UI
```

---

## 5. Autosuggestion Flow

```
You type: "git com"
    │
    ▼
zsh-autosuggestions checks strategy in order:
    1. history   → scan ~/.zsh_history for prefix match
    2. completion → ask zsh completion engine if no history match
    │
    ├─ match found → ghost text rendered (dim color after cursor)
    │                Tab accepts all / ALT-f accepts one word
    │
    └─ no match   → no ghost text
                    Tab → fzf-tab opens completion UI instead
```

---

## 6. FZF Ecosystem Map

| Shortcut | Source | Filter | Output |
|---|---|---|---|
| `CTRL-T` | `fd` files+dirs, hidden | fzf | paste path to prompt |
| `ALT-C` | `fd` dirs, hidden | fzf + eza preview | cd |
| `ALT-J` / `j<Tab>` | zoxide + fd | fzf multi-mode | cd |
| `CTRL-R` | atuin DB | fzf / atuin UI | execute command |
| `Tab` (trailing space) | zsh completion | fzf-tab + eza/bat | complete argument |
| `**<Tab>` | fd (inline) | fzf | insert path at cursor |
| `fe` | fd files | fzf + bat preview | open in $EDITOR |
| `fcd` | fd dirs | fzf + eza preview | cd |
| `fkill` | ps -ef | fzf | kill process |
| `fbr` | git branches | fzf | git checkout |
| yazi `CTRL-T` | fd files | fzf | reveal in yazi |
| yazi `ALT-C` | fd dirs | fzf | cd + zoxide add |
| yazi `CTRL-J` | zoxide list | fzf | cd |

---

## 7. Strengths — Current State

| Area | Status | Detail |
|---|---|---|
| Tab routing | ✅ Solid | 4-branch decision covers all cases, no dead presses |
| Ghost text | ✅ Solid | history + completion fallback, nearly always present |
| Word acceptance | ✅ Solid | ALT-f / ALT-→ for word-by-word |
| History arrows | ✅ Solid | prefix-filtered, cross-session via SHARE_HISTORY |
| History search | ✅ Excellent | Atuin — dedup, timestamps, fuzzy, session/dir filters |
| Directory nav | ✅ Excellent | zcd with 4 modes is best-in-class above plain `zi` |
| Completion UI | ✅ Excellent | fzf-tab + eza/bat preview + hidden files shown |
| File manager | ✅ Excellent | yazi + cwd sync back to shell on exit |
| Session mgmt | ✅ Excellent | sesh unifies tmux sessions + windows + zoxide dirs |
| vi text objects | ✅ Strong | extended with `ib/ab/iq/aq` for any bracket/quote |
| ALT-C vs ALT-J | ⚠️ Redundant | ALT-C is strictly weaker than zcd — see §8 |
| fzf-tab switch-group | ⚠️ Minor | `< >` keys work but are visually confusing in docs |

---

## 8. Remaining Open Questions

### 8.1 ALT-C is redundant with ALT-J
`ALT-C` calls plain `fd --type d` → fzf. `ALT-J` calls zcd which does the same plus zoxide ranking, navigate mode, multi-source switching, and preview. There is no scenario where you'd prefer ALT-C over ALT-J.

**Options:**
- **Remap** `ALT-C` → `_zcd_widget` (single mental model)
- **Repurpose** `ALT-C` to mean "search only in current dir" vs `ALT-J` global

### 8.2 `j word<Tab>` could pre-filter zcd
Typing `j dotfiles<Tab>` today: the `j` prefix handler only matches `BUFFER == "j"` exactly, so it accepts the autosuggestion instead. A pre-filter handler would open zcd with `dotfiles` as the initial fzf query.

### 8.3 fzf-tab switch-group keys
`< >` work but read as redirection operators in documentation. `[ ]` or `, .` are less ambiguous.
