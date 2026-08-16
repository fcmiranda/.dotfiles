# Zsh Vi Mode & Custom Surrounds

Zsh is configured with `zsh-vi-mode` in [`zsh-plugins/.zsh/plugins/zsh-vi-mode.zsh`](../../zsh-plugins/.zsh/plugins/zsh-vi-mode.zsh), bringing full Vi modal editing (`insert`, `vicmd`, `visual`, `replace`) to the command line along with custom surround text objects and dynamic Starship prompt synchronization.

---

## 1. Starship Prompt Integration

- **Live Mode Tracking**: Exported shell variable `ZVM_MODE` tracks the active mode (`i` = insert, `n` = normal/cmd, `v`/`vl` = visual, `r` = replace).
- **Instant Prompt Refresh**: Switching modes (e.g. pressing `<Esc>` to enter `vi-cmd-mode` or `i` for insert mode) invokes `zvm_after_select_vi_mode()`, calling `zle reset-prompt` to instantly redraw the prompt indicator.
- **Starship Theme Presets**: Preset templates (see [`starship/.config/omarchy/themed-overrides/starship.toml.tpl`](../../starship/.config/omarchy/themed-overrides/starship.toml.tpl)) evaluate `$ZVM_MODE` via custom module `when` rules (e.g. `case "$ZVM_MODE" in n) exit 0;; *) exit 1;; esac`) to render distinct colors and indicators per mode.

---

## 2. Combined Surround Text Objects (`ib`, `ab`, `iq`, `aq`)

Custom ZLE widgets extend Vi mode with smart, unified surround text objects so you don't need to type specific bracket or quote characters:

- **Brackets (`ib` & `ab`)**:
  - `ib` (inside brackets): Automatically detects and targets the innermost enclosing brackets `(`, `[`, `{`, or `<`.
  - `ab` (around brackets): Targets the innermost enclosing brackets including the bracket characters themselves.
- **Quotes (`iq` & `aq`)**:
  - `iq` (inside quotes): Automatically detects and targets the innermost enclosing quotes `"`, `'`, or `` ` ``.
  - `aq` (around quotes): Targets the innermost enclosing quotes including the quote characters themselves.

### Supported Operations in `vicmd` & `visual` Modes

| Keybinding | Mode | Action |
| :--- | :--- | :--- |
| `vib` / `vab` | Visual | Visually select inside / around innermost brackets |
| `viq` / `vaq` | Visual | Visually select inside / around innermost quotes |
| `dib` / `dab` | Normal (`vicmd`) | Delete inside / around innermost brackets |
| `diq` / `daq` | Normal (`vicmd`) | Delete inside / around innermost quotes |
| `yib` / `yab` | Normal (`vicmd`) | Yank (copy) inside / around innermost brackets to clipboard |
| `yiq` / `yaq` | Normal (`vicmd`) | Yank (copy) inside / around innermost quotes to clipboard |
| `cib` / `cab` | Normal (`vicmd`) | Change inside / around innermost brackets (deletes & returns to Insert mode) |
| `ciq` / `caq` | Normal (`vicmd`) | Change inside / around innermost quotes (deletes & returns to Insert mode) |

---

## 3. Keybindings & Initialization

- **Insert Mode Default**: Every new command prompt starts in Vi Insert mode (`_zvm_custom_zle_line_init`).
- **History Navigation**: `Ctrl+K` / `Ctrl+J` and Up/Down arrows perform prefix-aware history searches; `Ctrl+R` opens Atuin; `Ctrl+T` triggers the Matchmaker jump widget.
