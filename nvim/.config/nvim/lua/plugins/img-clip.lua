-- Image Clipboard Paste for Neovim (img-clip.nvim)
-- Automatically saves images from system clipboard (Wayland/X11) to assets/
-- and inserts markdown syntax with the alt text pre-selected in Select Mode (like VS Code).
--
-- Interactions:
--   - 'p' in Markdown: Smart Paste (pastes image if clipboard has image, else normal text paste)
--   - 'P' in Markdown: Smart Paste before cursor (pastes image if clipboard has image, else normal text paste)
--   - '<C-v>' in Insert Mode: Smart Paste image or clipboard register
--   - '<leader>p' or '<leader>ip': Explicit Paste Image command
--   - ':PasteImage': User command

local function is_image_magic(data)
  if not data or type(data) ~= "string" or #data < 4 then
    return false
  end
  -- PNG magic bytes: \x89PNG
  if data:sub(1, 4) == "\137PNG" then
    return true
  end
  -- JPEG magic bytes: \xFF\xD8\xFF
  if data:sub(1, 3) == "\255\216\255" then
    return true
  end
  -- GIF magic bytes: GIF87a / GIF89a
  if data:sub(1, 4) == "GIF8" then
    return true
  end
  -- BMP magic bytes: BM
  if data:sub(1, 2) == "BM" then
    return true
  end
  -- WebP magic bytes: RIFF....WEBP
  if #data >= 12 and data:sub(1, 4) == "RIFF" and data:sub(9, 12) == "WEBP" then
    return true
  end
  return false
end

local function is_binary_string(s)
  if not s or type(s) ~= "string" or s == "" then
    return false
  end
  if is_image_magic(s) then
    return true
  end
  -- Detect unprintable control bytes / null characters
  if s:find("[%z\1-\8\11\12\14-\31]") then
    return true
  end
  return false
end

local function is_clipboard_image()
  -- 1. Check Wayland clipboard types
  if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
    local types = vim.fn.system("wl-paste --list-types 2>/dev/null") or ""
    if types:find("image/", 1, true) then
      return true
    end
  end

  -- 2. Check X11 clipboard types
  if vim.env.DISPLAY and vim.fn.executable("xclip") == 1 then
    local types = vim.fn.system("xclip -selection clipboard -t TARGETS -o 2>/dev/null") or ""
    if types:find("image/", 1, true) then
      return true
    end
  end

  -- 3. Check registers for raw image magic bytes (PNG, JPEG, GIF, BMP, WebP)
  for _, reg in ipairs({ "+", "*", '"' }) do
    local content = vim.fn.getreg(reg)
    if is_image_magic(content) then
      return true
    end
  end

  return false
end

return {
  {
    "HakonHarnes/img-clip.nvim",
    lazy = false,
    cmd = { "PasteImage", "ImgClipConfig" },
    opts = {
      default = {
        dir_path = "assets",
        relative_to_current_file = true,
        extension = "png",
        file_name = "%Y-%m-%d-%H-%M-%S",
        use_absolute_path = false,
        prompt_for_file_name = false,
        insert_mode_after_paste = false,
        verbose = false,
      },
      filetypes = {
        markdown = {
          url_encode_path = true,
          template = "![image]($FILE_PATH)",
          download_images = false,
        },
      },
    },
    keys = {
      { "<leader>p", desc = "Paste Image from Clipboard (Alt Selected)" },
      { "<leader>ip", desc = "Paste Image from Clipboard" },
    },
    init = function()
      -- Safe Wayland clipboard provider to prevent raw binary dumping into text registers
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
    end,
    config = function(_, opts)
      local img_clip = require("img-clip")
      img_clip.setup(opts)

      -- Monkey-patch img-clip clipboard functions to support ALL image formats on Wayland
      local ok_clip, clip = pcall(require, "img-clip.clipboard")
      if ok_clip and clip then
        local orig_content_is_image = clip.content_is_image
        clip.content_is_image = function()
          if is_clipboard_image() then
            return true
          end
          return orig_content_is_image()
        end

        local orig_save_image = clip.save_image
        clip.save_image = function(file_path)
          local ok = orig_save_image(file_path)
          if ok and vim.fn.filereadable(file_path) == 1 and (vim.fn.getfsize(file_path) or 0) > 0 then
            return true
          end

          -- Multi-format Wayland fallback with ImageMagick conversion if needed
          if vim.env.WAYLAND_DISPLAY and vim.fn.executable("wl-paste") == 1 then
            local types = vim.fn.system("wl-paste --list-types 2>/dev/null") or ""
            local image_mimes = { "image/png", "image/jpeg", "image/webp", "image/gif", "image/bmp", "image/tiff" }
            for _, mime in ipairs(image_mimes) do
              if types:find(mime, 1, true) then
                local cmd
                if vim.fn.executable("magick") == 1 then
                  cmd = string.format("wl-paste --type %s 2>/dev/null | magick - %s", vim.fn.shellescape(mime), vim.fn.shellescape(file_path))
                else
                  cmd = string.format("wl-paste --type %s 2>/dev/null > %s", vim.fn.shellescape(mime), vim.fn.shellescape(file_path))
                end
                vim.fn.system(cmd)
                if vim.v.shell_error == 0 and vim.fn.filereadable(file_path) == 1 and (vim.fn.getfsize(file_path) or 0) > 0 then
                  return true
                end
              end
            end
          end

          -- Register fallback if register contains raw image bytes
          for _, reg in ipairs({ "+", "*", '"' }) do
            local content = vim.fn.getreg(reg)
            if is_image_magic(content) then
              local f = io.open(file_path, "wb")
              if f then
                f:write(content)
                f:close()
                if vim.fn.filereadable(file_path) == 1 and (vim.fn.getfsize(file_path) or 0) > 0 then
                  return true
                end
              end
            end
          end

          return false
        end
      end

      -- Select alt text inside ![...] in Select Mode (like VS Code)
      local function select_alt_text()
        local row = vim.api.nvim_win_get_cursor(0)[1]
        local total_rows = vim.api.nvim_buf_line_count(0)
        local target_row, start_b, end_b = nil, nil, nil

        for _, r in ipairs({ row, row - 1, row + 1, row - 2, row + 2 }) do
          if r >= 1 and r <= total_rows then
            local line = vim.api.nvim_buf_get_lines(0, r - 1, r, false)[1] or ""
            local s, e = line:find("%!%[[^%]]*%]")
            if s and e then
              target_row = r
              start_b = s
              end_b = e
              break
            end
          end
        end

        if target_row and start_b and end_b then
          vim.api.nvim_win_set_cursor(0, { target_row, start_b + 1 })
          local keys = vim.api.nvim_replace_termcodes("vi]<C-g>", true, false, true)
          vim.api.nvim_feedkeys(keys, "x", false)
        end
      end

      -- Function to paste image and immediately select the alt text in Select Mode (like VS Code)
      local function paste_image_with_alt_selection(api_opts)
        local ok = img_clip.paste_image(api_opts)
        if ok then
          select_alt_text()
          if vim.api.nvim_get_mode().mode ~= "s" then
            vim.schedule(select_alt_text)
          end
        end
        return ok
      end

      -- User commands
      vim.api.nvim_create_user_command("PasteImage", function()
        paste_image_with_alt_selection()
      end, { desc = "Paste image from system clipboard with alt text selected" })

      -- Dedicated keymaps
      vim.keymap.set("n", "<leader>p", function()
        paste_image_with_alt_selection()
      end, { desc = "Paste Image from Clipboard (Alt Selected)" })

      vim.keymap.set("n", "<leader>ip", function()
        paste_image_with_alt_selection()
      end, { desc = "Paste Image from Clipboard" })

      local function bind_buffer_smart_paste(buf)
        if not vim.api.nvim_buf_is_valid(buf) then
          return
        end
        if vim.b[buf].img_clip_smart_paste_bound then
          return
        end
        vim.b[buf].img_clip_smart_paste_bound = true

        local function get_paste_reg_prefix()
          local reg = vim.v.register
          if reg and reg ~= '"' then
            return '"' .. reg
          end
          local plus = vim.fn.getreg("+")
          if plus and plus ~= "" then
            return '"+'
          end
          return '""'
        end

        -- Smart paste on 'p' (after cursor)
        vim.keymap.set("n", "p", function()
          if is_clipboard_image() then
            paste_image_with_alt_selection({ insert_template_after_cursor = true })
          else
            local reg = vim.v.register
            local reg_content = (reg and reg ~= '"') and vim.fn.getreg(reg) or vim.fn.getreg("+")
            if is_binary_string(reg_content) and not is_image_magic(reg_content) then
              vim.notify("Clipboard contains raw binary data, paste cancelled.", vim.log.levels.WARN)
              return
            end
            local reg_prefix = get_paste_reg_prefix()
            vim.cmd('execute "normal! " . v:count1 . ' .. vim.inspect(reg_prefix) .. ' . "p"')
          end
        end, { buffer = buf, desc = "Smart Paste (Image or Text)" })

        -- Smart paste on 'P' (before cursor)
        vim.keymap.set("n", "P", function()
          if is_clipboard_image() then
            paste_image_with_alt_selection({ insert_template_after_cursor = false })
          else
            local reg = vim.v.register
            local reg_content = (reg and reg ~= '"') and vim.fn.getreg(reg) or vim.fn.getreg("+")
            if is_binary_string(reg_content) and not is_image_magic(reg_content) then
              vim.notify("Clipboard contains raw binary data, paste cancelled.", vim.log.levels.WARN)
              return
            end
            local reg_prefix = get_paste_reg_prefix()
            vim.cmd('execute "normal! " . v:count1 . ' .. vim.inspect(reg_prefix) .. ' . "P"')
          end
        end, { buffer = buf, desc = "Smart Paste Before (Image or Text)" })

        -- Smart paste in Insert Mode: <C-v>
        vim.keymap.set("i", "<C-v>", function()
          if is_clipboard_image() then
            vim.cmd("stopinsert")
            paste_image_with_alt_selection({ insert_template_after_cursor = true })
          else
            local keys = vim.api.nvim_replace_termcodes("<C-r>+", true, false, true)
            vim.api.nvim_feedkeys(keys, "n", false)
          end
        end, { buffer = buf, desc = "Smart Paste Insert (Image or Text)" })
      end

      local target_fts = { "markdown", "text", "rmd", "quarto" }

      -- Attach immediately to all existing matching buffers
      for _, buf in ipairs(vim.api.nvim_list_bufs()) do
        if vim.api.nvim_buf_is_valid(buf) and vim.tbl_contains(target_fts, vim.bo[buf].filetype) then
          bind_buffer_smart_paste(buf)
        end
      end

      -- Attach to future buffers on FileType and BufEnter
      local group = vim.api.nvim_create_augroup("smart_image_paste", { clear = true })
      vim.api.nvim_create_autocmd("FileType", {
        pattern = target_fts,
        group = group,
        callback = function(args)
          bind_buffer_smart_paste(args.buf)
        end,
      })

      vim.api.nvim_create_autocmd("BufEnter", {
        pattern = "*",
        group = group,
        callback = function(args)
          if vim.tbl_contains(target_fts, vim.bo[args.buf].filetype) then
            bind_buffer_smart_paste(args.buf)
          end
        end,
      })
    end,
  },
}
