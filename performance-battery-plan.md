# Dotfiles Performance & Battery Optimization Plan

> **Scope:** Full analysis of all dotfiles in `~/.dotfiles` with actionable improvement  
> recommendations for three hardware tiers. Severity ratings use 🔴 High / 🟡 Medium / 🟢 Low impact.

---

## Hardware Tiers Referenced

| Tier | Example Hardware | RAM | CPU | Notes |
|------|-----------------|-----|-----|-------|
| **A — High-end** | Modern laptop with dGPU | 16–32 GB | AMD Ryzen / Intel Core i7+ | Current config targets this |
| **B — Mid-range** | Typical dev laptop | 8–16 GB | Intel Core i5/i7 (4–8c) | Some adjustments needed |
| **C — Constrained** | Dell Latitude 3190 | 4 GB | Intel Celeron N4100 (4c/4t, 1.1–2.4 GHz, 6W TDP) | Significant changes required |

---

## 1. Analysis: What Currently Drains Resources

### 1.1 Hyprland / Compositor (`hypr/`)

| Issue | Config File | Severity | Description |
|-------|-------------|----------|-------------|
| Animations enabled | `animations.conf` | 🟡 B / 🔴 C | Even "fast & snappy" animations require the compositor to render intermediate GPU frames, holding the iGPU above idle. On Celeron N4100 (Intel UHD 600, 12 EU) this causes sustained GPU load and prevents C-states. |
| `rounding = 8` | `looknfeel.conf` | 🟡 B / 🔴 C | Corner rounding requires per-frame masking passes. Every window resize/move is more expensive. |
| Blur on hyprlock | `hyprlock.conf` → `blur_passes = 3` | 🟡 B / 🔴 C | Three blur passes on the lock screen background render under GPU compositor load. Uses ~30–60 MB extra VRAM. |
| NVIDIA env vars active | `hyprland.conf` | 🔴 C | `NVD_BACKEND=direct` + `LIBVA_DRIVER_NAME=nvidia` are set unconditionally. On machines without an NVIDIA GPU (Celeron is Intel-only) these env vars cause warning spam and can trigger driver fallback paths that leak memory. |
| `GDK_SCALE=2` | `monitors.conf` | 🟡 B / 🔴 C | Forces 2× HiDPI scaling globally. On a 1366×768 Latitude 3190 panel this is wrong anyway, but on any non-retina machine it doubles the rendered surface for every GTK app. |
| `persistent-workspaces` 0–5 | `waybar/config.jsonc` | 🟡 | 6 persistent workspaces means Hyprland keeps 6 workspace objects in memory even when empty. Each workspace tracks window lists, focus history, etc. |

### 1.2 Waybar (`waybar/`)

| Module | Severity | Description |
|--------|----------|-------------|
| `custom/cava` — cava.sh | 🔴 C | Runs `cava` as a persistent child process + a `sed` pipeline + a `while IFS= read` loop + `playerctl status` query **every single audio frame (30 fps)**. This is 3 processes alive at all times just for the visualizer bar in the status bar. On a Celeron this will push the 4 little cores measurably. |
| `custom/spotify` | 🟡 B / 🔴 C | `interval = 1` — polls playerctl **every second** with a full shell invocation (`sh -lc "..."`). A login shell spawned every second (even lightweight) consumes ~5–15 ms CPU per launch on Celeron. That's a constant background drain. |
| `network` | 🟢 | `interval = 3` — polling every 3 seconds is acceptable but can be raised to 10 with no user-visible difference. |
| `battery` | 🟢 | `interval = 5` — fine for all tiers. |
| `cpu` | 🟢 | `interval = 5` — fine, but the module invokes `/proc/stat` reads; acceptable. |
| `reload_style_on_change = true` | 🟡 | Waybar watches the CSS and JSON files with inotify and hot-reloads. Harmless in development, tiny constant overhead in production. |
| CSS animations on workspace buttons | 🟡 C | `ws_normal` / `ws_active` / `ws_hover` are 20-second CSS keyframe animations on every button. GTK re-paints ticks for 20 s per button interaction. |
| Tray drawer transition | 🟢 | `transition-duration: 600` ms CSS transition in `group/tray-expander` — purely cosmetic GPU work. |

### 1.3 Terminal — Ghostty (`ghostty/`)

| Issue | Severity | Description |
|-------|----------|-------------|
| Custom GLSL cursor shader | 🟡 B / 🔴 C | `cursor_frozen.glsl` is a non-trivial parallelogram/SDF fragment shader active on every terminal frame repaint. On Intel UHD 600 (Celeron) with its limited shader units this adds measurable repaint cost vs. a simple cursor. |
| `font-thicken = true` | 🟢 | Forces sub-pixel font thickening; minor extra rasterisation pass per glyph. Negligible on A/B but adds up on C. |
| Ligatures disabled (`-calt`, `-liga`) | 🟢 (positive) | Already disabled — good for performance. |

### 1.4 Tmux (`tmux/`)

| Issue | Severity | Description |
|-------|----------|-------------|
| 8 TPM plugins | 🟡 B / 🔴 C | `tpm`, `tmux-resurrect`, `tmux-continuum`, `tmux-sensible`, `vim-tmux-navigator`, `tmux-thumbs`, `tmux-fzf`, `tmux-nerd-font-window-name`. Each adds `source` overhead at startup and some (continuum, nerd-font) run periodic background processes. |
| `tmux-continuum` | 🟡 | Auto-saves session every 15 min (default) — writes to disk periodically and runs shell commands in background. Minor but present. |
| `tmux-thumbs` | 🟢 | Rust binary — fast, but it is loaded at every tmux start even if never used. |
| `history-limit = 10000` | 🔴 C | With multiple panes × sessions × 10 000 lines of history each stored in RAM as scrollback buffer. On 4 GB this can accumulate to hundreds of MB. |
| Nerd font window name | 🟢 | Shell hook that runs on every window rename — tiny but constant. |
| `xclip` clipboards | 🟢 | External process spawn per copy operation. Fine, but `wl-copy` would be more native under Wayland. |

### 1.5 Zsh Shell Init (`zsh/`)

| Issue | Severity | Description |
|-------|----------|-------------|
| `eval "$(mise activate zsh)"` | 🟡 | Forks a subprocess and evals output on **every new shell**. `mise` adds ~30–80 ms to shell startup. Acceptable on A, noticeable on C. |
| `eval "$(atuin init zsh)"` | 🟢 | Same eval pattern — ~10–20 ms. |
| `eval "$(zoxide init zsh --cmd j)"` | 🟢 | ~5–10 ms. |
| `eval "$(starship init zsh)"` | 🟡 | Starship is rich — each prompt render forks a `starship prompt` process. Add `zsh-vi-mode` prompt resets (`zle reset-prompt`) and this can fire multiple times per Enter keypress. On Celeron: ~20–50 ms latency per prompt. |
| `zsh-vi-mode` | 🟡 | Complex plugin with custom `zle-line-init`, `zvm_after_select_vi_mode` callbacks, and multiple `zle -N` hooks. Each fires on every keypress in vi-mode transitions. |
| `zsh-syntax-highlighting` | 🟡 C | Re-tokenizes the full command line on **every keystroke**. On long pipelines this can cause perceptible input lag on slow CPUs. |
| `zsh-autosuggestions` | 🟢 | Uses `zsh` history async lookup — lightweight but adds a constant keypress hook. |
| `zsh-transient-prompt` | 🟢 | Post-execution prompt rewrite — minor. |
| 14 packages sourced unconditionally | 🟢 | `source_packages` guard is already present, but each binary check (`$+commands[...]`) still runs. |

### 1.6 Miscellaneous Tools

| Tool/Config | Severity | Description |
|-------------|----------|-------------|
| `hyprsunset` identity profile | 🟢 | Night-light is disabled but the `hyprsunset` daemon still runs, polling every few minutes. |
| `kanshi` | 🟢 | Monitor auto-switcher — light daemon, fine. |
| `mako` | 🟢 | Minimal notification daemon — no issues. |
| `walker` `max_results = 256` | 🟢 C | Indexing 256 results with icon rendering; on slow CPUs this can cause first-open lag. |
| `yazi` preview `max_width = 1200, max_height = 1800` | 🟡 C | Large preview image decode on a Celeron. |
| `bat` in FZF preview | 🟡 C | FZF's `CTRL-T` preview spawns `bat` with syntax highlighting for every navigation event. |
| `eza --tree --level=2 --icons` in FZF preview | 🟡 C | Icon resolution requires loading Nerd Font metadata on every directory preview. |
| Spotify playerctl in FZF preview comments | 🟢 | Commented out but was there — leave commented. |
| `tmux capture-pane` → `nvim` scrollback alias | 🟢 | One-shot, acceptable. |

---

## 2. Improvement Plan

### Priority Matrix

| # | Change | Tier | RAM Δ | CPU/Battery Δ | Effort |
|---|--------|------|-------|---------------|--------|
| P1 | Disable NVIDIA env vars on non-NVIDIA machines | C | — | 🔴 fix crash/leak | Low |
| P2 | Disable/simplify animations | C | — | 🔴 big | Low |
| P3 | Replace `cava.sh` with lower-fps or remove | C | ~10 MB | 🔴 big | Low |
| P4 | Fix `custom/spotify` poll interval | B/C | — | 🟡 med | Low |
| P5 | Lower `history-limit` in tmux | C | ~200 MB | 🟡 med | Low |
| P6 | Remove `tmux-continuum` or increase save interval | C | ~5 MB | 🟡 med | Low |
| P7 | Remove cursor GLSL shader on Tier C | C | — | 🟡 med | Low |
| P8 | Disable `rounding` + lock blur | C | — | 🟡 med | Low |
| P9 | Fix `GDK_SCALE=2` for non-HiDPI | C | ~50 MB | 🟡 med | Low |
| P10 | Reduce persistent workspaces | C | ~5 MB | 🟢 low | Low |
| P11 | Enable starship caching / switch to pure-zsh prompt | C | ~5 MB | 🟡 med | Medium |
| P12 | Replace `zsh-syntax-highlighting` with `fast-syntax-highlighting` | C | — | 🟡 med | Low |
| P13 | Tune hypridle to dim display earlier | B/C | — | 🔴 big battery | Low |
| P14 | Enable `hyprsunset` auto nightlight | B/C | — | 🟡 LCD backlight | Low |
| P15 | Reduce FZF preview image resolution | C | — | 🟢 | Low |
| P16 | Reduce `walker` max_results | C | ~5 MB | 🟢 | Low |
| P17 | Reduce `yazi` preview resolution | C | ~20 MB | 🟢 | Low |
| P18 | Reduce waybar CSS animation durations | C | — | 🟢 | Low |

---

## 3. Concrete Change Recipes by File

### 3.1 `hypr/animations.conf` — Tier C (Celeron)

```diff
# Replace the "Fast & snappy" block with full disable
-animations {
-    enabled = yes
-    ...
-}
+animations {
+    enabled = no
+}
```

For Tier B (occasional use), use the "Maximum speed" preset (duration=1) already commented in the file.

---

### 3.2 `hypr/hyprland.conf` — Guard NVIDIA vars behind a runtime check

```diff
-# NVIDIA environment variables
-env = NVD_BACKEND,direct
-env = LIBVA_DRIVER_NAME,nvidia
-env = __GLX_VENDOR_LIBRARY_NAME,nvidia
+# NVIDIA environment variables — only uncomment on machines with an NVIDIA GPU
+# env = NVD_BACKEND,direct
+# env = LIBVA_DRIVER_NAME,nvidia
+# env = __GLX_VENDOR_LIBRARY_NAME,nvidia
```

On Intel/AMD-only machines these **must** be removed or guarded. They cannot be set at Hyprland config level conditionally; use a machine-specific `~/.config/hypr/local.conf` (sourced last) per machine.

---

### 3.3 `hypr/hyprlock.conf` — Reduce blur cost

```diff
 background {
     monitor =
     color = $color
     path = ~/.config/omarchy/current/background
-    blur_passes = 3
+    blur_passes = 1   # Tier B: still looks good
+    # blur_passes = 0 # Tier C: flat color only
 }
```

---

### 3.4 `hypr/looknfeel.conf` — Remove rounding on Tier C

```diff
 decoration {
-    rounding = 8
+    rounding = 0   # Tier C: sharp corners, zero masking overhead
 }
```

---

### 3.5 `monitors.conf` — Fix scale for non-retina displays

```diff
-env = GDK_SCALE,2
+# env = GDK_SCALE,2   # Only enable on actual HiDPI/retina displays (≥220 ppi)
+# For 1366x768 @ 11.6" (Latitude 3190): do NOT set, or set to 1
 monitor=,preferred,auto,auto
```

A 1366×768 panel at 11.6" is ~135 ppi — nowhere near HiDPI. `GDK_SCALE=2` would cause GTK apps to render at 2732×1536 then downscale, wasting both RAM and GPU cycles.

---

### 3.6 `waybar/config.jsonc` — Fix cava and spotify polling

**Remove or disable cava on Tier C:**

```jsonc
// "modules-right": [
//   "custom/cava",   // Remove this on Tier C
//    ...
// ]
```

Alternatively, increase cava framerate in `cava.sh`:

```diff
-framerate = 30
+framerate = 10   # Tier B: adequate visual, ~66% less CPU
+# framerate = 0  # Tier C: consider removing entirely
```

**Fix spotify polling interval:**

```diff
 "custom/spotify": {
-    "interval": 1,
+    "interval": 5,   // Tier B: 5s is imperceptible for track name
+    // "interval": 10, // Tier C or remove the module
```

**Increase network polling:**

```diff
 "network": {
-    "interval": 3,
+    "interval": 10,
```

**Reduce persistent workspaces to what you actually use:**

```diff
 "persistent-workspaces": {
-    "*": ["0","1","2","3","4","5"]
+    "*": ["1","2","3"]   // Tier C: fewer empty workspace objects
 }
```

---

### 3.7 `waybar/styles/defaults.css` — Reduce CSS animations

```diff
-    animation: ws_normal 20s ease-in-out 1;
+    animation: none;

-    animation: ws_active 20s ease-in-out 1;
+    animation: none;

-    animation: ws_hover 20s ease-in-out 1;
+    animation: none;
```

And for the tray drawer transition:

```diff
-    "transition-duration": 600,
+    "transition-duration": 0,   // Tier C: instant expand
```

---

### 3.8 `ghostty/config` — Remove GLSL shader on Tier C

```diff
-custom-shader = /home/fecavmi/.config/ghostty/shaders/cursor_frozen.glsl
+# custom-shader = ...  # Tier C: plain block cursor, zero shader overhead
```

Also on Tier C:

```diff
-font-thicken = true
+font-thicken = false
```

---

### 3.9 `tmux/tmux.conf` — Memory & plugin tuning

```diff
-set-option -g history-limit 10000
+set-option -g history-limit 2000   # Tier C: ~80% less scrollback RAM
+# set-option -g history-limit 5000 # Tier B
```

Remove or tune continuum:

```diff
-set -g @plugin 'tmux-plugins/tmux-continuum'
-# (and its set @continuum-restore lines)
+# Tier C: remove tmux-continuum; use tmux-resurrect manual saves only
```

Remove `tmux-thumbs` if never used (it's a Rust binary loaded at every tmux start):

```diff
-set -g @plugin 'fcsonline/tmux-thumbs'
+# Tier C: remove if prefix+Space is not used regularly
```

Switch from `xclip` to native Wayland:

```diff
-bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
-bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "xclip -in -selection clipboard"
+bind -T copy-mode-vi y send-keys -X copy-pipe-and-cancel "wl-copy"
+bind -T copy-mode-vi MouseDragEnd1Pane send-keys -X copy-pipe-and-cancel "wl-copy"
```

---

### 3.10 `zsh/init.zsh` — Shell startup optimisation

**Option A (Tier B): Cache `mise` evaluation (fastest approach)**

```zsh
# In mise.zsh — cache the activation script
_mise_cache="$HOME/.cache/mise-activate.zsh"
if [[ ! -f "$_mise_cache" || "$HOME/.local/bin/mise" -nt "$_mise_cache" ]]; then
    mise activate zsh >| "$_mise_cache"
fi
source "$_mise_cache"
```

**Option B (Tier C): Replace starship with a minimal pure-zsh prompt**

Starship is the single largest per-keystroke cost: it spawns a subprocess on every prompt render. On a Celeron this adds 20–50 ms of perceived lag per command.

```zsh
# Minimal replacement — add to init.zsh instead of source_packages starship
autoload -Uz vcs_info
precmd() { vcs_info }
setopt PROMPT_SUBST
PROMPT='%F{blue}%~%f ${vcs_info_msg_0_}%# '
```

Or use `pure` (POSIX zsh, no subprocess) instead of starship:

```zsh
# Install: https://github.com/sindresorhus/pure
# Already runs async in pure zsh — no subprocess
```

**Option C (Tier C): Replace `zsh-syntax-highlighting` with `fast-syntax-highlighting`**

```diff
-source_plugins \
-  zsh-vi-mode \
-  zsh-autosuggestions \
-  zsh-syntax-highlighting \
-  zsh-transient-prompt
+source_plugins \
+  zsh-autosuggestions \
+  fast-syntax-highlighting \    # 3-5× faster tokenizer, written in zsh
+  zsh-transient-prompt
# Tier C: also consider removing zsh-vi-mode and using built-in vi mode:
# bindkey -v
```

---

### 3.11 `hypr/hypridle.conf` — Aggressive battery saving

```diff
 listener {
-    timeout = 150   # 2.5 min → screensaver
+    timeout = 90    # Tier C: 90s → screensaver (display is largest power drain)
 }

 listener {
-    timeout = 300   # 5 min → lock
+    timeout = 180   # Tier C: 3 min → lock
 }

 listener {
-    timeout = 330   # 5.5 min → display off
+    timeout = 210   # Tier C: 3.5 min → display off
 }
```

Enable `hyprsunset` night profile to reduce perceptual brightness without lowering backlight:

```diff
-# Enable auto switch to nightlight:
-# profile {
-#     time = 20:00
-#     temperature = 4000
-# }
+profile {
+    time = 20:00
+    temperature = 4000   # Tier B/C: reduces blue LED drive, saves ~0.3–0.5W
+}
```

---

### 3.12 `yazi/yazi.toml` — Reduce preview overhead

```diff
 [preview]
-max_width = 1200
-max_height = 1800
+max_width = 600    # Tier C: half-res preview, 75% less decode work
+max_height = 900
-image_quality = 75
+image_quality = 50  # Tier C: still looks fine in a small pane
```

---

### 3.13 `walker/config.toml` — Reduce index size

```diff
-max_results = 256
+max_results = 64   # Tier C: faster initial index, less RAM for results list
```

---

### 3.14 `fzf/packages/fzf.zsh` — Limit preview spawn rate

FZF's `CTRL-T` and `ALT-C` spawn `bat` or `eza` on every cursor movement. On Tier C:

```diff
-export FZF_CTRL_T_OPTS="
-    --preview='... bat --style=numbers --color=always --line-range=:300 {}'
-    --preview-window=right:60%
+export FZF_CTRL_T_OPTS="
+    --preview='[[ -d {} ]] && eza --level=1 --color=always {} || bat --style=plain --color=always --line-range=:50 {}'
+    --preview-window=right:40%
```

- `--style=plain` drops line numbers/borders → faster bat rendering
- `--line-range=:50` instead of `:300` → 6× less I/O per preview

---

## 4. Tier-Specific Profiles

### Profile C — Dell Latitude 3190 (4 GB RAM, Celeron N4100)

**Must-do** (high impact, zero UX regression):

- [ ] Comment out NVIDIA env vars in `hyprland.conf`
- [ ] Set `GDK_SCALE=1` (or remove the line) in `monitors.conf`
- [ ] Disable animations: `animations { enabled = no }` in `animations.conf`
- [ ] Remove `custom/cava` from `modules-right` in `waybar/config.jsonc`
- [ ] Set `custom/spotify` `interval` to `10` (or remove module)
- [ ] Set tmux `history-limit` to `2000`
- [ ] Remove `tmux-continuum` plugin
- [ ] Remove cursor GLSL shader in ghostty config
- [ ] Set `blur_passes = 0` in `hyprlock.conf`
- [ ] Shorten hypridle timeouts (display off at ~3 min)

**Recommended** (measurable improvement):

- [ ] Remove `rounding = 8` from `looknfeel.conf`
- [ ] Replace `zsh-syntax-highlighting` with `fast-syntax-highlighting`
- [ ] Replace `starship` with `pure` prompt or a native zsh prompt
- [ ] Add `mise` activation caching
- [ ] Reduce `walker` max_results to 64
- [ ] Reduce `yazi` preview resolution
- [ ] Reduce FZF preview line range to `:50` and use `bat --style=plain`
- [ ] Set waybar `network interval` to 15
- [ ] Set waybar CSS animations to `none`
- [ ] Enable `hyprsunset` nightlight at 20:00

**Expected gains on Celeron N4100:**

| Change | RAM saved | Battery gain (approx) |
|--------|-----------|----------------------|
| Disable animations + rounding | — | +0.5–1.0 W less GPU |
| Remove cava | ~15 MB | +0.2–0.5 W |
| Shorter screen timeout | — | +0.5–1.5 W on average |
| Fix GDK_SCALE | ~50–100 MB | — |
| Tmux scrollback limit | ~100–200 MB | — |
| Total | ~200–300 MB | +1–3 W (~10–20% battery life) |

---

### Profile B — Mid-range Laptop (8–16 GB, Core i5/i7)

- Keep animations at "Fast & snappy" (current) or "Maximum speed"
- Set `custom/spotify` `interval` to `5`
- Set `blur_passes = 1` in hyprlock
- Increase `history-limit` to `5000`
- Consider caching `mise` activation
- Enable `hyprsunset` nightlight
- Set `network` interval to `10`

---

### Profile A — High-end (16+ GB, dedicated GPU)

Current config is well-suited. Optional quality-of-life:

- Replace `xclip` with `wl-copy` for proper Wayland clipboard (not a performance issue, but correctness)
- Consider `reload_style_on_change = false` in waybar production config

---

## 5. Feature Removability Assessment

| Feature | Can Remove? | Impact if Removed | Alternative |
|---------|-------------|-------------------|-------------|
| `cava` visualizer | ✅ Yes | Zero functional loss; purely cosmetic | Remove module from waybar |
| `lolcat` (rainbow alias) | ✅ Yes | Zero functional loss | Remove package |
| `figlet` | ✅ Yes | Only used for ASCII art text | Remove package |
| `tmux-continuum` | ✅ Yes on C | Session auto-save; use `tmux-resurrect` manually | `<prefix>+Ctrl-s` to save |
| `tmux-thumbs` | ✅ Yes on C | Hint-mode copy; useful but not essential | Manual copy-mode |
| `hyprsunset identity` profile | ✅ Replace | Does nothing useful; replace with actual night profile | See §3.11 |
| `zsh-vi-mode` | ⚠️ Tier C only | Loses vi modal editing in shell | `bindkey -v` (builtin) |
| `custom/spotify` module | ✅ Yes on C | Polybar-style "now playing" | Use mpris tray instead |
| GLSL cursor shaders | ✅ Yes | Cosmetic only | Plain block cursor |
| `tmux-fzf` plugin | ⚠️ Optional | FZF inside tmux; overlap with shell FZF | Shell-level FZF sufficient |
| `duf` (df alias) | ✅ Yes | Use vanilla `df -h` | Alias `df` to nothing |
| `procs` (ps alias) | ✅ Yes | Use `ps aux` or htop | Alias `ps` to nothing |
| `kanshi` | ⚠️ Keep | Needed for multi-monitor hotplug | Keep if you use external displays |
| `sesh` | ⚠️ Optional | Wraps `tmux` session management | Use tmux natively |

---

## 6. Best Tool Choices by Notebook Tier

### Tier C (Dell Latitude 3190 / Celeron / 4 GB)

| Category | Current | Better Choice | Why |
|----------|---------|---------------|-----|
| Terminal | Ghostty (GPU accelerated, with GLSL shader) | **Foot** or **Alacritty** without shader | Foot is Wayland-native, minimal, ~10 MB RAM; Alacritty disables shaders by default |
| Shell prompt | Starship (subprocess per prompt) | **Pure** (async zsh, no subprocess) or **Powerlevel10k instant prompt** | Zero subprocess overhead |
| Syntax highlighting | `zsh-syntax-highlighting` | **fast-syntax-highlighting** | 3–5× faster tokenizer |
| File manager | Yazi with large previews | Yazi with reduced preview settings, or **lf** | lf is lower RAM, no image preview by default |
| Multiplexer | tmux + 8 plugins | tmux + only tpm+resurrect+sensible | Fewer plugin hooks = less overhead |
| App launcher | Walker (GTK, full icon index) | **Fuzzel** (pure Wayland, lightweight) or **Tofi** | Fuzzel: ~8 MB RAM, <20 ms cold start |
| Notifications | Mako | Keep Mako | Already minimal |
| Status bar | Waybar with cava+spotify | Waybar without cava; keep other modules | Already in waybar config, just remove modules |
| Compositor | Hyprland with animations | **Hyprland with animations=no** or consider **Sway** | Sway: no GPU compositor effects = lowest iGPU usage |
| Browser | (not configured) | **Firefox with uBlock Origin** | Chrome/Electron apps eat RAM aggressively |
| Text editor | Neovim (configured) | Keep Neovim, avoid VS Code | Neovim: ~30–50 MB RAM vs. VS Code: 300–700 MB |

### Tier B (8–16 GB, Core i5)

Current toolset is appropriate. Main optimisations:
- Replace starship with Powerlevel10k (instant prompt mode, same feature set, zero subprocess lag)
- Reduce waybar cava to 15 fps
- Use `wl-copy` instead of `xclip`

### Tier A (16+ GB, dGPU)

Current config is fine as-is. If on NVIDIA, the env vars in `hyprland.conf` are correct and necessary.

---

## 7. Additional Battery Strategies (System-level, not dotfiles)

These are outside the dotfiles scope but have high impact on Tier C:

1. **`power-profiles-daemon` / `tuned`**: Set profile to `power-saver` when on battery.
   ```bash
   powerprofilesctl set power-saver   # when on battery
   ```

2. **`tlp` or `auto-cpufreq`**: Govern CPU frequency scaling aggressively on Celeron.
   ```ini
   # /etc/tlp.conf
   CPU_SCALING_GOVERNOR_ON_BAT=powersave
   CPU_BOOST_ON_BAT=0           # Celeron has no Turbo Boost worth enabling on battery
   SATA_LINKPWR_ON_BAT=min_power
   WIFI_PWR_ON_BAT=on
   ```

3. **Hyprland `xdg-portal-hyprland`**: Ensure screen sharing uses PipeWire properly; a broken portal can keep the compositor at elevated frame rates.

4. **Swap**: With 4 GB RAM, ensure `zram` is enabled:
   ```bash
   systemctl enable --now systemd-zram-setup@zram0
   ```
   `zram` compresses swap in RAM (typically 2:1 ratio), effectively giving ~6 GB usable on a 4 GB machine without SSD wear.

5. **Font rendering**: With `font-thicken = false` in ghostty and `GDK_SCALE=1`, disable sub-pixel hinting in fontconfig to reduce rasterisation work in GTK apps.

6. **Disable Bluetooth when not in use**: The `bluetooth` waybar module shows state but doesn't manage power. Add to `hypridle`:
   ```ini
   listener {
       timeout = 1800   # 30 min idle → disable BT
       on-timeout = rfkill block bluetooth
       on-resume = rfkill unblock bluetooth
   }
   ```

---

## 8. Implementation Order (Tier C Quick-Start)

Execute in this order for fastest improvement with least effort:

```bash
# 1. Comment NVIDIA vars (immediate — prevents env errors)
#    Edit: ~/.config/hypr/hyprland.conf  → comment env = NVD_BACKEND, etc.

# 2. Fix display scale (immediate — halves GTK rendering surface)
#    Edit: ~/.config/hypr/monitors.conf  → comment GDK_SCALE=2

# 3. Disable animations (immediate after hyprctl reload)
#    Edit: ~/.config/hypr/animations.conf  → enabled = no

# 4. Remove cava from waybar (immediate after waybar restart)
#    Edit: ~/.config/waybar/config.jsonc  → remove "custom/cava" from modules-right

# 5. Lower tmux scrollback
#    Edit: ~/.config/tmux/tmux.conf  → history-limit 2000

# 6. Remove cursor shader
#    Edit: ~/.config/ghostty/config  → comment custom-shader line

# 7. Tighten hypridle screen timeout
#    Edit: ~/.config/hypr/hypridle.conf  → reduce all timeouts

# 8. Install fast-syntax-highlighting & update init.zsh

# 9. Install pure prompt & remove starship from source_packages

# 10. Enable zram if not already active
#     systemctl enable --now systemd-zram-setup@zram0
```

---

*Analysis performed: March 2026 | Dotfiles path: `~/.dotfiles`*
