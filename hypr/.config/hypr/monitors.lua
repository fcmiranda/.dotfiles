-- See https://wiki.hypr.land/Configuring/Basics/Monitors/
-- List current monitors and supported resolutions with: hyprctl monitors all

local function read_file(path)
  local f = io.open(path, "r")
  if not f then return "" end
  local content = f:read("*a") or ""
  f:close()
  return content:gsub("%z", ""):gsub("^%s+", ""):gsub("%s+$", "")
end

local function is_apple_machine()
  -- Apple Silicon MacBooks (M1/M2/M3) have devicetree model (e.g. Apple MacBook Air (M1, 2020))
  local dt_model = read_file("/proc/device-tree/model"):lower()
  if dt_model:find("macbook") or dt_model:find("apple") then
    return true
  end

  -- Intel MacBooks have DMI product_name or sys_vendor
  local dmi_product = read_file("/sys/class/dmi/id/product_name"):lower()
  local dmi_vendor = read_file("/sys/class/dmi/id/sys_vendor"):lower()
  if dmi_product:find("macbook") or dmi_vendor:find("apple") then
    return true
  end

  return false
end

-- Automatic scale per machine:
-- MacBook (M1/Retina) -> scale 2 (HiDPI)
-- Dell Inspiron 14R (5437) / standard laptops -> scale 1
local default_scale = is_apple_machine() and 2 or 1

local omarchy_gdk_scale = default_scale
local omarchy_monitor_scale = default_scale

hl.env("GDK_SCALE", tostring(omarchy_gdk_scale))
hl.monitor({ output = "", mode = "preferred", position = "auto", scale = omarchy_monitor_scale })

-- Configure a specific monitor.
-- Dell Inspiron 14R (1366x768):
-- hl.monitor({ output = "desc:Chimei Innolux Corporation 0x1476", mode = "preferred", position = "auto", scale = 1 })
-- hl.monitor({ output = "DP-2", mode = "2560x1440@144", position = "0x0", scale = 1 })

-- Portrait/rotated secondary monitor (transform: 1 = 90°, 3 = 270°).
-- hl.monitor({ output = "DP-2", mode = "preferred", position = "auto", scale = 1, transform = 1 })
