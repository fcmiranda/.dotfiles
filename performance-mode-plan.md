# Performance Mode Plan

## Context

Two machines share the same dotfiles. The newer one handles the current config fine;
the older one lags. A toggle-based performance mode resolves this without maintaining
two separate config branches.

---

## Process Audit (memtop --top 25)

| Process | RSS | CPU% | Notes |
|---|---|---|---|
| code (7 procs) | 1.2 GB | 81% | Active editor — expected |
| walker | 278 MB | 0% | Launcher daemon (`--gapplication-service`), kept for instant launch |
| elephant | 181 MB | 0% | Sesh TUI background service |
| journalctl | 213 MB | 0% | Live log watcher (started by sesh/autostart) |
| Hyprland | 118 MB | 8.5% | Includes blur + shadow compositing pass |
| cava (bash + proc) | ~5 MB | **4–5%** | Continuous audio visualizer in waybar |
| waybar | 62 MB | 1.5% | Includes spotify polling every 1 s |
| dockerd + containerd | 128 MB | 0% | Idle docker engine |
| swayosd-server | 50 MB | 0% | OSD server |
| fcitx5 | 32 MB | 0% | Input method (only needed for CJK) |

---

## Identified Bottlenecks

### 1. Hyprland compositor effects (~8.5% CPU, GPU load)
- `blur` — multi-pass shader on every transparent surface
- `shadow` — additional render pass per window
- `animations` — CPU/GPU during window transitions
- `rounding` — anti-aliased corner clipping on every frame
- Window transparency (0.97 / 0.90) — compositor blending on every frame

**Fix:** `performance.conf` Hyprland toggle (already created) — add `rounding = 0`.

### 2. Cava visualizer (4–5% continuous CPU)
- Long-running bash loop + cava process spawned by waybar `custom/cava`
- No polling interval — runs non-stop even when no audio is playing
- Already has a disable-file mechanism (`/tmp/waybar-cava-disabled`)

**Fix:** Performance mode disables cava via the existing disable file.

### 3. Waybar high-frequency polling
- `custom/spotify`: interval = **1 s** (spawns a subshell every second)
- `network`: interval = 3 s
- `cpu`: interval = 5 s
- `battery`: interval = 5 s
- `custom/perf`: interval = 3 s

**Fix (optional):** None of these individually dominate, but spotify at 1 s is aggressive.
  Performance mode does not change these since waybar cannot hot-reload intervals.

### 4. Walker resident daemon (278 MB)
- Stays in memory to ensure sub-100 ms launch.
- 0% CPU so it doesn't hurt performance, only RAM.
- **Not touched** — killing it makes the launcher slow, which defeats the purpose.

### 5. Docker idle (128 MB)
- Idle daemon. Not touched automatically — user manages this.

---

## Implementation

### Layer 1 — Hyprland (done + improved)

File: `omarchy/.local/share/omarchy/default/hypr/toggles/performance.conf`

- [x] `blur.enabled = false`
- [x] `shadow.enabled = false`
- [x] `animations.enabled = false`
- [x] `opacity 1.0 1.0` on all windows
- [ ] `rounding = 0` — **to add**

### Layer 2 — Background processes

File: `omarchy/.local/share/omarchy/bin/omarchy-toggle-performance`

- [ ] On enable: disable cava via `/tmp/waybar-cava-disabled` + kill cava process
- [ ] On disable: re-enable cava by removing the disable file + signal waybar

### Layer 3 — Power profile (done)

- [x] `omarchy-powerprofiles-set ac` on enable (prefers `performance` profile)
- [x] `omarchy-powerprofiles-set autodetect` on disable

---

## Persistence Through Theme Changes

The Hyprland flag lives in `~/.local/state/omarchy/toggles/hypr/performance.conf`.
Every theme change calls `omarchy-restart-hyprctl` → `hyprctl reload`, which
re-sources that directory. The flag is untouched by the theme pipeline.

The cava disable file lives in `/tmp/waybar-cava-disabled`. This is a tmpfs path
and does **not** persist across reboots — intentional, so performance mode resets
on reboot. The Hyprland flag does persist across reboots.

---

## Toggle Command

```sh
omarchy toggle performance
# or
omarchy-toggle-performance
```

Notification on enable: `"Performance mode: ON — blur, shadows, animations, cava disabled"`
Notification on disable: `"Performance mode: OFF — visual effects restored"`
