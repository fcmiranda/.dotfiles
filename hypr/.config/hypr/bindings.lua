-- Personal keybinding overrides migrated from bindings.conf
-- See current bindings: omarchy menu keybindings --print

local home = os.getenv("HOME") or "/home/fecavmi"

-- ==============================================================================
-- Application Bindings
-- ==============================================================================

-- Core Applications
o.bind("SUPER + RETURN", "Terminal", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)"')
o.bind("SUPER + ALT + RETURN", "Tmux", 'uwsm-app -- xdg-terminal-exec --dir="$(omarchy-cmd-terminal-cwd)" tmux new')
hl.unbind("SUPER + SHIFT + F")
o.bind("SUPER + SHIFT + F", "Yazi", "uwsm-app -- ghostty -e zsh -c 'tmp=$(mktemp -t yazi-cwd.XXXXXX); trap \"rm -f $tmp\" EXIT; yazi --cwd-file=\"$tmp\"; [[ -s \"$tmp\" ]] && cd \"$(<$tmp)\"; exec zsh -i'")
o.bind("SUPER + SHIFT + B", "Browser", "omarchy-launch-browser")
o.bind("SUPER + SHIFT + ALT + B", "Browser (private)", "omarchy-launch-browser --private")
o.bind("SUPER + SHIFT + M", "Music", "omarchy-launch-or-focus spotify")
o.bind("SUPER + SHIFT + N", "Editor", "omarchy-launch-editor")
o.bind("SUPER + SHIFT + T", "Activity", "omarchy-launch-tui btop")
o.bind("SUPER + SHIFT + D", "Docker", "omarchy-launch-tui lazydocker")
o.bind("SUPER + SHIFT + G", "Signal", 'omarchy-launch-or-focus signal "uwsm-app -- signal-desktop"')
o.bind("SUPER + SHIFT + O", "Obsidian", 'omarchy-launch-or-focus "^obsidian$" "uwsm-app -- obsidian -disable-gpu --enable-wayland-ime"')
o.bind("SUPER + SHIFT + W", "Typora", "uwsm-app -- typora")
o.bind("SUPER + SHIFT + SLASH", "Passwords", "uwsm-app -- 1password")

-- Web Applications & Utilities
o.bind("SUPER + SHIFT + A", "Animation Switcher", "omarchy-launch-tui " .. home .. "/.local/bin/hypr-anim")
o.bind("SUPER + SHIFT + ALT + A", "Grok", "omarchy-launch-webapp 'https://grok.com'")
o.bind("SUPER + SHIFT + C", "Calendar", "omarchy-launch-webapp 'https://app.hey.com/calendar/weeks/'")
o.bind("SUPER + SHIFT + E", "Email", "omarchy-launch-webapp 'https://app.hey.com'")
o.bind("SUPER + SHIFT + Y", "YouTube", "omarchy-launch-webapp 'https://youtube.com/'")
o.bind("SUPER + SHIFT + ALT + G", "WhatsApp", "omarchy-launch-or-focus-webapp WhatsApp 'https://web.whatsapp.com/'")
o.bind("SUPER + SHIFT + CTRL + G", "Google Messages", "omarchy-launch-or-focus-webapp 'Google Messages' 'https://messages.google.com/web/conversations'")
o.bind("SUPER + SHIFT + P", "Google Photos", "omarchy-launch-or-focus-webapp 'Google Photos' 'https://photos.google.com/'")
o.bind("SUPER + SHIFT + X", "X", "omarchy-launch-webapp 'https://x.com/'")
o.bind("SUPER + SHIFT + ALT + X", "X Post", "omarchy-launch-webapp 'https://x.com/compose/post'")

-- ==============================================================================
-- Screenshots & Screen Recording
-- ==============================================================================
hl.unbind("SUPER + SHIFT + S")
o.bind("SUPER + SHIFT + S", "Screenshot (region)", 'bash -c \'slurp | grim -g - - | satty --filename - --copy-command "wl-copy" --output-filename "$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"\'')
o.bind("SUPER + SHIFT + ALT + S", "Screenshot (fullscreen)", 'bash -c \'grim - | satty --filename - --copy-command "wl-copy" --output-filename "$HOME/Pictures/screenshot-$(date +%Y%m%d-%H%M%S).png"\'')
o.bind("SUPER + SHIFT + Escape", "Kill stuck screenshot", "bash -c 'pkill -x hyprpicker; pkill -x slurp'")
o.bind("SUPER + SHIFT + R", "Toggle screen recording", "omarchy-cmd-screenrecord")

-- ==============================================================================
-- Custom Launcher / Menu Overrides
-- ==============================================================================
hl.unbind("SUPER + SHIFT + K")
o.bind("SUPER + SHIFT + K", "Sesh sessions", "omarchy-launch-sesh")

o.bind("SUPER + SHIFT + W", "Motion Wallpaper", home .. "/.local/bin/motion-wallpaper-toggle")
o.bind("SUPER + F12", "Battery Menu", "uwsm-app -- " .. home .. "/.local/bin/battery-menu")
o.bind("SUPER + SHIFT + F12", "Battery Menu", "uwsm-app -- " .. home .. "/.local/bin/battery-menu")

-- Volume & Mute Keys
o.bind("F9", "Mute", "omarchy-swayosd-client --output-volume mute-toggle", { repeating = true, locked = true })
o.bind("F10", "Volume down", "omarchy-swayosd-client --output-volume lower", { repeating = true, locked = true })
o.bind("F12", "Volume up", "omarchy-swayosd-client --output-volume raise", { repeating = true, locked = true })

-- Keyboard Backlight Keys
o.bind("SUPER + F1", "Keyboard brightness down", "omarchy-brightness-keyboard down", { repeating = true, locked = true })
o.bind("SUPER + F2", "Keyboard brightness up", "omarchy-brightness-keyboard up", { repeating = true, locked = true })
o.bind("SUPER + SHIFT + F1", "Keyboard brightness 0%", "bash -c 'omarchy-brightness-keyboard off; omarchy-swayosd-kbd-brightness 0'", { repeating = true, locked = true })
o.bind("SUPER + SHIFT + F2", "Keyboard brightness 100%", "bash -c 'brightnessctl -d kbd_backlight set 100% >/dev/null && omarchy-swayosd-kbd-brightness 100'", { repeating = true, locked = true })

-- ==============================================================================
-- Workspace Shortcuts
-- ==============================================================================
o.bind("SUPER + code:49", "Switch to workspace 0", hl.dsp.focus({ workspace = "name:0" }))
o.bind("SUPER + SHIFT + code:49", "Move app to workspace 0", hl.dsp.window.move({ workspace = "name:0" }))

-- ==============================================================================
-- Window Management
-- ==============================================================================
hl.unbind("SUPER + W")
o.bind("SUPER + W", "Close window", hl.dsp.window.close())

hl.unbind("SUPER + V")
o.bind("SUPER + V", "Swap split", hl.dsp.layout("swapsplit"))

hl.unbind("SUPER + M")
o.bind("SUPER + M", "Fullscreen maximize", hl.dsp.window.fullscreen({ mode = "maximized" }))

hl.unbind("SUPER + T")
o.bind("SUPER + T", "Toggle floating & center", 'hyprctl --batch "dispatch togglefloating; dispatch centerwindow"')

o.bind("SUPER + BACKSLASH", "Toggle window split", hl.dsp.layout("togglesplit"))

-- Focus Navigation (Vim keys)
hl.unbind("SUPER + H")
hl.unbind("SUPER + J")
hl.unbind("SUPER + K")
hl.unbind("SUPER + L")
o.bind("SUPER + H", "Move window focus left", hl.dsp.focus({ direction = "l" }))
o.bind("SUPER + J", "Move window focus down", hl.dsp.focus({ direction = "d" }))
o.bind("SUPER + K", "Move window focus up", hl.dsp.focus({ direction = "u" }))
o.bind("SUPER + L", "Move window focus right", hl.dsp.focus({ direction = "r" }))

-- Window Moving (Vim keys)
o.bind("SUPER + ALT + H", "Move window left", hl.dsp.window.move({ direction = "l" }))
o.bind("SUPER + ALT + J", "Move window down", hl.dsp.window.move({ direction = "d" }))
o.bind("SUPER + ALT + K", "Move window up", hl.dsp.window.move({ direction = "u" }))
o.bind("SUPER + ALT + L", "Move window right", hl.dsp.window.move({ direction = "r" }))

-- Window Swapping (Vim keys)
o.bind("SUPER + CTRL + SHIFT + H", "Swap window left", hl.dsp.window.swap({ direction = "l" }))
o.bind("SUPER + CTRL + SHIFT + J", "Swap window down", hl.dsp.window.swap({ direction = "d" }))
o.bind("SUPER + CTRL + SHIFT + K", "Swap window up", hl.dsp.window.swap({ direction = "u" }))
o.bind("SUPER + CTRL + SHIFT + L", "Swap window right", hl.dsp.window.swap({ direction = "r" }))

-- Window Resizing (Vim keys)
o.bind("SUPER + SHIFT + H", "Resize left", hl.dsp.window.resize({ x = -100, y = 0, relative = true }))
o.bind("SUPER + SHIFT + J", "Resize down", hl.dsp.window.resize({ x = 0, y = 100, relative = true }))
o.bind("SUPER + SHIFT + K", "Resize up", hl.dsp.window.resize({ x = 0, y = -100, relative = true }))
o.bind("SUPER + SHIFT + L", "Resize right", hl.dsp.window.resize({ x = 100, y = 0, relative = true }))

-- ==============================================================================
-- Display & Zoom
-- ==============================================================================
o.bind("SUPER + SHIFT + mouse_down", "Zoom in", 'bash -c \'hyprctl keyword cursor:zoom_factor $(awk "BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep \\"float:\\" | awk \\"{print \\$2}\\") + 0.5}")\'', { mouse = true })
o.bind("SUPER + SHIFT + mouse_up", "Zoom out", 'bash -c \'hyprctl keyword cursor:zoom_factor $(awk "BEGIN {print $(hyprctl getoption cursor:zoom_factor | grep \\"float:\\" | awk \\"{print \\$2}\\") - 0.5}")\'', { mouse = true })
o.bind("SUPER + SHIFT + Z", "Reset zoom", "hyprctl keyword cursor:zoom_factor 1")

-- ==============================================================================
-- System Maintenance
-- ==============================================================================
o.bind("SUPER + ALT + C", "Clean memory", "uwsm-app -- clean-memory")
