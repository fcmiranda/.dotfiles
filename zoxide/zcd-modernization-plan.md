# `zcd` — Modernization Plan

> Audit of the current implementation against modern tooling alternatives.
> Every feature from `zcd-spec.md` is preserved.

---

## TL;DR — What Changes, What Stays

| Area | Current | Proposed | Reason |
|------|---------|----------|--------|
| Fuzzy picker | `fzf` | **keep `fzf`** | No equivalent for the feature set used |
| Relative-path computation | `python3` | `awk` one-liner | Drop interpreter dependency; awk is faster on large lists |
| Clipboard | `xclip` | `wl-copy` | Dotfiles target Wayland (Hyprland); xclip requires XWayland |
| Temp file management | 11 separate `mktemp` | single `mktemp -d` + `trap` | Atomic cleanup, shorter code, no leaks on crash |
| Directory search | `fd` | **keep `fd`** | Already the best tool; nothing faster or more ergonomic |
| Navigation history | temp-file stack | **keep as-is** | Required by fzf's stateless execution model |
| Preview | `eza` + `bat` | **keep as-is** | Already the right tools |
| Frecency | `zoxide` | **keep as-is** | Core feature, no alternative |

---

## 1. Why `fzf` Stays

`gum` (`charmbracelet/gum`) is the obvious "modern" candidate, but it cannot replace `fzf` here. The specific features `zcd` relies on are only available in `fzf`:

| Feature | Used in `zcd` | `fzf` support | `gum filter` support |
|---------|---------------|---------------|----------------------|
| `transform:` bind | TAB toggle, arrow dispatch | ✅ (≥ 0.38) | ✗ |
| `reload(…)` | source switch, navigation | ✅ | ✗ |
| `execute-silent(…)` | state writes without flicker | ✅ | ✗ |
| `rebind` / `unbind` | printable-key blocking in navigate mode | ✅ | ✗ |
| `change-prompt` | visual mode feedback | ✅ | ✗ |
| `change-header` | two-line dynamic header | ✅ | ✗ |
| `--delimiter` + `--with-nth` | hide full-path column, keep it selectable | ✅ | ✗ |
| `--preview` with conditional logic | eza for dirs, bat for files | ✅ | ✗ |
| `ctrl-/:toggle-preview` | preview pane toggle | ✅ | ✗ |

`gum filter` is a static one-shot picker with no key-binding API. Replicating the dual-mode UI in `gum` would require writing a full TUI application in Go or Python — not a simplification.

**`fzf` is the correct tool and should stay.**

---

## 2. Drop `python3` → Replace with `awk`

### Current approach

A temp Python script is written to disk and called as a subprocess to convert absolute paths to tab-separated `fullpath\trelpath` pairs. Python is used because `realpath --relative-to` "is not portable".

### Problem

- Adds a mandatory interpreter dependency for a single, simple operation.
- Writing the script to a temp file and injecting `cwd` via shell concatenation is fragile.
- On large `fd` result sets (thousands of paths), spawning Python has noticeable startup cost.

### Proposed: `awk` inline function

`awk` is universally available, starts fast, and can carry out relative-path arithmetic natively using string operations. On Linux, GNU `realpath --relative-to` is also reliably available (GNU coreutils), but `awk` avoids the per-line subprocess cost of piping into `realpath`.

```awk
# relpath.awk — inline, no temp file needed
# usage: ... | awk -v cwd="$_cwd" -f relpath.awk
#
# Or inline as a single awk program string
BEGIN {
    n = split(cwd, base, "/")
}
{
    p = $0
    if (p == "") next
    m = split(p, tgt, "/")
    # find common prefix length
    common = 0
    for (i = 1; i <= (n < m ? n : m); i++) {
        if (base[i] == tgt[i]) common = i
        else break
    }
    rel = ""
    for (i = common + 1; i <= n; i++) rel = rel "../"
    for (i = common + 1; i <= m; i++) rel = rel tgt[i] (i < m ? "/" : "")
    if (rel == "") rel = "."
    print p "\t" rel
}
```

Embedded directly in the shell function as a variable — no temp file required for this piece. The Python temp-file generation code (`_relscript`, the `RELEOF` heredoc, the `echo "cwd = ..."` injection) is entirely removed.

This eliminates one of the eleven temp files (`_relscript`).

---

## 3. Replace `xclip` with `wl-copy`

### Current

```zsh
ctrl-y:execute-silent(echo -n {1} | xclip -selection clipboard)
```

`xclip` only works under X11. In the Hyprland Wayland session it silently fails unless XWayland is running and `DISPLAY` is set.

### Proposed

```zsh
ctrl-y:execute-silent(echo -n {1} | wl-copy)
```

`wl-copy` is part of `wl-clipboard`, the Wayland-native clipboard tool. It works in any Wayland compositor and is already in the dependency list of most Wayland-focused dotfiles setups.

**Dependency change:** remove `xclip`, add `wl-clipboard`.

If cross-environment portability is desired, a fallback wrapper can be used:

```zsh
local _copy_cmd
if command -v wl-copy &>/dev/null; then
    _copy_cmd='wl-copy'
elif command -v xclip &>/dev/null; then
    _copy_cmd='xclip -selection clipboard'
else
    _copy_cmd='cat > /dev/null'  # graceful no-op
fi
# then in the bind:
# ctrl-y:execute-silent(echo -n {1} | $_copy_cmd)
```

---

## 4. Single Temp Directory + `trap` Cleanup

### Current

Eleven separate `mktemp` calls produce eleven scattered files in `/tmp`. Cleanup is a single long `rm -f` at the end. If `zcd` is interrupted (Ctrl-C inside fzf before the shell `rm -f` line), the files leak.

### Proposed

```zsh
local _tmpdir
_tmpdir=$(mktemp -d)
trap 'rm -rf "$_tmpdir"' EXIT INT TERM

local _stack="$_tmpdir/stack"
local _sortfile="$_tmpdir/sortfile"
local _curdir="$_tmpdir/curdir"
local _modefile="$_tmpdir/modefile"
local _sourcefile="$_tmpdir/sourcefile"
local _togglescript="$_tmpdir/toggle"
local _rightaction="$_tmpdir/rightaction"
local _leftaction="$_tmpdir/leftaction"
local _rightscript="$_tmpdir/rightscript"
local _leftscript="$_tmpdir/leftscript"
# _relscript removed (replaced by awk)
```

**Benefits:**

- `trap EXIT` fires on every exit path: normal return, `ESC`, `CTRL-C` inside the widget, shell crash.
- All ten remaining files (one removed by dropping python) live under a predictable directory path.
- Debug: `ls /tmp/zcd-XXXXX/` to inspect state while troubleshooting.
- Remove the manual `rm -f` at the end — `trap` handles it.

---

## 5. Minor Shell Quality Improvements

### 5.1 `zsh -c` instead of `sh -c` in `execute-silent`

`execute-silent(…)` is evaluated by `sh`. For most of the state-write operations this is fine, but if any future bind content uses zsh-specific syntax (arrays, `[[`, `(( ))` without leading whitespace), it will silently fail. Consider specifying `zsh` explicitly in the fzf `--shell` flag (introduced in fzf 0.56):

```
fzf --shell zsh ...
```

This makes all `execute-silent`, `transform:`, and `reload` content run under zsh, eliminating the `sh -c` vs `zsh` mismatch entirely.

### 5.2 Touch initial state files instead of redundant `echo`/`printf`

Instead of:
```zsh
echo "dirsfirst" > "$_sortfile"
echo "filter"    > "$_modefile"
(( zoxide_only )) && echo "zo" > "$_sourcefile" || echo "all" > "$_sourcefile"
printf '' > "$_curdir"
```

Use a dedicated `_state_init` function to make intent explicit and centralize state initialization (reused by source-switch binds):

```zsh
_zcd_init_state() {
    print -n "dirsfirst" > "$_sortfile"
    print -n "filter"    > "$_modefile"
    print -n "all"       > "$_sourcefile"
    : > "$_stack"
    : > "$_curdir"
}
```

### 5.3 Eliminate the `_init_reload_rel` branch duplication

Currently there are two nearly-identical `eval` calls (one for `zoxide_only`, one for combined). After the `awk` refactor the source expression is short enough to be fully determined before `fzf` is called:

```zsh
local _source_cmd
(( zoxide_only )) && _source_cmd=$_init_zo_awk || _source_cmd=$_init_all_awk
dir=$(eval "$_source_cmd" | fzf ... "${_common_binds[@]}")
```

A single `fzf` invocation, no branching `if`.

---

## 6. Updated Dependency Table

| Tool | Purpose | Change |
|------|---------|--------|
| `zoxide` | Frecency-weighted directory list | unchanged |
| `fd` | Fast filesystem search | unchanged |
| `fzf` | Interactive fuzzy picker (≥ 0.38 for `transform:`, ≥ 0.56 for `--shell`) | unchanged |
| `awk` | Inline relative-path computation | **replaces `python3`** |
| `eza` | Directory tree preview | unchanged |
| `bat` | File content preview | unchanged |
| `wl-copy` | Clipboard copy (Wayland) | **replaces `xclip`** |
| `zsh` | Shell host | unchanged |
| ~~`python3`~~ | ~~Relative-path computation~~ | **removed** |
| ~~`xclip`~~ | ~~Clipboard (X11)~~ | **removed** |

---

## 7. Implementation Checklist

- [ ] Replace `_relscript` Python heredoc with inline `awk` program variable
- [ ] Update `_init_all_rel` / `_init_zo_rel` / `_browse` to use `awk` instead of `python3 '$_relscript'`
- [ ] Remove `_relscript` mktemp call and the `chmod`/`rm` references to it
- [ ] Replace `mktemp` × 11 with `mktemp -d` and named files under `$_tmpdir`
- [ ] Add `trap 'rm -rf "$_tmpdir"' EXIT INT TERM` immediately after `mktemp -d`
- [ ] Remove the manual `rm -f` line at the end of the function
- [ ] Replace `xclip -selection clipboard` with `wl-copy` in `_bind_copy`
- [ ] Update the dependency comment block at the top of `zoxide.zsh`
- [ ] Add `--shell zsh` to the `fzf` invocation if fzf ≥ 0.56 is confirmed
- [ ] Consolidate the two `fzf` call branches into one using a pre-determined `_source_cmd`
- [ ] Verify `fzf --version` ≥ 0.38 in a startup check or README note
