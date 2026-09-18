# Master Keybindings & Kinetic Interaction Matrix

## 1. Biomechanical Axioms

1. **Strict Home Row Anchoring ($H = 0$):** Hands remain permanently anchored to the standard home row positions ($ASDF / JKL;$).
2. **MacBook Ergonomics - No `Alt/Option`:** `Alt` on Apple keyboards requires forced thumb adduction and ulnar wrist deviation. `Alt` chords are strictly banned.
3. **`keyd` Dual-Function Overload:** Physical `CapsLock` is overloaded via the kernel:
   - `Tap` $\to$ `Esc` (120ms single cycle)
   - `Hold` $\to$ `Ctrl` (0 wrist angle deviation)
4. **Seamless Traversal:** Directional keys (`h/j/k/l` or `Ctrl+H/J/K/L`) work identically whether input query has focus or result list has focus. Mode traps are eliminated.
5. **Zero Churn Principle:** Established muscle memory is an inviolable biological asset. Never rebind working shortcuts.

---

## 2. Multi-Layer Interaction Matrix

### A. Global & Desktop (Hyprland / Kernel)
| Key / Chord | Target Layer | Executed Action | Kinetic Mechanics | Ergonomic Rationale |
| :--- | :---: | :--- | :--- | :--- |
| **`CapsLock` (Tap)** | Global | `Esc` / Cancel / Unwind | Single pinky tap | 0 hand movement ($H=0$) |
| **`CapsLock` (Hold)** | Global | `Ctrl` Modifier | Left pinky hold | Zero ulnar deviation |
| **`Super + Return`** | Hyprland | Open Terminal (Ghostty) | Right thumb + Right pinky | Inward bilateral roll |
| **`Super + Space`** | Hyprland | Application Launcher | Right thumb + Left thumb | Dual thumb tap |

### B. Shell & ZLE Widgets (Zsh)
| Key / Chord | Target Layer | Executed Action | Kinetic Mechanics | Ergonomic Rationale |
| :--- | :---: | :--- | :--- | :--- |
| **`j + Enter`** | Zsh Buffer | Jump to `$HOME` (`cd ~`) | Inward bilateral roll | Sacred muscle memory (<100ms) |
| **`j <query>`** | Zsh Buffer | Smart Frecency Jump | Home row typing | Instant match resolution |
| **`Tab` (Empty Prompt)** | ZLE | Matchmaker `jump` Picker | Left pinky tap | Object-First workflow |
| **`ptl` / `mtl`** | Zsh Buffer | Paste/Move to Last Target | 3 direct home-row keystrokes | Reuses `_MM_LAST_TARGET` |
| **`ptg` / `mtg`** | Zsh Buffer | Paste/Move & Change Directory | 3 keystrokes + fuzzy query | Eliminates separate `cd` |
| **`pt` / `mt`** | Zsh Buffer | Paste/Move in Current Working Dir | 2 keystrokes + fuzzy query | Preserves working directory |

### C. Tmux & Popups
| Key / Chord | Target Layer | Executed Action | Kinetic Mechanics | Ergonomic Rationale |
| :--- | :---: | :--- | :--- | :--- |
| **`Ctrl+Space`** | Tmux | Tmux Prefix Key | Left pinky (`CapsLock`) + Thumb | Natural hand posture |
| **`prefix + s`** | Tmux | Sesh Session Picker Popup | Prefix + Left ring finger | Quick context switching |
| **`Ctrl+G`** | Tmux / Zsh | Lazygitrs Dedicated Popup | Left pinky (`CapsLock`) + Left index | Rapid inward chord |
| **`Esc` / `q`** | Tmux Popup | Close / Dismiss Popup | Left pinky tap | Instant modal unwinding |

### D. Matchmaker & File Manager (`fm.rs`)
| Key / Chord | Target Layer | Executed Action | Kinetic Mechanics | Ergonomic Rationale |
| :--- | :---: | :--- | :--- | :--- |
| **`Ctrl+L` / `l`** | Matchmaker | Enter Directory (`ChDir`) | Right index or Left pinky+Right ring | Seamless traversal |
| **`Ctrl+H` / `h`** | Matchmaker | Ascend to Parent (`ChDir ..`) | Right index or Left pinky+Right index| Seamless traversal |
| **`Ctrl+U`** | Matchmaker | Ancestor Jump (Multi-level ascent)| Inward roll (`CapsLock + U`) | Multi-level root jump |
| **`u`** | `fm.rs` | Undo Last File Operation | Right index tap | File Manager UndoStack rollback |
| **`f` / `Ctrl+F`** | Matchmaker | Cycle Source (Local/Frec/Bookmark)| Left index tap | Instant dataset switching |
| **`y` / `x` / `p`** | `fm.rs` | Yank / Cut / Paste Files | Pure Vim standard verbs | Zero cognitive load |
| **`a` / `r` / `d`** | `fm.rs` | Add / Rename / Delete (Trash) | Pure Vim standard verbs | Direct in-place file operations |

### E. Lazygitrs (Dual-Diff & Worktrees)
| Key / Chord | Target Layer | Executed Action | Kinetic Mechanics | Ergonomic Rationale |
| :--- | :---: | :--- | :--- | :--- |
| **`Ctrl+G`** | Lazygitrs | Toggle Dual-Diff (`Files` $\leftrightarrow$ `HEAD`)| Inward roll (`CapsLock + G`) | Single-touch diff flip |
| **`Ctrl+S`** | Lazygitrs | Open Commit Log / Filter Menu | Inward roll (`CapsLock + S`) | Left hand home row chord |
| **`Ctrl+F`** | Lazygitrs | Mark Commit as Fixup | Inward roll (`CapsLock + F`) | Left hand home row chord |
| **`-`** | Lazygitrs | Fold / Unfold Tree Node | Middle/Index finger tap | Visual clutter management |
| **`,` / `.`** | Lazygitrs | Navigate Parent / Child in Tree | Right index / ring finger | Mouse-free tree traversal |
| **`<` / `>`** | Lazygitrs | Navigate Sibling Nodes in Tree | Right index / ring finger | Horizontal structural jump |
| **`Enter` (on dir)**| Lazygitrs | Full-Screen Combined Dir Diff | Right pinky tap | Package-wide inspection |
