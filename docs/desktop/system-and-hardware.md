# Desktop, Displays, Terminal & Hardware Management

System-level behaviors, Wayland display hotplugging, Ghostty terminal optimizations, and hardware power profiles.

---

## 1. Automatic Monitor Management via Kanshi

Display profiles and hotplug events are automatically handled by [`kanshi`](https://github.com/emersion/kanshi), a Wayland monitor daemon.

### How it Works

- **Autostart**: `kanshi` is launched on session start via [`hypr/.config/hypr/autostart.conf`](../../hypr/.config/hypr/autostart.conf):
  ```ini
  exec-once = kanshi
  ```
- **Hotplug Detection**: `kanshi` listens to Wayland output events. When an external monitor (or Ultrawide display) is plugged in or disconnected, it automatically applies matching display profiles without restarting Hyprland.
- **Profile Layouts**: Managed in the [`kanshi`](../../kanshi) package (target: `~/.config/kanshi/config`). Example configuration from [`kanshi/.config/kanshi/config.ultrawide`](../../kanshi/.config/kanshi/config.ultrawide):

  ```kanshi
  # External Ultrawide connected: disable laptop screen, set HDMI resolution & reserved space
  profile {
      output "eDP-1" disable
      output "HDMI-A-1" mode 2560x1080 position 0,0
      exec hyprctl keyword monitor "HDMI-A-1,addreserved,-10,0,0,0"
  }

  # Standalone laptop: enable internal display
  profile {
      output "eDP-1" enable
  }
  ```

---

## 2. Ghostty Terminal Enhancements

Configurations in [`ghostty/.config/ghostty/config`](../../ghostty/.config/ghostty/config) provide several advanced terminal features:

- **CSI u Key Escapes**: Maps `Ctrl+1` through `Ctrl+9` and `Ctrl+~` to explicit CSI u escape codes (e.g. `\x1b[49;5u`), ensuring terminal multiplexers like `tmux` reliably capture window navigation keybindings.
- **Hyprland Performance (`epoll`)**: Sets `async-backend = epoll` to eliminate event loop latency under Hyprland.
- **Custom Shaders**: Includes GPU GLSL shader effects (`cursor_frozen.glsl` / `cursor_blaze.glsl`) for custom visual cursor rendering.

---

## 3. Battery Management & CPU Power Profiles

Hardware battery health and CPU energy management scripts shipped in the [`battery`](../../battery) stow package (`battery/.local/bin/`):

- **Charging Thresholds (`battery-threshold`)**: Sets hardware battery charge limits (e.g. `80%`) to minimize battery degradation when plugged in long-term.
- **CPU Performance Toggle (`perf-toggle`)**: Switches CPU energy-performance hints between `performance`, `balanced`, and `power-saver` modes on the fly.
- **Waybar Status (`perf-waybar`)**: Integrates live power state and battery condition into the Waybar status bar.
