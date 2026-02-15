# Omarchy Package Theming with Templates (Step by Step)

This guide shows how to make any app/package config follow the currently selected Omarchy theme.

## How Omarchy templating works

When you run:

```bash
omarchy-theme-set "<theme-name>"
```

Omarchy does this:

1. Copies the selected theme into:
   - `~/.config/omarchy/current/next-theme/`
2. Reads `colors.toml` from that folder.
3. Renders all `*.tpl` template files (user templates first, then built-ins).
4. Writes rendered output files into `~/.config/omarchy/current/next-theme/`.
5. Swaps `next-theme` to:
   - `~/.config/omarchy/current/theme/`

So your app should read config from `~/.config/omarchy/current/theme/<your-file>`.

---

## Step 1) Decide the target config file name

Pick the real filename your app expects.

Examples:
- app reads `config.toml`
- app reads `tool.conf`
- app reads `colors.json`

If your app expects `tool.conf`, your template must be named:

- `tool.conf.tpl`

---

## Step 2) Create a user template (recommended)

Create your template in:

- `~/.config/omarchy/themed/<your-file>.tpl`

Why this location:
- It overrides built-in templates.
- It survives `omarchy-update`.

Example:

```bash
mkdir -p ~/.config/omarchy/themed
$EDITOR ~/.config/omarchy/themed/tool.conf.tpl
```

---

## Step 3) Use Omarchy placeholders in the template

Inside `*.tpl`, use placeholders from theme `colors.toml`.

Common placeholders:

- `{{ background }}`
- `{{ foreground }}`
- `{{ color0 }}` ... `{{ color15 }}`

Variants Omarchy also generates:

- `{{ colorN_strip }}` → hex without `#`
- `{{ colorN_rgb }}` → decimal RGB like `127,187,179`

### Example template

```toml
# ~/.config/omarchy/themed/tool.conf.tpl
bg = "{{ background }}"
fg = "{{ foreground }}"
accent = "{{ color4 }}"
accent_no_hash = "{{ color4_strip }}"
accent_rgb = "{{ color4_rgb }}"
```

---

## Step 4) Apply (render) with your current theme

Run:

```bash
omarchy-theme-set "$(cat ~/.config/omarchy/current/theme.name)"
```

Or switch and apply another theme directly:

```bash
omarchy-theme-set "everforest"
```

This regenerates:

- `~/.config/omarchy/current/theme/<your-file>`

---

## Step 5) Point the app to the rendered file

Use one of these patterns.

### Pattern A: Symlink app config to Omarchy rendered file (best)

```bash
ln -snf ~/.config/omarchy/current/theme/<your-file> ~/.config/<app>/<your-file>
```

Because `~/.config/omarchy/current/theme/` is updated on each theme change, the app always reads the newest rendered config.

### Pattern B: Export app env var to Omarchy rendered file

If app supports an env var path (like Starship):

```bash
export APP_CONFIG=~/.config/omarchy/current/theme/<your-file>
```

Add it to your shell config if needed.

---

## Step 6) Reload or restart the app

Most apps must be reloaded after config changes.

Examples:
- terminal prompt: `exec zsh`
- app daemon/service: restart command for that app

---

## Step 7) Verify quickly

```bash
# Confirm rendered output exists
ls -la ~/.config/omarchy/current/theme/<your-file>

# Inspect first lines
sed -n '1,40p' ~/.config/omarchy/current/theme/<your-file>
```

---

## Complete quick-start checklist

1. Create `~/.config/omarchy/themed/<your-file>.tpl`
2. Put `{{ ... }}` color placeholders in it
3. Run `omarchy-theme-set "$(cat ~/.config/omarchy/current/theme.name)"`
4. Symlink app config to `~/.config/omarchy/current/theme/<your-file>`
5. Reload app

---

## Real example (Starship)

Template:
- `~/.local/share/omarchy/default/themed/starship.toml.tpl` (built-in)
- recommended override: `~/.config/omarchy/themed/starship.toml.tpl`

Rendered output:
- `~/.config/omarchy/current/theme/starship.toml`

App config path:
- `STARSHIP_CONFIG=$HOME/.config/starship/config.toml`
- symlink `~/.config/starship/config.toml -> ~/.config/omarchy/current/theme/starship.toml`

Then change theme with:

```bash
omarchy-theme-set "tokyo night"
```

and Starship follows the new Omarchy colors.
