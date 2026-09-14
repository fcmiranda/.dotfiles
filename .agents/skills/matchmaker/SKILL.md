---
name: matchmaker
description: |
  Expert guide for building fast, composable TUI pickers with Matchmaker (mm) — a Rust fuzzy-finder
  similar to fzf but with TOML config, nav mode, column splitting, piped input, and preset overrides.
  Use this skill whenever the user wants to build a selector, menu, picker, switcher, or TUI list
  powered by mm/matchmaker. Also trigger it when the user asks about: preset files (.toml in
  ~/.config/matchmaker/presets/), nav_mode, piping to mm, preview commands, keybinds, columns,
  or integrating mm into a shell script. Apply this skill proactively whenever the user is building
  a new mm workflow even if they don't say "matchmaker" explicitly.
---

# Matchmaker (mm) — Expert Builder Skill

Matchmaker (`mm`) is a fast, Rust-based TUI fuzzy finder configured via TOML. Think of it as fzf
with structured presets, nav mode, multi-column support, and rich preview layouts. The binary
lives at `~/.local/bin/mm` (or `~/.cargo/bin/mm`).

## Architecture Overview

```
~/.config/matchmaker/
├── config.toml          # base config (always loaded)
└── presets/             # overrides layered with -o flag
    ├── jump.toml
    ├── backgrounds.toml
    └── your-tool.toml
```

Invoke with a preset: `mm -o your-tool` (no path, no extension — mm resolves from presets/).  
Layer multiple overrides: `mm -o base -o extra`.

---

## ⚡ Performance: Piped Input vs start.command

This is the most important performance decision:

### 🚀 Fastest: Standalone Config Execution (`mm --no-read --config "$preset_file"`)
```bash
# Instant load used by Omarchy menus — bypasses base config reading & TOML merging
(cd ~/.config/hypr/animations && mm --no-read --config ~/.config/matchmaker/presets/animations.toml)
```
- **`--config` vs `-o`**: `--config` completely **bypasses reading `~/.config/matchmaker/config.toml`** and skips TOML tree merging in Rust. Loads the preset directly as a 1-step standalone config (<1ms).
- **`--no-read`**: Tells mm to skip reading stdin and immediately run the `[start.command]`.
- **0 subprocesses, 0 merge latency** — instant TUI initialization.

### Fast: Native Directory Context (`cd target_dir && mm --nav --sort`)
```bash
# Change directory context and let mm scan natively in Rust
(cd ~/.config/hypr/animations && mm -o my-preset --nav --sort)
```
- Uses mm's native Rust file scanner directly.
- Ideal for pickers operating on a folder of files.

### Fast: Pipe directly from your script
```bash
# Generate list in bash, pipe to mm
my_items | mm -o my-preset
```
- Omit `[start.command]` in the preset so mm reads from stdin directly
- **No shell subprocess is spawned by mm** — mm reads stdin immediately

### Zero-Fork Shell Loop Pattern (No Subprocesses)
When generating list items inside `[start.command] cmd`, avoid spawning external sub-processes (`head`, `sed`, `awk`) inside loops. Use pure shell built-ins:

```sh
[start.command]
cmd = '''
ANIM_DIR="$HOME/.config/hypr/animations"
for file in $ANIM_DIR/*.conf; do
  [ -f "$file" ] || continue
  read -r title < "$file" || true
  title="${title#\#}"
  title="${title# }"
  [ -z "$title" ] && title="${file##*/}"
  printf "%s\t%s\n" "$title" "$file"
done
'''
```
- `read -r title < "$file"` reads the first line using shell built-in (0 forks)
- `${title#\#}` strips `#` using parameter expansion (0 forks)
- `${file##*/}` extracts filename using parameter expansion (0 forks)
- **0 sub-processes spawned** — runs in <0.1ms.

### Rule of thumb
- **Small/static lists** (< 1000 items): pipe from script, use `x=""`
- **Large/streaming lists**: use `start.command` with `separator = "\\0"` for null-byte splitting

---

## Config Reference

### Input & Columns

```toml
[start.command]
# Note: both 'cmd' and 'command' keys work as aliases for the shell command
cmd = 'fd --print0'      # 'cmd' is the short alias
# command = 'fd --print0'  # 'command' also works (used in jump.toml)
separator = "\\0"          # null-byte separator (safe for filenames)

[columns]
split = "\t"               # split on tab → multi-column
names = [
  "label",                 # visible column
  { name = "path", hidden = true }  # used in preview/exec but not shown
]
```

Column references in commands use `{1}`, `{2}`, etc. (1-indexed).  
`{=}` = full line. `{=1}` = first column (alternative syntax). `{=#}` = 0-based row index.  
`{item}` = item label (useful as a preview border title). `{+1}` = all selected items, column 1.

### Nav Mode (keyboard-driven browsing)

```toml
[ui]
nav_mode = true
nav_bar = "Plain"    # or "Double", "Rounded"
nav_color = "Cyan"

[start]
mode = "nav"         # start in nav mode

[binds]
# Prefix nav^^ for nav-mode-only binds
"nav^^j"     = "Down"
"nav^^k"     = "Up"
"nav^^g"     = "Pos(0)"
"nav^^G"     = "Pos(-1)"
"nav^^enter" = "Accept"
"nav^^q"     = "Quit"
"nav^^esc"   = "Quit"
```

Nav mode vs query mode: nav mode is for browsing (vim-style hjkl), query mode is for typing.
Press any printable character to switch to query mode. Press `esc` to return to nav.

Two ways to define nav-mode-only binds — both work:

```toml
# Option A: nav^^ prefix inside [binds]
[binds]
"nav^^j" = "Down"
"nav^^enter" = "Accept"

# Option B: separate [ui.nav_binds] section (no prefix needed)
[ui.nav_binds]
"j" = "Down"
"enter" = "Accept"
"l" = ["ChDir({=})", "@reload_local"]   # @reload_local refreshes after chdir
"h" = ["ChDir(..)", "@reload_local"]
"~" = ["ChDir(/home/user)", "Pos(0)", "@reload_local"]
"o" = "ExecuteSilent(xdg-open {=1})"    # {=1} = first column only
```

Use `[ui.nav_binds]` when you have many nav-specific binds; `nav^^` is simpler for a few.

### Preview Panel (Native vs External Command)

Matchmaker features **built-in native Rust renderers** for files, directories, markdown, and media.
**There is no need to add an external `command = '''...'''` when `mm` supports the content natively**:
- **Source Code & Text**: Native syntect syntax highlighting with line numbers (replaces `bat` and `cat`).
- **Directories**: Native directory tree renderer (replaces `eza --tree` and `tree`).
- **Markdown**: Native Ratatui Markdown parser with headers, tables, task lists, code fences, and Mermaid diagram extraction.
- **Mermaid Diagrams**: Native inline Kitty Unicode Placeholders (`inline_diagrams = true`) and modal SVG/PNG rasterizer (`s` / `ToggleDiagram`). Features automatic Omarchy dark/light theme sync and transparent alpha backgrounds.
- **Images & Media**: Native Kitty graphics protocol with aspect ratio fitting, pan, and zoom (replaces `chafa` and `catimg`).

```toml
[preview]
show = true
wrap = true
media = true            # enables native Kitty image/video/pdf protocol
markdown = true         # enables native markdown rendering
diagrams = true         # enables Mermaid diagram handling
inline_diagrams = true  # enables Kitty Unicode Placeholders (\u{10EEEE}) inline rendering
diagram_theme = "auto"  # "auto" (Omarchy/COLORFGBG detection), "dark", "light"
diagram_background = "transparent" # "transparent" (borderless flow) or "solid"

# Native preview (files, directories, markdown, images) — NO command needed:
[[preview.layout]]
side = "right"
percentage = 60
min = 30

[preview.border]
type = "Rounded"
color = "Cyan"
title_fg = "Cyan"
```

> **When TO use `command = '''...'''`**: ONLY specify `command` for domain-specific, dynamic non-file previews that `mm` cannot produce on its own, such as:
> - `git log` / `git diff` / `git status` (e.g. `awt.toml`)
> - Process & Port details `ps` / `lsof` (e.g. `kill.toml`)
> - Tmux pane inspection `tmux capture-pane` (e.g. `window-picker.toml`)
> - External previewers like `sesh preview` (e.g. `sesh-picker.toml`)
> - Live configuration triggers (e.g. `animations.toml` reloading Hyprland)

Multiple preview layouts cycle with `ctrl-/`.

### Key Binds

```toml
[binds]
# Standard binds (work in both modes)
"ctrl-j"       = "Down"
"ctrl-k"       = "Up"
"ctrl-shift-j" = "PreviewDown(5)"   # Scroll preview down while typing in filter mode
"ctrl-shift-k" = "PreviewUp(5)"     # Scroll preview up while typing in filter mode
"ctrl-u"       = "Cancel"           # clear query
"enter"        = "Accept"
"esc"          = "Quit"

# Preview & Diagram Navigation
"ctrl-s"       = "ToggleDiagram"    # Modal diagram viewer (focuses nearest diagram; in nav mode use 's')
"0"            = "DiagramResetZoom" # Reset diagram zoom (0 dedicated reset key)
"-"            = "DiagramZoomOut"
"="            = "DiagramZoomIn"
# In Diagram/Fullscreen mode: Arrow keys (Up/Down/Left/Right) and hjkl pan the diagram
# In [ui.nav_binds]: "s" = "ToggleDiagram" provides single-key toggle from Results mode

# Actions
"ctrl-r"       = "Reload"
"ctrl-/"       = "CyclePreview"
"ctrl-p"       = "SwitchPreview"
"alt-p"        = "Print({-})"       # print selected without closing

# Execute without closing mm
"ctrl-x"       = "ExecuteSilent(cp {2} ~/target/)"

# Replace mm process with editor
"ctrl-e"       = "Become($EDITOR {2})"

# ReloadNext cycles through additional_commands
"ctrl-z"       = "ReloadNext"
```

### Output Template

```toml
[start]
output_template = "{2}"   # only output column 2 on accept
# or
output_separator = "\n"   # separator between multi-selected items
```

Without `output_template`, mm prints the full matched line.

---

## Preset Template (Copy-Paste Starter)

```toml
# ~/.config/matchmaker/presets/my-tool.toml

[ui]
nav_mode = true
nav_bar = "Plain"
[matcher]
sort = "smart"        # "smart"/"auto": preserves natural stream order on empty query, sorts by fuzzy relevance when typing
depth_penalty = 15   # SIMD-accelerated path depth penalty: penalizes deep nested subfolders so shallow root files rank higher

[tui]
percentage = 70
min = 12
max = 60

[query]
prompt = " My Tool > "
prompt_style.fg = "Cyan"
status_inline = true

[preview]
show = true
wrap = true

[preview.border]
type = "Rounded"
color = "Cyan"
title_fg = "Cyan"

# Native preview (omits command — mm handles syntax highlighting, markdown & media natively)
[[preview.layout]]
side = "right"
percentage = 60
min = 35

[columns]
split = "\t"
names = [
  "label",
  { name = "path", hidden = true }
]

# No start.command — input is piped from the caller script
[start]
mode = "nav"
additional_commands = []

[start.command]
cmd = ""

[binds]
"ctrl-j"     = "Down"
"ctrl-k"     = "Up"
"nav^^enter" = "Accept"
"nav^^q"     = "Quit"
"nav^^esc"   = "Quit"
"nav^^g"     = "Pos(0)"
"nav^^G"     = "Pos(-1)"
"nav^^j"     = "Down"
"nav^^k"     = "Up"
```

---

## Shell Script Pattern

This is the canonical pattern for a fast mm-based tool:

```bash
#!/usr/bin/env bash
# my-picker — TUI picker powered by mm

PRESET="${HOME}/.config/matchmaker/presets/my-tool.toml"
MM=$(command -v mm) || { echo "mm not found" >&2; exit 1; }

# Build tab-separated input: "DISPLAY_LABEL\tACTUAL_PATH"
build_list() {
  for item in /some/path/*.conf; do
    [[ -f "$item" ]] || continue
    label=$(head -n1 "$item" | sed 's/^# *//')
    printf "%s\t%s\n" "$label" "$item"
  done
}

# Pipe list directly — instant startup, no shell subprocess in mm
SELECTED=$(build_list | "$MM" -o "$PRESET" x="" 2>/dev/null)
[[ -z "$SELECTED" ]] && exit 0

# Extract second column (the hidden path)
TARGET=$(printf '%s' "$SELECTED" | awk -F'\t' '{print $2}')
[[ -z "$TARGET" ]] && TARGET="$SELECTED"

# Act on selection
echo "Selected: $TARGET"
```

---

## Common Patterns

### Mark the currently active item
```bash
build_list() {
  CURRENT=$(cat ~/.config/active-item 2>/dev/null)
  for item in /path/*.conf; do
    label=$(basename "$item" .conf)
    marker=""
    [[ "$item" == "$CURRENT" ]] && marker=" 󰄴"
    printf "%s%s\t%s\n" "$label" "$marker" "$item"
  done
}
```

### Nerd Font icons by index
```bash
icons=("" "" "" "󰎁" "" "󰒲")
idx=0
for item in ...; do
  icon="${icons[$idx]:-}"
  printf "%s  %s\t%s\n" "$icon" "$label" "$item"
  (( idx++ ))
done
```

### ReloadNext (cycle data sources)
```toml
[start]
additional_commands = ["", "mm list --dirs 2>/dev/null"]

[binds]
"@reloadnext" = "ReloadNext"   # define semantic alias first
"ctrl-z"      = "@reloadnext"  # then bind key to alias

# Also works in ui.nav_binds for nav-mode-only cycling
[ui.nav_binds]
"ctrl-z" = "@reloadnext"
"z"      = "@reloadnext"
```

### Breadcrumb (path display in file browser)
```toml
[breadcrumb]
show = true
separator = "/"
style.fg = "Cyan"
style.modifier = "BOLD"
separator_style.fg = "Cyan"
# current_folder_only = true   # show only last segment
# truncate_length = 3          # max segments
# width_pct = 80               # max % of terminal width
```
Breadcrumb automatically updates when `ChDir` is triggered.

### Execute action without leaving mm
```toml
[binds]
"ctrl-p" = "ExecuteSilent(notify-send 'preview' '{1}')"
"ctrl-o" = "Execute($EDITOR {2})"    # opens editor, returns to mm after
"ctrl-b" = "Become($EDITOR {2})"     # replaces mm process with editor
```

### Null-byte separated input (safe for paths with spaces)
```bash
fd --print0 | mm -o my-preset i="\0"
```
```toml
[start.command]
cmd = "fd --print0"
separator = "\\0"
```

---

## Environment Variables Available in Commands

| Variable | Description |
|---|---|
| `{1}`, `{2}`, ... | Columns by index (1-based) |
| `{=}` | Full input line |
| `{=#}` | 0-based row index |
| `{+1}` | All selected items, column 1 |
| `MM_QUERY` | Current query string |
| `MM_POS` | Current cursor position |
| `MM_MATCH_COUNT` | Number of filtered matches |
| `MM_TOTAL_COUNT` | Total item count |
| `LINES` / `COLUMNS` | Preview area dimensions (preview commands only) |

---

## Troubleshooting

| Symptom | Likely Cause | Fix |
|---|---|---|
| Slow to open | `start.command` spawning shell | Pipe input from script, use `x=""` |
| No items shown | `cmd = ""` but no stdin | Pipe data: `my_cmd \| mm -o preset x=""` |
| Nav mode not working | Missing `[start] mode = "nav"` | Add `mode = "nav"` under `[start]` |
| Preview shows nothing | Column ref wrong | Check `{1}` vs `{2}` — tab-split |
| Accept returns full line | No output_template | Add `output_template = "{2}"` or parse with awk |
| Binds conflict between modes | Using bare bind for nav-only action | Prefix nav-only binds with `nav^^` |
