# MacBook Notch Configuration

This document outlines the configurations implemented to enable full-screen notch support and a custom split-bar layout for Apple Silicon MacBooks (e.g., MacBook M1/M2/M3 models) running Linux under the **Omarchy** dotfiles setup.

---

## 1. Kernel Configuration (GRUB Command Line)

By default, Linux distributions on Apple Silicon (such as Asahi Linux) hide the physical display notch by treating that area of the screen as non-existent. This effectively chops off the top portion of the display, resulting in a thick black bar across the top.

To reclaim the vertical screen area beside the notch (the "ears"), the kernel must be configured to expose the full physical screen resolution.

### Steps to Enable:
1. Open `/etc/default/grub` with root privileges:
   ```bash
   sudo nvim /etc/default/grub
   ```
2. Locate the `GRUB_CMDLINE_LINUX_DEFAULT` line and append `appledrm.show_notch=1` to the options:
   ```bash
   GRUB_CMDLINE_LINUX_DEFAULT="loglevel=3 quiet splash appledrm.show_notch=1"
   ```
   > [!NOTE]
   > On older kernels, this parameter was named `apple_dcp.show_notch=1`. For modern Asahi Linux kernels, `appledrm.show_notch=1` is the correct parameter.

3. Rebuild the GRUB configuration:
   ```bash
   sudo grub-mkconfig -o /boot/grub/grub.cfg
   ```
4. **Reboot** the system to apply the kernel parameter.

---

## 2. Dynamic Hardware Detection (`setup-waybar.sh`)

Once the notch area is exposed to the display manager, the status bar (Waybar) must adapt so that its elements do not get hidden behind the physical notch cutout. 

To achieve this dynamically, we introduced a hardware detection script:
* **Script Location:** `waybar/.config/waybar/setup-waybar.sh`
* **Trigger:** Configured in `hypr/.config/hypr/autostart.conf` to run once during Hyprland startup:
  ```ini
  exec-once = ~/.config/waybar/setup-waybar.sh
  ```

### How the Script Works:
1. It inspects `/sys/firmware/devicetree/base/model` for the keyword `macbook`.
2. **If a MacBook is detected:**
   - It symlinks `~/.config/waybar/config.jsonc` to the notch-friendly `config.jsonc.macbook` configuration.
   - It symlinks `~/.config/waybar/style.css` to the floating-pill `style.css.macbook` stylesheet.
3. **Otherwise (Standard hardware):**
   - It symlinks them back to `config.jsonc.default` and `style.css.default`.
4. **Waybar Auto-Restart:**
   - If the symlink target changes from what was previously set, the script automatically triggers `omarchy-restart-waybar` to apply the layout immediately.

---

## 3. Split Waybar Configuration (`config.jsonc.macbook`)

The MacBook-specific Waybar config splits the panel into two distinct blocks on the left and right, leaving a completely blank gap in the middle where the physical notch sits.

* **Thinner Bar Height:** The height of the bar is set to `32` (decreased from `36`) to make the bar thinner, allowing window content and application borders to sit closer to the top and align cleanly with the notch boundary.
* **Modules Left (`modules-left`):**
  - Displays the Omarchy launcher menu, workspaces tracker, active Spotify track, and the OpenCode state.
* **Modules Center (`modules-center`):**
  - Contains only a single custom module `custom/notch-spacer`.
  - **Notch Spacer Definition:**
    ```json
    "custom/notch-spacer": {
      "format": " ",
      "tooltip": false
    }
    ```
* **Modules Right (`modules-right`):**
  - Groups indicators (screen recording, system updates, CAVA visualizer, Bluetooth, Wi-Fi, volume, CPU load, perf profile, battery, and clock).

---

## 4. Minimalist Spacer & Edge Alignment (`style.css.macbook`)

To optimize screen space and bring window borders closer to the notch area, the floating background capsules (pills) are removed, leaving a clean, integrated status line.

* **Base Import:**
  - Imports the original style rules so we don't duplicate code:
    ```css
    @import "style.css.default";
    ```
* **Transparent Panel:**
  - Sets the global Waybar container background to transparent so the items blend directly:
    ```css
    window#waybar {
      background: transparent;
    }
    ```
* **Spacer Width:**
  - Forces `#custom-notch-spacer` to be a transparent box with a minimum width corresponding to the physical notch:
    ```css
    #custom-notch-spacer {
      background: transparent;
      border: none;
      min-width: 200px; /* Adjusted for 14" MacBook Pro Notch width */
      padding: 0;
      margin: 0;
    }
    ```
* **Edge Margin/Padding Adjustment:**
  - Removes the background capsules to let modules float naturally and adds a right-edge padding adjustment to align the system tray/clock properly at the screen border:
    ```css
    window#waybar.top .modules-right {
      padding: 0 20px 0 0;
    }
    ```
