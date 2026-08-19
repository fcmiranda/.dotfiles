-- Keymaps are automatically loaded on the VeryLazy event
-- Default keymaps that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/keymaps.lua
-- Add any additional keymaps here

-- =============================================================================
-- Matchmaker (mm) Native Float Picker for Neovim
-- =============================================================================
local function mm_open_file()
  local tmp = vim.fn.tempname()
  local cmd = string.format("mm > %s", tmp)

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
      vim.api.nvim_win_close(win, true)
      if vim.fn.filereadable(tmp) == 1 then
        local lines = vim.fn.readfile(tmp)
        vim.fn.delete(tmp)
        if lines[1] and #lines[1] > 0 then
          vim.cmd("edit " .. vim.fn.fnameescape(lines[1]))
        end
      end
    end,
  })
  vim.cmd("startinsert")
end

vim.keymap.set("n", "<leader>fm", mm_open_file, { desc = "Matchmaker Find Files" })
vim.keymap.set("n", "<leader>mm", mm_open_file, { desc = "Matchmaker Picker" })

