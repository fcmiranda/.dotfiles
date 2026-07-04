# System Theme

The desktop is themed by [Omarchy](https://github.com/basepiac/omarchy). Omarchy ships a set of
named color themes and renders per-app config files from them, so switching one theme updates
Hyprland, the status bar, launcher, notifications, terminal emulators, editors, and browsers in a
single step.

This repo only contributes **overrides** and **hook scripts** on top of Omarchy's built-in theme
engine. The engine itself is upstream code installed under `~/.local/share/omarchy/`.

## Theme store layout

```
~/.local/share/omarchy/themes/<name>/        # Built-in themes (from Omarchy)
├── colors.toml                              #   palette (accent, foreground, color0..15, ...)
├── wallpaper                                 #   background image
└── ...                                       #   per-theme config snippets

~/.config/omarchy/theme-overrides/<name>/    # Overrides shipped in this repo
└── colors.toml                              #   color edits layered over the built-in theme

~/.config/omarchy/current/theme/             # Active, rendered theme (generated — don't edit)
~/.config/omarchy/current/theme.name         # Plain text file holding the active theme name
```

Themes shipped as overrides here: `catppuccin`, `catppuccin-latte`, `ethereal`, `everforest`,
`flexoki-light`, `gruvbox`, `hackerman`, `kanagawa`, `lumon`, `matte-black`, `miasma`, `nord`,
`osaka-jade`, `retro-82`, `ristretto`, `rose-pine`, `tokyo-night`, `vantablack`, `white`.

See `omarchy/.config/omarchy/theme-overrides/`.

## How a theme switch works

Switching is triggered by the `omarchy-theme-set <name>` command
(`~/.local/share/omarchy/bin/omarchy-theme-set`):

1. Build a *next* theme dir (`~/.config/omarchy/current/next-theme`) by copying the built-in
   theme and overlaying the matching override directory from this repo on top.
2. Render `*.tpl` templates against `colors.toml` via `omarchy-theme-set-templates`. Templates
   live in two places:
   - Built-in: `~/.local/share/omarchy/default/themed/*.tpl`
     (e.g. `ghostty.conf.tpl`, `hyprland.conf.tpl`, `waybar.css.tpl`, `mako.ini.tpl`,
     `alacritty.toml.tpl`, `btop.theme.tpl`, `hyprlock.conf.tpl`, `walker.css.tpl`,
     `chromium.theme.tpl`, `obsidian.css.tpl`, `swayosd.css.tpl`, `keyboard.rgb.tpl`)
   - User (this repo): `~/.config/omarchy/themed/*.tpl`
     (currently only `kitty.conf.tpl`)
3. Atomically swap the *next* dir into `~/.config/omarchy/current/theme` and write the theme
   name to `theme.name`.
4. Restart components: `omarchy-restart-waybar`, `omarchy-restart-fuzzel`, `omarchy-restart-swayosd`,
   `omarchy-restart-terminal`, `omarchy-restart-hyprctl`, `omarchy-restart-btop`,
   `omarchy-restart-opencode`, `omarchy-restart-mako`.
5. Apply theme to external apps: `omarchy-theme-set-gnome`, `omarchy-theme-set-browser`,
   `omarchy-theme-set-vscode`, `omarchy-theme-set-obsidian`, `omarchy-theme-set-keyboard`.
6. Fire the `theme-set` hook so per-app refresh logic can run.

## Template syntax

Templates substitute `{{ key }}` placeholders from `colors.toml`:

| Placeholder        | Resolves to                                   |
|--------------------|-----------------------------------------------|
| `{{ foreground }}` | The hex value (e.g. `#cdd6f4`)                |
| `{{ foreground_strip }}` | Same value with the leading `#` removed |
| `{{ foreground_rgb }}`  | `r,g,b` decimal triple for hex colors    |

Override colors take precedence over the built-in theme's `colors.toml` (first-match wins in the
underlying `sed` pass). See the render logic in
`omarchy/.config/omarchy/hooks/theme-set`.

## The `theme-set` hook (extending the theme system)

`omarchy/.config/omarchy/hooks/theme-set` runs after every theme switch and does extra work this
repo needs:

- Re-sources `~/.config/tmux/tmux.conf` so tmux picks up the freshly rendered `tmux-colors.conf`.
- Re-renders any user template in `~/.config/omarchy/themed/` using both the active theme's
  `colors.toml` and any matching override file, applying them with the same `{{ key }}` substitution.
- Calls `omarchy-restart-hyprctl` (i.e. `hyprctl reload`) to apply new Hyprland colors.
- Writes the Neovim colorscheme name so running Neovim instances pick it up via an fs watcher.

This is also where additional per-app refresh logic should be added when adopting a new tool into
the dotfiles.

## Useful theme commands

```bash
omarchy-theme-list                  # list available themes
omarchy-theme-current               # print the active theme name
omarchy-theme-set <name>            # switch theme (renders templates, restarts components, runs hook)
omarchy-theme-refresh               # re-render templates for the current theme without switching
omarchy-theme-bg-set <path>         # set a custom wallpaper for the current theme
omarchy-theme-bg-next               # advance to the next built-in wallpaper
```