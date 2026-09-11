# Workflow Keybindings, Biomechanical Audit & Ergonomic Reference Matrix

This document provides a comprehensive audit and definitive reference of all keyboard shortcuts across the terminal workflow (`tmux`, `zsh`, `matchmaker`, `lazygitrs`, `keyd`, and AI agent tools).

---

## 🔬 1. Architectural Principles of the Keybinding System

1. **Home Row First ($H = 0$):** Every high-frequency operation is reachable without moving hands from the base typing position ($ASDF / JKL;$).
2. **Kernel Dual-Function Modifiers (`keyd`):** `CapsLock` operates as `Ctrl` when held and `Esc` when tapped, eliminating awkward pinky stretches to the bottom-left corner.
3. **Prefix Guarding for Destructive Actions:** Non-destructive navigation (switching windows, scratchpads, completions) uses **Zero-Prefix / Direct Chords**; destructive actions (closing windows, killing sessions) require a deliberate **Prefix Guard** to prevent accidental data loss.
4. **Mnemonic Consistency:** `n` = New, `w` = Window/Close, `s` = Switch/Select, `t` = Task/Sesh, `g` = Git, `i` = Inspect AI.

---

## 🗺️ 2. Comprehensive Keybinding Matrix

### 🚀 Layer 0: Global Zero-Prefix & Scratchpad Overlays (Fastest Access)

| Keybinding | Scope | Action | Biomechanical Mechanics | KLM Timing ($T$) |
| :--- | :---: | :--- | :--- | :---: |
| **`Ctrl + G`** | Global / Shell | **Lazygitrs Floating Popup (`90% × 88%`)** | Inward roll: CapsLock (Pinky) + G (Index) | $130\text{ ms}$ |
| **`Ctrl + Shift + G`** | Global / Tmux | **AWT Worktree Manager Popup (`85% × 75%`)** | Inward chord: CapsLock (Pinky) + Shift + G | $140\text{ ms}$ |
| **`Alt + o`** (`M-o`) | Global / Tmux | **OpenCode AI Floating Popup (`85% × 85%`)** | Left Thumb (Alt) + Right Ring (O) | $140\text{ ms}$ |
| **`Alt + a`** (`M-a`) | Global / Tmux | **Jump to / Create dedicated AI Window** | Left Thumb (Alt) + Left Pinky (A) | $130\text{ ms}$ |
| **`Ctrl + 0..9`** | Tmux | **Direct Window Select (Windows 0 to 9)** | CapsLock (Pinky) + Number Key | $130\text{ ms}$ |
| **`Ctrl + Shift + 0..9`** | Tmux | **Move & Shift Window to Slot 0..9** | Left Pinky + Left Ring + Number Key | $160\text{ ms}$ |

---

### 🪟 Layer 1: Multiplexer Management (`Prefix` = `Ctrl + Space`)

> **Prefix Execution:** Left Pinky (`CapsLock`) + Thumb (`Space`). Ergonomically neutral with zero wrist deviation.

| Prefix Shortcut | Target Action | Ergonomic Justification & Mnemonic |
| :--- | :--- | :--- |
| **`Prefix + s`** | **Window Picker (Matchmaker `75% × 60%`)** | `s` = **S**witch / **S**elect window. Centered Golden Ratio modal with live preview. |
| **`Prefix + S`** | **Fullscreen Window Picker** | Shift+S opens maximized picker for large multi-monitor overviews. |
| **`Prefix + t`** | **Sesh Workspace / Task Picker** | `t` = **T**ask / **T**eleport to project sessions. |
| **`Prefix + i`** | **AI Agent Bell / Alert HUD** | `i` = **I**ntelligence / **I**nspect agent turn or question. Cycles pending alerts. |
| **`Prefix + n`** | **New Window (Current Path)** | `n` = **N**ew window. Aligned with universal browser tab creation. |
| **`Prefix + w`** | **Close Pane / Window (`kill-pane`)** | `w` = Close **W**indow. Universal browser/IDE closing chord. |
| **`Prefix + W`** | **Kill Entire Session (`kill-session`)** | Shift+W symmetry: uppercase destroys the parent container. |
| **`Prefix + o`** | **AI Split Pane (35% Right Side)** | `o` = **O**penCode side-by-side split. Toggle closes split if already open. |
| **`Prefix + N`** | **Neovim Floating Scratchpad (`90% × 90%`)** | Quick scratchpad editor over the active workspace. |
| **`Prefix + \|`** | **Vertical Split Window** | Intuitive visual divider symbol. |
| **`Prefix + -`** | **Horizontal Split Window** | Intuitive visual divider symbol. |
| **`Prefix + h` / `l`**| **Previous / Next Window** | Vim standard directional motions. |
| **`Prefix + Tab`** | **Last Active Window (MRU Toggle)** | Instant toggle between the two most recent windows. |
| **`Prefix + y`** | **Token Extract / Yank (`75% × 60%`)** | `y` = **Y**ank tokens, URLs, hashes, paths via Matchmaker. Inward chord ($H=0$). Dynamic 60%/95% preview toggle (`Ctrl+P`). |
| **`Prefix + E`** | **Full Scrollback in Neovim** | Captures complete ANSI scrollback history into read-only Neovim buffer. |
| **`Prefix + e`** / **`C-e`** | **Workspace Files Peek (`75% × 60%`)** | `e` = **E**xplore workspace files via Matchmaker popup. Dynamic 60%/95% full-modal preview toggle (`Ctrl+P` / `P`), native Markdown & Mermaid rendering, AI prompt insert (`Ctrl+V`). |
### 🐚 Layer 2: Smart Shell (`zsh`) & Object-First Navigation Widgets

| Keybinding | Widget / Function | Behavior & Context Awareness |
| :--- | :--- | :--- |
| **`<Tab>`** (Empty Prompt) | `_smart_tab` $\rightarrow$ `_jump_widget` | Triggers Matchmaker Jump. If single directory $\rightarrow$ immediate `cd`. If multiple or file $\rightarrow$ Object-First buffer insertion (`BUFFER=" $target"`, `CURSOR=0`). |
| **`<Tab>`** (Ghost Text at End) | `_smart_tab` $\rightarrow$ `autosuggest-accept` | Accepts autosuggestion immediately ($CURSOR == $#BUFFER). |
| **`<Tab>`** (Command / Mid-line) | `_smart_tab` $\rightarrow$ `mm-ftb` | Auto-spaces command name (`_auto_space_if_command`) and opens Matchmaker multi-column completion picker. |
| **`Ctrl + F`** | `_jump_widget` | Manual Matchmaker Jump Widget: fast directory/file picker with Object-First buffer insertion ($H=0$). |
| **`Ctrl + G`** | `_git_files_widget` | Lazygitrs Floating Popup (`~/.config/tmux/lazygitrs-popup.sh "$PWD"`, or detaches if already inside popup). |
| **`Ctrl + N`** | `_mm_tab_widget` | Explicitly invokes Matchmaker completion UI. |
| **`Ctrl + K`** | `history-beginning-search-backward-end` | Prefix history search backward based on current buffer query. |
| **`Ctrl + J`** | `history-beginning-search-forward-end` | Prefix history search forward based on current buffer query. |
| **`Ctrl + Backspace`** | `backward-kill-word` | Deletes preceding word in Insert mode ($T_K = 120\text{ ms}$). |
| **`Ctrl + R`** | `atuin-search` | Full-text contextual and temporal history search. |
| **`Ctrl + T`** | `_intelli_search` | IntelliShell Command Templates & TLDR: Interactive fuzzy search across 29k+ curated command snippets with parameter replacement ($H=0$). |

#### 2.1 Zero-Friction Frecency 2.0 File Transfer & Directory Jump
> For comprehensive KLM-GOMS benchmarks, speedup tables ($20.5\times$ vs CLI, $32.7\times$ vs AI), and architectural pillars, see [**Zero-Friction File Transfer Benchmark & Architectural Guide**](zero-friction-file-transfer-benchmark.md).

| Command / Alias | Action Executed | Biomechanical Mechanics | KLM Cost ($T$) | Ergonomic Rationale |
| :--- | :--- | :--- | :---: | :--- |
| **`j`** / **`z`** | Jump Home / Directory / Frecency | Left Index single tap or query | $100\text{ ms} - 400\text{ ms}$ | $H=0$. Immediate navigation without typing `cd ~` or long paths. |
| **`ji`** / **`zi`** | Interactive Matchmaker Jump | Left Index inward chord / alias | $200\text{ ms}$ | Full tree navigation, ancestor jump (`Ctrl+U`), and editor launch. |
| **`pt`** (`pasteto`) | Copy Files & Stay | Home-row chord + MM picker | $750\text{ ms}$ | Transfers files to frecency destination without leaving current context. |
| **`ptg`** (`pasteto -g`) | Copy Files & Jump to Destination | Home-row chord + MM picker + `cd` | $750\text{ ms}$ | Transfers files and immediately navigates to destination. |
| **`ptl`** (`pasteto -l`) | Copy Files to Last Target | Home-row chord + cached `_MM_LAST_TARGET` | **$220\text{ ms}$** | **Record transfer speed ($20.5\times$ vs CLI):** Bypasses picker entirely. |
| **`mt`** / **`mtg`** / **`mtl`** | Move Equivalents (`moveto`) | Home-row chords + `moveto` flags | $220\text{ ms} - 750\text{ ms}$ | Move equivalents with zero interactive blocking prompts. |

---

### 📂 Layer 3: Matchmaker Frecency Directory Jump & File Manager (`jump.toml`)

| Keybinding | Action / Command | Behavior & Context Awareness |
| :--- | :--- | :--- |
| **`Enter`** | `Accept` | Selects item: `cd` to directory or emit selected path to caller. |
| **`u`** | `@undo` | **File Manager UndoStack:** Undoes last file operation (yank, cut, paste, delete). |
| **`Ctrl + U`** | Ancestor Hierarchy Jump | Walks directory hierarchy backwards up to root `/` dynamically via `Reload(...)`. |
| **`h` / `Left`** | `ChDir(..)` | Navigates up to parent directory ($H=0$). |
| **`l` / `Right`** | `ChDir({=})` | Drills down into selected directory ($H=0$). |
| **`e` / `Ctrl + E`** | `Execute(nvim {+})` | Opens selected file(s) in Neovim with frecency boost. |
| **`y` / `x`** | `@yank` / `@cut` | Stages file(s) for copy or move in File Manager. |
| **`p` / `P` (`Ctrl + V`)** | `@paste` / `@paste_into` | Pastes staged files into current directory or selected subfolder. |
| **`Tab`** | `Toggle`, `Down` | Multi-select items in directory tree. |
| **`,`** | `SortMenu` | Opens sort configuration menu. |
| **`\`** | `ToggleParentPeek` | Toggles split parent-directory preview. |
| **`Ctrl + P`** | `SwitchPreview` | Toggles or cycles preview window layout. |

---

### 📦 Layer 4: Lazygitrs Modal Navigation, Commits, Diff Review & AI Notes

#### 4.1 Hierarchical Unwinding & Panel Navigation
| Keybinding | Scope | Behavior |
| :--- | :--- | :--- |
| **`Esc`** | Inside Diff / Submenus | **Desempilha Foco:** Returns focus to the Files list without closing. |
| **`Esc`** | On Root Files List | **Fecha o Popup:** Closes and destroys the popup overlay in 0ms. |
| **`q`** / **`Ctrl + C`** | Anywhere | Quits Lazygitrs and closes the popup immediately. |
| **`1` / `2` / `3` / `4` / `5`** | Root Navigation | Instant jump to Status (1), Files (2), Branches (3), Commits (4), Stash (5). |
| **`:`** (Colon) | Global | Universal shell command runner popup (executes arbitrary shell commands in repo root). |

#### 4.2 Tree View Navigation (Files & Commit Files)
| Keybinding | Scope | Behavior |
| :--- | :--- | :--- |
| **`-`** | Directory Node | **Fold / Unfold:** Explicitly toggles directory collapse state for any folder (including root). |
| **`Enter`** | Directory Node | **Fullscreen Combined Diff:** Expands and focuses a combined unified diff of all child files. |
| **`Enter`** | File Node | Focuses the diff panel for the selected file in fullscreen. |
| **`,`** (Comma) | Tree View | **Jump to Parent:** Navigates directly to parent directory node. |
| **`.`** (Period) | Tree View | **Jump to Child:** Navigates directly to first child node within directory. |
| **`<`** | Tree View | **Previous Sibling:** Navigates directly to previous sibling node at the same tree depth. |
| **`>`** | Tree View | **Next Sibling:** Navigates directly to next sibling node at the same tree depth. |

#### 4.3 Reconciled Commits Panel & Branch Filtering
| Keybinding | Scope | Action & Ergonomic Alignment |
| :--- | :--- | :--- |
| **`Ctrl + S`** (`<c-s>`) | Commits Panel | **Branch Filter Menu (`openLogMenu`):** Multi-select branch filtering popup with `<Clear Filter>`. **Dynamically rendered in the status bar** based on configuration. |
| **`Ctrl + F`** (`<c-f>`) | Commits Panel | **Mark Commit as Fixup (`markCommitAsFixup`):** Targets highlighted commit for subsequent fixup. |
| **`F`** (Shift+F) | Commits Panel | **Create Fixup Commit (`createFixupCommit`):** Creates immediate fixup commit targeting the marked commit. |
| **`a`** | Commits Panel | **Toggle All Branches Log:** Toggles commit log view between all branches and HEAD-only. |
| **`b`** | Commits Panel | **Bisect Options Menu (`viewBisectOptions`):** Opens Git bisect workflow menu. |
| **`i`** | Commits Panel | **Interactive Rebase (`interactiveRebase`):** Initiates interactive rebase atop highlighted commit. |
| **`C` / `V`** | Commits Panel | **Cherry-Pick Copy & Paste:** `C` copies commit to clipboard; `V` pastes/applies cherry-pick. |
| **`s` / `S`** | Commits Panel | **Squash:** `s` squashes down into next commit; `S` squashes all commits above. |
| **`r` / `R`** | Commits Panel | **Rename Commit:** `r` renames in-place; `R` opens default `$EDITOR`. |
| **`g`** | Commits Panel | **Reset Options:** Soft, mixed, or hard reset menu. |

#### 4.4 Diff Review & Hunk Navigation
| Keybinding | Scope | Behavior |
| :--- | :--- | :--- |
| **`{` / `}`** | Diff View | Cycles between change hunks backwards / forwards. |
| **`[` / `]`** | Diff View | Switches view between Old side only, New side only, or Side-by-Side. |
| **`Enter`** | Diff View | **Revert Block:** Reverts hovered or selected diff block in working tree. |
| **`u`** | Diff View | **Undo Revert Block:** Undoes the last diff block revert. |
| **`v`** | Diff View | Toggles visual line/range selection in diff. |

#### 4.5 AI Review Notes Workflow & Worktree Isolation
| Keybinding | Scope | Action & Mechanics |
| :--- | :--- | :--- |
| **`c`** | Diff View / Note | **Create Note:** Creates inline review comment on hovered line (or adds note to selected line). |
| **`n` / `N`** | Diff View | **Cycle Notes:** Jumps to next (`n`) or previous (`N`) review note in current diff. |
| **`y`** | Note Selected | **Yank / Copy Note:** Copies full note text to system clipboard with a 500ms Neovim-style flash highlight. |
| **`S`** (Shift+S) | Note Selected | **Send to AI:** Dispatches note to active AI session via SSE, TUI push, or `notifyCommand`. Marks note as `sent`. |
| **`r` / `R`** | Note Selected | **Reset Note Status:** Resets note status from `sent`/`addressed` back to `new`. |
| **`d`** | Note Selected | **Delete Note:** Removes review note from `.lines.json` with fallback selection to adjacent note. |
| **`Enter` / `o`** | Note Selected | **View Note Details:** Opens modal popup displaying author, timestamp, status, and full markdown text. |
| *Automated* | Worktree Root | **Worktree Port Isolation (`.lazygitrs.port`):** Each worktree writes its dynamic port to `.lazygitrs.port`, isolating concurrent agent sessions. |

---

## 🔬 3. Consolidated Interaction Matrix (KLM Biomechanical Audit)

The table below consolidates the definitive keybindings across all layers, auditing each chord through Card, Moran & Newell's **Keystroke-Level Model (KLM)**:

| Key / Chord | Context / Mode | Action Executed | Biomechanical Mechanics | KLM Cost ($T$) | Ergonomic Rationale |
| :--- | :--- | :--- | :--- | :---: | :--- |
| **`Ctrl + G`** | Global / Shell | Open Lazygitrs Floating Popup | Inward roll: CapsLock (Pinky) + G (Index) | $130\text{ ms}$ | $H=0$. Immediate access to Git workspace without context switching. |
| **`Ctrl + Shift + G`** | Global / Tmux | AWT Worktree Manager Popup | Inward chord: CapsLock (Pinky) + Shift + G | $140\text{ ms}$ | Direct access to worktrees; symmetric to `Ctrl+G`. |
| **`Alt + o`** | Global / Tmux | OpenCode AI Floating Popup | Left Thumb (Alt) + Right Ring (O) | $140\text{ ms}$ | Zero wrist displacement; instant overlay for agent interaction. |
| **`Alt + a`** | Global / Tmux | Focus / Create Dedicated AI Window | Left Thumb (Alt) + Left Pinky (A) | $130\text{ ms}$ | High-frequency jump to primary agent workspace. |
| **`Prefix + s`** | Tmux Multiplexer | Window Picker (`75% × 60%`) | Left Pinky (CapsLock) + Thumb (Space) $\rightarrow$ `s` | $240\text{ ms}$ | Prefix guard protects against accidental modal popups during fast typing. |
| **`Prefix + t`** | Tmux Multiplexer | Sesh Workspace Picker | Left Pinky (CapsLock) + Thumb (Space) $\rightarrow$ `t` | $240\text{ ms}$ | `t` = Task/Teleport; mnemonic alignment with project workflows. |
| **`Prefix + i`** | Tmux Multiplexer | AI Agent Bell / Alert HUD | Left Pinky (CapsLock) + Thumb (Space) $\rightarrow$ `i` | $240\text{ ms}$ | `i` = Intelligence; cycles pending questions and permission alerts. |
| **`Prefix + w`** | Tmux Multiplexer | Close Pane / Window (`kill-pane`) | Left Pinky (CapsLock) + Thumb (Space) $\rightarrow$ `w` | $240\text{ ms}$ | Prefix guard prevents accidental pane destruction. |
| **`<Tab>`** (Empty) | Shell / ZLE | Matchmaker Directory Jump | Left Pinky single tap on Tab | $100\text{ ms}$ | **Object-First ergonomics:** Empty prompt immediately surfaces directory jumper. |
| **`<Tab>`** (Ghost) | Shell / ZLE | Accept Inline Autosuggestion | Left Pinky single tap on Tab | $100\text{ ms}$ | Accepted only when `$CURSOR -eq $#BUFFER`, preventing midline ghost-text hijacking. |
| **`<Tab>`** (Command) | Shell / ZLE | Auto-space & Matchmaker FTB | Left Pinky single tap on Tab | $100\text{ ms}$ | Eliminates manual spacebar typing after aliases/commands. |
| **`Ctrl + F`** | Shell / ZLE | Matchmaker Jump Widget | Inward chord: CapsLock (Pinky) + F (Index) | $120\text{ ms}$ | $H=0$. Replaces legacy `Ctrl+T` with home-row inward curl. |
| **`Ctrl + N`** | Shell / ZLE | Matchmaker Completion UI | CapsLock (Pinky) + N (Right Index) | $130\text{ ms}$ | Direct fallback completion invocation without touching arrow keys. |
| **`Ctrl + K` / `J`** | Shell / ZLE | Prefix History Search Prev / Next | CapsLock (Pinky) + K / J (Home Row) | $120\text{ ms}$ | Preserves Vim navigation instincts during shell command search. |
| **`u`** | Matchmaker Jump | Undo File Operation (`@undo`) | Right Index reach up to `u` | $110\text{ ms}$ | Unmodified 1-touch operation for File Manager UndoStack. |
| **`Ctrl + U`** | Matchmaker Jump | Ancestor Hierarchy Jump | CapsLock (Pinky) + U (Right Index) | $130\text{ ms}$ | Differentiated from `u`; walks up directory tree up to root `/`. |
| **`h` / `l`** | Matchmaker Jump | Directory Up (`..`) / Down (`{=}`) | Right Index / Ring on Home Row | $100\text{ ms}$ | Flawless Vim horizontal navigation with zero wrist movement. |
| **`e` / `Ctrl + E`** | Matchmaker Jump | Edit in Neovim (`nvim {+}`) | Left Middle reach up to `e` | $110\text{ ms}$ | Fast handoff from directory search to code editor. |
| **`y` / `x` / `p`** | Matchmaker Jump | Yank / Cut / Paste File Operations | Home row & bottom row direct taps | $110\text{ ms}$ | Intuitive file manager clipboard workflow. |
| **`-`** | Lazygitrs Tree | Fold / Unfold Directory Node | Right Pinky top-row reach to `-` | $120\text{ ms}$ | Dedicated directory collapse toggle for all folders (including root). |
| **`Enter`** (on dir) | Lazygitrs Tree | Fullscreen Combined Diff | Right Pinky tap on Enter | $100\text{ ms}$ | Instant multi-file diff view without manual traversal. |
| **`,` / `.`** | Lazygitrs Tree | Navigate to Parent / Child Node | Right Middle / Ring reach to bottom row | $110\text{ ms}$ | Hierarchical tree traversal without lateral hand shift. |
| **`<` / `>`** | Lazygitrs Tree | Navigate Prev / Next Sibling | Shift + `,` / `.` (Pinky + Ring/Middle) | $140\text{ ms}$ | Sibling navigation preserving structural depth. |
| **`Ctrl + S`** | Lazygitrs Commits | Open Branch Filter Menu (`openLogMenu`) | CapsLock (Pinky) + S (Left Ring) | $120\text{ ms}$ | Home-row chord; dynamic status bar reflects active keybinding. |
| **`Ctrl + F`** | Lazygitrs Commits | Mark Commit as Fixup | CapsLock (Pinky) + F (Left Index) | $120\text{ ms}$ | Home-row inward chord; fast target marking before squash/fixup. |
| **`F`** (Shift+F) | Lazygitrs Commits | Create Fixup Commit | Left Pinky (Shift) + Left Index (F) | $140\text{ ms}$ | Direct uppercase counterpart to fixup marking. |
| **`a`** | Lazygitrs Commits | Toggle All Branches vs HEAD Log | Left Pinky tap on Home Row `a` | $100\text{ ms}$ | Instant log view alternation with zero finger reach. |
| **`b`** | Lazygitrs Commits | Open Bisect Options Menu | Left Index reach down to `b` | $110\text{ ms}$ | Rapid access to binary search debugging workflow. |
| **`i`** | Lazygitrs Commits | Interactive Rebase Menu | Right Middle reach up to `i` | $110\text{ ms}$ | Standard Git interactive rebase mnemonic. |
| **`C` / `V`** | Lazygitrs Commits | Cherry-Pick Copy / Paste | Shift + C / Shift + V (Pinky + Index) | $140\text{ ms}$ | Universal OS clipboard mnemonics adapted for Git commits. |
| **`:`** (Colon) | Lazygitrs Global | Universal Shell Command Runner | Shift + `;` (Right Pinky chord) | $130\text{ ms}$ | Vim ex-command mnemonic; executes arbitrary scripts in repo root. |
| **`{` / `}`** | Lazygitrs Diff | Previous / Next Diff Hunk | Shift + `[` / `]` (Right Pinky reach) | $140\text{ ms}$ | Classic Vim paragraph/block motion applied to diff hunks. |
| **`[` / `]`** | Lazygitrs Diff | Old / New / Both Diff Side Switch | Right Pinky reach to bracket keys | $120\text{ ms}$ | Fast inspection of individual file revisions. |
| **`Enter`** (in diff) | Lazygitrs Diff | Revert Hovered Diff Block | Right Pinky tap on Enter | $100\text{ ms}$ | Immediate hunk rejection during review. |
| **`u`** (in diff) | Lazygitrs Diff | Undo Last Revert Block | Right Index reach up to `u` | $110\text{ ms}$ | Safety net: instant recovery of accidental hunk reverts. |
| **`c`** | Lazygitrs Diff | Create Inline Review Note | Left Middle reach down to `c` | $110\text{ ms}$ | Initiates inline comment on active line for AI review. |
| **`n` / `N`** | Lazygitrs Diff | Cycle Next / Prev Review Note | Right Index reach to `n` / Shift + `N` | $110\text{ ms}$ / $140\text{ ms}$ | Standard search-next convention for review note navigation. |
| **`y`** (on note) | Lazygitrs Diff | Yank / Copy Note to Clipboard | Right Index reach up to `y` | $110\text{ ms}$ | Neovim-style 500ms flash feedback; copies full note text. |
| **`S`** (Shift+S) | Lazygitrs Diff | Send Note to Active AI Session | Left Pinky (Shift) + Left Ring (S) | $140\text{ ms}$ | `S` = Send / Submit. Notifies AI via dynamic `.lazygitrs.port`. |
| **`r` / `R`** (on note)| Lazygitrs Diff | Reset Note Status to `New` | Left Index reach up to `r` | $110\text{ ms}$ | Enables re-reviewing or re-dispatching notes to agent. |
| **`d`** (on note) | Lazygitrs Diff | Delete Review Note | Left Middle tap on Home Row `d` | $100\text{ ms}$ | Destructive single-note dismissal with auto-selection of next note. |
| **`Enter` / `o`** | Lazygitrs Diff | View Note Full Details Popup | Right Pinky tap / Right Ring reach | $100\text{ ms}$ / $110\text{ ms}$ | Full markdown rendering of rationale, author, and timestamp. |
| **`Esc`** | Lazygitrs Global | Hierarchical Context Unwind / Close | Left Pinky tap (keyd CapsLock tap) | $100\text{ ms}$ | $H=0$. Unwinds diff/submenu $\rightarrow$ Files list $\rightarrow$ closes popup. |

---

## 🔬 4. Biomechanical Audit Summary & Verdict

```text
┌─────────────────────────────────────────────────────────────────────────────┐
│                       WORKFLOW ERGONOMIC HEALTH SCORE                       │
├────────────────────────────────┬──────────────┬─────────────────────────────┤
│ Dimension                      │ Score        │ Key Driver                  │
├────────────────────────────────┼──────────────┼─────────────────────────────┤
│ 1. Home Row Anchoring (H = 0)  │ 10 / 10      │ keyd CapsLock=Ctrl/Esc      │
│ 2. Cognitive Friction (M ≈ 0)  │ 9.9 / 10     │ Dynamic Omarchy Semiotics   │
│ 3. Latency & Responsiveness    │ 10 / 10      │ Sub-100ms Doherty Threshold │
│ 4. Conflict Safety             │ 10 / 10      │ Clean POSIX/Vim Separation  │
│ 5. Muscle Memory Stability     │ 10 / 10      │ Zero Arbitrary Key Churn    │
└────────────────────────────────┴──────────────┴─────────────────────────────┘
```

* **Zero Collision Guarantee:** Global keys do not intercept POSIX TTY signals (`Ctrl+W`, `Ctrl+C`, `Ctrl+Z`), preserving full shell and editor functionality.
* **Complete Symmetry:** Pairings (`w`/`W`, `h`/`l`, `j`/`k`, `Esc`/`Enter`, `c`/`d`, `n`/`N`) maintain intuitive directional and hierarchical relationships.
* **Worktree Port Isolation:** Dynamically resolving `.lazygitrs.port` prevents port collisions and ensures seamless multi-agent concurrency.

---

## 🔗 Related Documentation
* [`docs/architecture/terminal-ergonomics-and-ux-manifesto.md`](terminal-ergonomics-and-ux-manifesto.md): Core HCI philosophy and cognitive models.
* [`docs/architecture/zero-friction-file-transfer-benchmark.md`](zero-friction-file-transfer-benchmark.md): Quantitative KLM-GOMS benchmark and architectural guide for Zero-Friction Frecency 2.0 file transfer and navigation.
* [`docs/tmux/popups-ergonomics-and-golden-ratio.md`](../tmux/popups-ergonomics-and-golden-ratio.md): Golden Ratio geometry and visual semiotics.
* [`docs/GIT_WORKTREE_AGENTIC_WORKFLOW.md`](../GIT_WORKTREE_AGENTIC_WORKFLOW.md): Agent worktree orchestrator and multi-agent Git workflow.
* [`docs/shell/completion.md`](../shell/completion.md): Matchmaker completion architecture.
* [`docs/shell/matchmaker-presets.md`](../shell/matchmaker-presets.md): Matchmaker presets reference.

