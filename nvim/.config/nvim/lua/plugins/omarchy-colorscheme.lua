-- Omarchy theme integration: loads the full plugin spec from the active
-- neovim.lua theme file so lazy properly manages (and never cleans) theme plugins.

local neovim_lua_file = vim.fn.expand("~/.local/state/omarchy/current/theme/neovim.lua")
if vim.fn.filereadable(neovim_lua_file) == 0 then
  neovim_lua_file = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")
end

local ok, specs = pcall(dofile, neovim_lua_file)
if ok and type(specs) == "table" then
  return specs
end

-- Fallback if the theme file is missing or invalid
return {
  { "LazyVim/LazyVim", opts = {} },
}
