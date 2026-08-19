-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- =============================================================================
-- Matchmaker (mm) Native Float Picker for Neovim
-- =============================================================================
local function mm_picker(preset)
  preset = preset or "nvim"
  local tmp = vim.fn.tempname()
  local cmd = string.format("mm -o %s > %s", preset, vim.fn.fnameescape(tmp))

  local buf = vim.api.nvim_create_buf(false, true)
  local width = math.floor(vim.o.columns * 0.85)
  local height = math.floor(vim.o.lines * 0.8)
  local row = math.floor((vim.o.lines - height) / 2)
  local col = math.floor((vim.o.columns - width) / 2)

  local win = vim.api.nvim_open_win(buf, true, {
    relative = "editor",
    width = width,
    height = height,
    row = row,
    col = col,
    style = "minimal",
    border = "rounded",
  })

  vim.fn.termopen(cmd, {
    on_exit = function()
      if vim.api.nvim_win_is_valid(win) then
        vim.api.nvim_win_close(win, true)
      end
      if vim.fn.filereadable(tmp) == 1 then
        local lines = vim.fn.readfile(tmp)
        vim.fn.delete(tmp)
        for _, line in ipairs(lines) do
          local target = vim.trim(line)
          if target ~= "" and vim.fn.filereadable(target) == 1 then
            vim.cmd("edit " .. vim.fn.fnameescape(target))
          elseif target ~= "" and vim.fn.isdirectory(target) == 1 then
            vim.cmd("cd " .. vim.fn.fnameescape(target))
          end
        end
      end
    end,
  })
  vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>mm", function() mm_picker("nvim") end, { desc = "Matchmaker File Picker" })
vim.keymap.set("n", "<leader>mj", function() mm_picker("jump") end, { desc = "Matchmaker Jump Picker" })

