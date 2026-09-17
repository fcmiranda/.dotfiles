-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

-- Sync clipboard with system clipboard
vim.opt.clipboard = "unnamedplus"

-- Safe clipboard provider for Wayland
-- Prevents binary image data (e.g. screenshots or copied images) from dumping raw bytes into text registers
if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
  vim.g.clipboard = {
    name = "wl-clipboard-safe",
    copy = {
      ["+"] = { "wl-copy", "--type", "text/plain" },
      ["*"] = { "wl-copy", "--primary", "--type", "text/plain" },
    },
    paste = {
      ["+"] = { "sh", "-c", "wl-paste --no-newline --type text/plain 2>/dev/null || true" },
      ["*"] = { "sh", "-c", "wl-paste --primary --no-newline --type text/plain 2>/dev/null || true" },
    },
    cache_enabled = 1,
  }
end
