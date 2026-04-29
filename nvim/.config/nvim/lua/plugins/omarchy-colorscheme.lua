-- Omarchy theme integration: automatically switches nvim colorscheme
-- when the omarchy theme changes. The active colorscheme name is written
-- to ~/.config/omarchy/current/theme/nvim-colorscheme by the theme-set hook.

local colorscheme_file = vim.fn.expand("~/.config/omarchy/current/theme/nvim-colorscheme")

local function read_omarchy_colorscheme()
  local f = io.open(colorscheme_file, "r")
  if not f then
    return nil
  end
  local line = f:read("*l")
  f:close()
  return line and vim.trim(line) or nil
end

return {
  -- Gruvbox
  {
    "ellisonleao/gruvbox.nvim",
    lazy = true,
    opts = { contrast = "soft" },
  },

  -- Osaka (osaka-jade and other osaka variants)
  {
    "craftzdog/solarized-osaka.nvim",
    lazy = true,
    opts = { style = "storm" },
  },

  -- Kanagawa
  {
    "rebelot/kanagawa.nvim",
    lazy = true,
    opts = {},
  },

  -- Everforest
  {
    "sainnhe/everforest",
    lazy = true,
  },

  -- Rose Pine
  {
    "rose-pine/neovim",
    name = "rose-pine",
    lazy = true,
    opts = {},
  },

  -- Nord
  {
    "shaunsingh/nord.nvim",
    lazy = true,
  },

  -- Override LazyVim default colorscheme with omarchy's active theme
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      local theme_map = {
        ["tokyo-night"] = "tokyonight",
        ["catppuccin"] = "catppuccin",
        ["catppuccin-latte"] = "catppuccin-latte",
        ["gruvbox"] = "gruvbox",
        ["osaka-jade"] = "solarized-osaka",
        ["kanagawa"] = "kanagawa",
        ["everforest"] = "everforest",
        ["rose-pine"] = "rose-pine",
        ["nord"] = "nord",
        -- themes without a direct nvim counterpart fall back to tokyonight
        ["ethereal"] = "tokyonight",
        ["flexoki-light"] = "catppuccin-latte",
        ["hackerman"] = "tokyonight-night",
        ["matte-black"] = "tokyonight-night",
        ["miasma"] = "kanagawa-dragon",
        ["ristretto"] = "rose-pine-moon",
        ["vantablack"] = "tokyonight-night",
        ["white"] = "catppuccin-latte",
      }

      local omarchy_theme = read_omarchy_colorscheme()
      if omarchy_theme and omarchy_theme ~= "" then
        opts.colorscheme = omarchy_theme
      else
        -- Derive from current omarchy theme name
        local theme_name_file = vim.fn.expand("~/.config/omarchy/current/theme/name")
        local tf = io.open(theme_name_file, "r")
        if tf then
          local name = vim.trim(tf:read("*l") or "")
          tf:close()
          local mapped = theme_map[name]
          if mapped then
            opts.colorscheme = mapped
          end
        end
      end
    end,
  },
}
