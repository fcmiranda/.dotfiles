# Dynamic Context-Aware Workspace Pills

This document explains the architecture and implementation of the **Dynamic Context-Aware Workspace Pills** in Quickshell (`fecavmi.workspaces`), providing semantic app icon representations and real-time title-aware tab tracking for Hyprland.

---

## 💡 Concept & Terminology

### What is it called?
In modern tiling window manager environments (Hyprland, Wayland, Sway, AeroSpace), this feature is known as:
- **Dynamic Context-Aware Workspace Pills**
- **Semantic Window Icon Rewriting**
- **Title-Aware Window Pattern Matching**

Rather than displaying static workspace numbers (`1`, `2`, `3`), the top bar workspaces widget renders interactive capsule-shaped "pills" containing the Nerd Font icons of all active applications in that workspace. When browsing web applications (such as switching tabs between YouTube and GitHub), the icon automatically updates to match the active tab's semantic identity.

---

## ⚙️ How the Detection Works

The mechanism relies on real-time event-driven IPC between Hyprland, Wayland protocols, and Quickshell's reactive QML engine.

```
┌─────────────────────────────────────────────────────────────┐
│                       Hyprland WM                           │
│  (Window creation, tab switch, URL change, workspace focus) │
└──────────────────────────────┬──────────────────────────────┘
                               │ IPC Socket Events
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                 Quickshell Hyprland Engine                  │
│       `Hyprland.workspaces` ───► `workspace.toplevels`      │
└──────────────────────────────┬──────────────────────────────┘
                               │ QML Property Binding
                               ▼
┌─────────────────────────────────────────────────────────────┐
│               `Workspaces.qml` Pill Evaluator               │
│                                                             │
│   1. Title Match   : "YouTube" ──► 󰗃, "GitHub" ──► 󰊤         │
│   2. Class Match   : "google-chrome" ──► , "ghostty" ──►  │
│   3. Heuristic     : Title substring fallback               │
│   4. Default       :  (Unknown App) / Workspace # (Empty)  │
└──────────────────────────────┬──────────────────────────────┘
                               │ Reactive Rendering
                               ▼
┌─────────────────────────────────────────────────────────────┐
│                   Top Bar Workspace Pills                   │
│               [  ]   [  󰗃 ]   [ 󰲇 ]   [ 4 ]               │
└─────────────────────────────────────────────────────────────┘
```

### 1. Event-Driven Reactivity (Zero Polling)
- **Hyprland IPC Events**: Whenever you change a browser tab, navigate to a new site, or focus a window, Hyprland emits an IPC notification updating the window's `title` and `lastIpcObject`.
- **QML Bindable Properties**: In Qt/Quickshell, properties such as `workspace.toplevels` and `toplevel.title` are reactive bindings (`QObjectBindableProperty`).
- Whenever Hyprland updates the title string, Quickshell's QML engine immediately triggers a re-evaluation of `getWorkspaceLabel()` without any timers, scripts, or polling loops.

### 2. Hierarchical Matching Pipeline

Inside [`omarchy/.config/omarchy/plugins/fecavmi.workspaces/Workspaces.qml`](../../omarchy/.config/omarchy/plugins/fecavmi.workspaces/Workspaces.qml), the `iconForToplevel()` function evaluates the window metadata through a 4-tier hierarchy:

#### Tier 1: Semantic Title Patterns (Webapps & Special States)
Web browsers share a common class (`google-chrome`, `firefox`), but different tabs represent distinct web apps. Tier 1 matches specific patterns in the window title:

| Pattern in `title` | Mapped Icon | Description |
| :--- | :---: | :--- |
| `youtube` | `󰗃` | YouTube video or music tab |
| `github`, `github.io`, `/ repositories`, `pull request(s)`, `issues ·`, `commits ·`, `releases ·` | `󰊤` | GitHub repositories, PRs, SPA pages, or GitHub Pages |
| `google photos` | `󰋩` | Google Photos gallery |
| `chatgpt` / `grok` | `󰚩` | AI Chat interfaces |
| `whatsapp` | `󰖣` | WhatsApp Web |
| `google messages` | `󰭹` | SMS / Chat |
| `is sharing your screen` | `󰹑` | Screen recording / sharing indicator |

#### Tier 2: Application Class Mapping (`appId` / `class`)
For desktop applications, Tier 2 checks the compositor class identifiers:

| App Category | Matching Identifiers (`cls`) | Icon |
| :--- | :--- | :---: |
| **Terminals** | `ghostty`, `kitty` (Theme-Aware Vector SVGs / `app:`), `foot`, `alacritty`, `agent` | `app:com.mitchellh.ghostty` / `app:kitty` / `` / `󱚤` |
| **Browsers** | `google-chrome`, `chromium`, `brave`, `firefox`, `zen` | `` / `` |
| **Editors & IDEs** | `antigravity-ide` (Theme-Aware `app:`), `code`, `vscode`, `nvim`, `obsidian` | `app:antigravity-ide` / `` / `` / `󰈙` |
| **Communication** | `discord`, `vesktop`, `telegram`, `signal`, `thunderbird` | `` / `` / `󰭹` / `` |
| **Media & Audio** | `spotify`, `steam`, `vlc`, `mpv` | `` / `` / `󰕼` / `` |
| **File Managers** | `nautilus`, `dolphin`, `thunar`, `yazi` | `` |
| **Omarchy TUIs** | `impala`, `bluetui`, `wiremix`, `btop`, `lazydocker`, `lazygit` | `󰤨` / `󰂰` / `󰕾` / `󰍛` / `󰡨` / `󰊢` |

#### Tier 3: Title Heuristics Fallback
If the application class is wrapped or unavailable, Tier 3 searches the title string for common application signatures (e.g. `"chrome"`, `"bash"`, `"spotify"`).

#### Tier 4: Graceful Default
- Unrecognized open windows: `` (Generic window icon).
- Empty workspaces: Minimal numeric indicator (`0`, `1`, `2`, `3`, etc.) with `0.45` dimmed opacity.

---

## 🎨 Visual Pill Design & States

Each workspace item is wrapped in an adaptive `Rectangle` container:

```qml
Rectangle {
  id: pillRect
  height: root.barSize - 8
  radius: height / 2
  implicitWidth: Math.max(height, label.implicitWidth + 14)

  color: focused ? Util.alpha(Color.accent, 0.22)
       : mouseArea.containsMouse ? Util.alpha(Color.foreground, 0.12)
       : occupied ? Util.alpha(Color.foreground, 0.06) : "transparent"

  border.color: focused ? Color.accent
              : mouseArea.containsMouse ? Util.alpha(Color.foreground, 0.3)
              : occupied ? Util.alpha(Color.foreground, 0.15) : "transparent"
  border.width: focused ? 1.5 : (occupied ? 1 : 0)
}
```

1. **Focused (Active Workspace)**:
   - Full accent border (`border.width: 1.5`, `border.color: Color.accent`).
   - Tinted background (`Util.alpha(Color.accent, 0.22)`).
   - Accent text color.
2. **Occupied (Inactive with Windows)**:
   - Subtle background pill (`Util.alpha(Color.foreground, 0.06)`).
   - Soft border (`Util.alpha(Color.foreground, 0.15)`).
   - Full opacity app icons.
3. **Empty (Inactive without Windows)**:
   - Borderless transparent pill.
   - Low-contrast workspace number (`opacity: 0.45`).
4. **Interactive**:
   - `Qt.PointingHandCursor` on hover with smooth color transition.
   - Left-click executes `hyprctl dispatch hl.dsp.focus(...)` to switch workspaces instantly.

---

## 🛠️ Configuration & Customization

The plugin files are located in the dotfiles worktree:
- **Plugin Manifest**: [`omarchy/.config/omarchy/plugins/fecavmi.workspaces/manifest.json`](../../omarchy/.config/omarchy/plugins/fecavmi.workspaces/manifest.json)
- **QML Implementation**: [`omarchy/.config/omarchy/plugins/fecavmi.workspaces/Workspaces.qml`](../../omarchy/.config/omarchy/plugins/fecavmi.workspaces/Workspaces.qml)
- **Active Shell Layout**: [`~/.config/omarchy/shell.json`](../../omarchy/.config/omarchy/shell.json)

### Restarting the Shell
To reload changes made to the workspace widget:
```bash
omarchy restart shell
```
