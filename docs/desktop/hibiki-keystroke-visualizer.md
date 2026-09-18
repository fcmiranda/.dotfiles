# Hibiki (響) — Wayland Keystroke Visualizer & Audio Companion

[Hibiki](https://github.com/linuxmobile/hibiki) is a high-performance GTK4 Layer Shell keystroke visualizer and auditory typing companion built specifically for Wayland compositors (Hyprland, Niri, Sway). Heavily inspired by KeyCastr and devaslife's aesthetic setups, it renders keystroke overlays and provides zero-latency mechanical keyboard sounds.

---

## 🚀 Key Features

* **Wayland Native & Layer Shell**: Interacts directly with Wayland compositors using `gtk4-layer-shell`, avoiding X11/XWayland workarounds.
* **Dual Display Modes**:
  * **Keystroke Mode**: Classic on-screen key combination badges for screencasts, live streams, presentations, and tutorials.
  * **Bubble Mode**: Minimal, floating bubble overlay displaying compact key press bubbles.
* **Built-in Audio Engine**:
  * Multi-threaded `rodio`-powered sound engine.
  * Compatible with Mechvibes sound packs (single and multi-file switch audio).
  * Low latency audio playback.
* **Granular Typography & Theming**:
  * Per-mode font family, weight, and size configuration.
  * Respects system GTK themes and Omarchy dark aesthetics.
* **System Tray & Hotkeys**:
  * Quick access via tray icon to toggle visualizer modes, pause capture, or open settings.
  * Global hotkeys for pause (`Ctrl+P`) and toggle focus (`Ctrl+B`).

---

## 🛠️ Architecture & Stow Package Layout

Hibiki is managed as an isolated GNU Stow package within `~/.dotfiles/main`:

```text
hibiki/
├── .config/
│   └── hibiki/
│       └── config.toml                  # Mirrored to ~/.config/hibiki/config.toml
└── .local/
    └── share/
        ├── applications/
        │   └── hibiki.desktop           # Mirrored to ~/.local/share/applications/
        └── icons/hicolor/scalable/apps/
            └── hibiki.svg               # Mirrored to ~/.local/share/icons/hicolor/...
```

### 1. Configuration (`~/.config/hibiki/config.toml`)

The central configuration lives in `~/.config/hibiki/config.toml`:

```toml
# 響 (Hibiki) Configuration
display_mode = "keystroke"
position = "bottomcenter"
display_timeout_ms = 2000
max_keys = 5
margin = 20
show_modifiers = true
all_keyboards = true
font_scale = 1.0
opacity = 1.0
font_family = "JetBrainsMono Nerd Font"
font_size = 1.2
keystroke_theme = "system"
keystroke_draggable = false
keystroke_hotkey = "<Shift><Control>k"
pause_hotkey = "<Control>p"
toggle_focus_hotkey = "<Control>b"
auto_detect_layout = true
corner_radius = 1.0

[bubble]
font_family = "JetBrainsMono Nerd Font"
font_size = 1.0
color = "#3584e4"
position = "topright"
draggable = false
hotkey = "<Shift><Control>b"
timeout_ms = 10000
opacity = 1.0
corner_radius = 0.36

[audio]
enabled = false
volume = 1.0
sound_pack = "cherrymx-blue-abs"

[bubble.audio]
enabled = false
volume = 1.0
sound_pack = "cherrymx-blue-abs"
```

---

## ⌨️ CLI Usage & Flags

Hibiki provides both a launcher GUI and direct overlay daemon mode:

| Command | Description |
| :--- | :--- |
| `hibiki` | Launch Hibiki with Dashboard / Launcher settings window. |
| `hibiki --no-ui` / `hibiki -n` | Bypass Dashboard and start visualizer directly (ideal for Hyprland `exec-once` autostart). |

Both commands are registered in [IntelliShell custom commands](../../intelli-shell/.config/intelli-shell/custom.commands) (`intelli-sync`).

---

## 🔒 Permissions & Compositor Setup

Hibiki captures raw keyboard events via Linux `evdev` (`/dev/input/event*`).

To allow keystroke capture without running as root, the user account must belong to the `input` group:

```bash
# Verify group membership
groups | grep input

# If missing, add current user and relogin:
sudo usermod -aG input "$USER"
```

---

## 📦 Software Lifecycle (`.shell/install`)

Hibiki is registered in the dotfiles package installation pipeline:

1. **Custom Installer**: `.shell/install/packages/hibiki.zsh` compiles `hibiki` from GitHub via `cargo install --git https://github.com/linuxmobile/hibiki` and links the binary into `~/.local/bin/hibiki`.
2. **Master List**: Added to `install_packages` in `.shell/install/install.zsh`.
3. **Stow Integration**: Run `./stow.sh hibiki` to link desktop files, icons, and configuration.
