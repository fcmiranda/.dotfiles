# Hyprland Animations Configuration

Detailed reference of the active animation configuration, cubic Bézier curves, and animation trees in this Hyprland + Omarchy environment.

---

## 1. Overview & General State

- **Animations Enabled**: `true`
- **Configuration Mechanism**: Configured via Omarchy's Lua configuration layer (`hl.config`, `hl.curve`, `hl.animation`).
- **Base Default Source**: [`/usr/share/omarchy/default/hypr/looknfeel.lua`](/usr/share/omarchy/default/hypr/looknfeel.lua)
- **User Overrides**: [`~/.config/hypr/looknfeel.lua`](/home/fecavmi/.config/hypr/looknfeel.lua)

---

## 2. Cubic Bézier Curves (`hl.curve`)

The following Bézier curves are registered for window and layer transitions:

| Curve Name | Control Points $(X_0, Y_0, X_1, Y_1)$ | Purpose / Characteristics |
| :--- | :--- | :--- |
| **`easeOutQuint`** | `(0.23, 1.00, 0.32, 1.00)` | Fast initial acceleration with smooth, natural deceleration for windows and borders. |
| **`easeInOutCubic`** | `(0.65, 0.05, 0.36, 1.00)` | Symmetrical acceleration and deceleration for smooth continuous transitions. |
| **`linear`** | `(0.00, 0.00, 1.00, 1.00)` | Constant velocity, used primarily for fast closing animations (`windowsOut`, `layersOut`). |
| **`almostLinear`** | `(0.50, 0.50, 0.75, 1.00)` | Subtle curve near linear for smooth opacity fades (`fadeIn`, `fadeOut`, `fadeLayers`). |
| **`quick`** | `(0.15, 0.00, 0.10, 1.00)` | Snappy responsive curve for general fade transitions. |
| **`default`** | `(0.00, 0.75, 0.15, 1.00)` | Hyprland default curve for global fallback. |

---

## 3. Active Animation Rules (`hl.animation`)

| Animation Target | Enabled | Speed | Bézier Curve | Style / Parameters | Description |
| :--- | :---: | :---: | :--- | :--- | :--- |
| **`global`** | `true` | `10.00` | `default` | — | Global fallback animation speed & curve. |
| **`windows`** | `true` | `3.79` | `easeOutQuint` | — | Base window transform tree. |
| **`windowsIn`** | `true` | `4.10` | `easeOutQuint` | `popin 87%` | Window open animation (pops in from 87% scale). |
| **`windowsOut`** | `true` | `1.49` | `linear` | `popin 87%` | Window close animation (fast linear fade/shrink to 87%). |
| **`fade`** | `true` | `3.03` | `quick` | — | Cross-fade on window property changes. |
| **`fadeIn`** | `true` | `1.73` | `almostLinear` | — | Window opacity ramp-up when opening. |
| **`fadeOut`** | `true` | `1.46` | `almostLinear` | — | Window opacity ramp-down when closing. |
| **`border`** | `true` | `5.39` | `easeOutQuint` | — | Border color transitions. |
| **`layers`** | `true` | `3.81` | `easeOutQuint` | — | Layer surface animation base (bars, notifications, menus). |
| **`layersIn`** | `true` | `4.00` | `easeOutQuint` | `fade` | Layer surface entrance fade. |
| **`layersOut`** | `true` | `1.50` | `linear` | `fade` | Fast linear fade on layer exit. |
| **`fadeLayersIn`** | `true` | `1.79` | `almostLinear` | — | Layer opacity ramp-up. |
| **`fadeLayersOut`** | `true` | `1.39` | `almostLinear` | — | Layer opacity ramp-down. |
| **`specialWorkspace`** | `true` | `3.00` | `easeOutQuint` | `slidevert` | Vertical slide for special scratchpad workspace. |
| **`workspaces`** | `false` | `1.00` | `default` | — | **Disabled** (workspace switching is instant for zero latency). |
| **`fadeSwitch`** | `false` | `1.00` | `default` | — | Disabled window fade switch. |

---

## 4. Customizing Animations

To customize or override animations without modifying system packages, edit [`hypr/.config/hypr/looknfeel.lua`](../../hypr/.config/hypr/looknfeel.lua):

### Example: Enable Workspace Slide Animations
```lua
-- Add to ~/.config/hypr/looknfeel.lua
hl.animation({ leaf = "workspaces", enabled = true, speed = 3.5, bezier = "easeOutQuint", style = "slide" })
```

### Example: Disable All Animations
```lua
-- Add to ~/.config/hypr/looknfeel.lua
hl.config({
  animations = {
    enabled = false,
  },
})
```

---

## 5. Inspection & Validation Commands

```bash
# View active live animation state from Hyprland IPC
hyprctl animations

# Reload Hyprland configuration
hyprctl reload

# Validate config syntax and check for errors
hyprctl configerrors
```
