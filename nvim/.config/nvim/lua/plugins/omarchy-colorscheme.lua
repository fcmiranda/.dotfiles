-- Omarchy theme integration: automatically switches nvim colorscheme
-- by reading the colorscheme name directly from the active neovim.lua theme file.

local neovim_lua_file = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

local function read_omarchy_colorscheme()
  local f = io.open(neovim_lua_file, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local cs = content:match('colorscheme%s*=%s*"([^"]+)"')
  return cs and vim.trim(cs) or nil
end

return {


  -- Override LazyVim default colorscheme with omarchy's active theme
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      local cs = read_omarchy_colorscheme()
      if cs and cs ~= "" then opts.colorscheme = cs end
    end,
  },

}
