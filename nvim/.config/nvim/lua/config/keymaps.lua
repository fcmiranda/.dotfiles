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

-- =============================================================================
-- Reopen Last Closed Buffer (<leader>br / <C-S-t>)
-- =============================================================================
local closed_buffers = {}

vim.api.nvim_create_autocmd("BufDelete", {
  group = vim.api.nvim_create_augroup("ReopenClosedBuffer", { clear = true }),
  callback = function(args)
    local name = vim.api.nvim_buf_get_name(args.buf)
    if name ~= "" and vim.fn.filereadable(name) == 1 then
      table.insert(closed_buffers, name)
      if #closed_buffers > 25 then
        table.remove(closed_buffers, 1)
      end
    end
  end,
})

local function reopen_closed_buffer()
  while #closed_buffers > 0 do
    local file = table.remove(closed_buffers)
    if vim.fn.filereadable(file) == 1 then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
      vim.notify("Reopened: " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
      return
    end
  end
  -- Fallback to recent files (oldfiles)
  local oldfiles = vim.v.oldfiles or {}
  for _, file in ipairs(oldfiles) do
    if vim.fn.filereadable(file) == 1 and vim.fn.bufnr(file) == -1 then
      vim.cmd("edit " .. vim.fn.fnameescape(file))
      vim.notify("Reopened (history): " .. vim.fn.fnamemodify(file, ":t"), vim.log.levels.INFO)
      return
    end
  end
  vim.notify("No closed buffers to reopen", vim.log.levels.WARN)
end

vim.keymap.set("n", "<leader>br", reopen_closed_buffer, { desc = "Reopen Last Closed Buffer" })
vim.keymap.set("n", "<C-S-t>", reopen_closed_buffer, { desc = "Reopen Last Closed Buffer" })


