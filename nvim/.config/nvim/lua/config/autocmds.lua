-- Autocmds are automatically loaded on the VeryLazy event
-- Default autocmds that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/autocmds.lua
--
-- Add any additional autocmds here
-- with `vim.api.nvim_create_autocmd`
--
-- Or remove existing autocmds by their group name (which is prefixed with `lazyvim_` for the defaults)
-- e.g. vim.api.nvim_del_augroup_by_name("lazyvim_wrap_spell")

-- Watch omarchy theme changes and reload colorscheme live
local neovim_lua_file = vim.fn.expand("~/.config/omarchy/current/theme/neovim.lua")

local function read_omarchy_colorscheme()
  local f = io.open(neovim_lua_file, "r")
  if not f then return nil end
  local content = f:read("*a")
  f:close()
  local cs = content:match('colorscheme%s*=%s*"([^"]+)"')
  return cs and vim.trim(cs) or nil
end

local w = vim.uv.new_fs_event()
if w then
  w:start(vim.fn.expand("~/.config/omarchy/current"), {}, function(err, fname)
    if err or fname ~= "theme.name" then return end
    vim.schedule(function()
      local cs = read_omarchy_colorscheme()
      if not cs or cs == "" then return end

      local ok, specs = pcall(dofile, neovim_lua_file)
      if not (ok and type(specs) == "table") then return end

      local lazy_data = vim.fn.stdpath("data") .. "/lazy"
      local missing = {}
      for _, spec in ipairs(specs) do
        local plugin = type(spec[1]) == "string" and spec[1] or nil
        if plugin and plugin ~= "LazyVim/LazyVim" then
          local short = plugin:match("[^/]+$")
          if vim.fn.isdirectory(lazy_data .. "/" .. short) == 1 then
            require("lazy").load({ plugins = { short } })
          else
            table.insert(missing, short)
          end
        end
      end

      if #missing > 0 then
        vim.notify(
          "Installing theme plugins: " .. table.concat(missing, ", ") .. "\nRestart nvim when done.",
          vim.log.levels.INFO,
          { title = "Omarchy theme" }
        )
        vim.fn.jobstart({ "nvim", "--headless", "+Lazy! sync", "+qa" }, {
          on_exit = function(_, code)
            if code == 0 then
              vim.schedule(function()
                vim.notify(
                  "Theme plugins installed. Restart nvim to apply colorscheme.",
                  vim.log.levels.INFO,
                  { title = "Omarchy theme" }
                )
              end)
            end
          end,
        })
      else
        pcall(vim.cmd, "colorscheme " .. cs)
      end
    end)
  end)
end
