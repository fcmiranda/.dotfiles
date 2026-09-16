-- Image & Mermaid Diagram Hover Preview for Neovim
-- Enables floating popup previews for Mermaid diagrams and images when hovering the cursor on links/code blocks.
-- Ergonomics:
--   - 'K': Smart Universal Hover (previews image/mermaid if on link, falls back to LSP hover)
--   - '<leader>mi': Explicit Mermaid / Image Preview at cursor
--   - '<leader>uI': Toggle automatic float hover on cursor movement
--   - ':ImageHover': Command to trigger preview
--   - ':ImageHoverToggle': Command to toggle auto-hover

return {
  {
    "folke/snacks.nvim",
    opts = function(_, opts)
      opts = opts or {}

      -- Ensure Chromium / headless browser path for Puppeteer / Mermaid CLI (mmdc)
      local chromium_bin = vim.fn.exepath("chromium")
      if chromium_bin == "" then
        chromium_bin = vim.fn.exepath("google-chrome")
      end
      if chromium_bin == "" and vim.fn.filereadable("/usr/bin/chromium") == 1 then
        chromium_bin = "/usr/bin/chromium"
      end
      if chromium_bin ~= "" then
        vim.env.PUPPETEER_EXECUTABLE_PATH = chromium_bin
      end

      opts.image = vim.tbl_deep_extend("force", opts.image or {}, {
        enabled = true,
        formats = {
          "png",
          "jpg",
          "jpeg",
          "gif",
          "bmp",
          "webp",
          "tiff",
          "heic",
          "avif",
          "mp4",
          "mov",
          "avi",
          "mkv",
          "webm",
          "pdf",
          "icns",
          "svg",
          "mmd",
          "mermaid",
        },
        doc = {
          enabled = true,
          -- Render in sleek floating popup on cursor hover (no buffer clutter)
          inline = false,
          float = true,
          max_width = 80,
          max_height = 40,
        },
        convert = {
          notify = true,
          mermaid = function()
            local theme = vim.o.background == "light" and "neutral" or "dark"
            return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "{scale}" }
          end,
        },
      })

      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        snacks_image = {
          relative = "cursor",
          border = "rounded",
          title = " 󰄧 Mermaid / Image Preview ",
          title_pos = "center",
          focusable = false,
          backdrop = false,
          row = 1,
          col = 1,
        },
      })
    end,
    config = function(_, opts)
      require("snacks").setup(opts)

      -- 1. Patch convert.commands to map .mermaid -> mmdc directly
      local ok_convert, Convert = pcall(require, "snacks.image.convert")
      if ok_convert and Convert.convert then
        local dummy = Convert.convert({ src = "dummy.png" })
        local i = 1
        while true do
          local name, val = debug.getupvalue(dummy._resolve, i)
          if not name then
            break
          end
          if name == "commands" and type(val) == "table" then
            val["mermaid"] = val["mmd"]
            break
          end
          i = i + 1
        end
      end

      -- Helper to check if a target is a supported image or mermaid file
      local function is_supported_media(target)
        if not target or target == "" then
          return false
        end
        if target:find("mermaid%.ink") then
          return true
        end
        local clean = target:gsub("[%?#].*", "")
        local ext = vim.fn.fnamemodify(clean, ":e"):lower()
        return vim.tbl_contains(Snacks.image.config.formats or {}, ext)
      end

      -- 2. Enhanced at_cursor: Fixes upstream snacks.nvim line comparison bug (cursor[1] == range[1]),
      -- ensures injected treesitter parsers (e.g. markdown_inline) are parsed,
      -- and provides fallback detection for non-treesitter buffers and links.
      local Snacks = require("snacks")
      if Snacks.image and Snacks.image.doc then
        Snacks.image.doc.at_cursor = function(cb)
          local buf = vim.api.nvim_get_current_buf()
          local cursor = vim.api.nvim_win_get_cursor(0)
          local cursor_line = cursor[1]
          local cursor_col = cursor[2]

          local ok_p, parser = pcall(vim.treesitter.get_parser, buf)
          if ok_p and parser then
            pcall(function()
              parser:parse(true)
            end)
          end

          Snacks.image.doc.find(buf, function(imgs)
            for _, img in ipairs(imgs) do
              local range = img.range
              if range then
                -- Strict line check: cursor line must be within [start_line, end_line]
                local within_lines = cursor_line >= range[1] and cursor_line <= range[3]
                if within_lines then
                  if range[1] == range[3] then
                    -- Single-line image / link: cursor column must be within link bounds
                    if cursor_col >= range[2] and cursor_col <= range[4] then
                      return cb(img.src, img.pos)
                    end
                  else
                    -- Multi-line block (e.g. fenced mermaid diagram)
                    return cb(img.src, img.pos)
                  end
                end
              end
            end

            -- Fallback: detect links/paths directly at current cursor position
            local line = vim.api.nvim_get_current_line()
            local col = cursor_col + 1

            -- Markdown inline link: [label](path) or ![label](path)
            local init = 1
            while true do
              local s, e, _, target = line:find("!?%[([^%]]*)%]%(([^)]+)%)", init)
              if not s then
                break
              end
              if col >= s and col <= e then
                target = target:gsub("^<", ""):gsub(">$", "")
                if is_supported_media(target) then
                  local resolved = Snacks.image.doc.resolve(buf, target)
                  return cb(resolved, { cursor_line, s - 1 })
                end
              end
              init = e + 1
            end

            -- Quoted path / url: "...", '...', `...`
            for _, q in ipairs({ '"', "'", "`" }) do
              init = 1
              while true do
                local s, e, target = line:find(q .. "([^" .. q .. "]+)" .. q, init)
                if not s then
                  break
                end
                if col >= s and col <= e then
                  if is_supported_media(target) then
                    local resolved = Snacks.image.doc.resolve(buf, target)
                    return cb(resolved, { cursor_line, s - 1 })
                  end
                end
                init = e + 1
              end
            end

            -- Bare URL: https://...
            init = 1
            while true do
              local s, e = line:find("https?://[%w%-_%.%?!&=/%%+#~:]+", init)
              if not s then
                break
              end
              if col >= s and col <= e then
                local url = line:sub(s, e)
                if is_supported_media(url) then
                  return cb(url, { cursor_line, s - 1 })
                end
              end
              init = e + 1
            end

            cb()
          end, { from = cursor_line, to = cursor_line })
        end
      end

      -- 3. Smart Universal Hover Integration:
      -- Integrates with 'K'. If cursor is on a diagram or image link, preview it;
      -- otherwise smoothly fall back to LSP hover.
      local function smart_hover()
        if Snacks.image and Snacks.image.doc then
          Snacks.image.doc.at_cursor(function(src)
            if src then
              Snacks.image.doc.hover()
            else
              vim.lsp.buf.hover()
            end
          end)
        else
          vim.lsp.buf.hover()
        end
      end

      vim.keymap.set("n", "K", smart_hover, { desc = "Smart Hover (Mermaid/Image or LSP)" })
      vim.keymap.set("n", "<leader>mi", function()
        Snacks.image.hover()
      end, { desc = "Mermaid / Image Preview at Cursor" })

      -- Re-bind K when LSP attaches so LSP does not clobber smart hover
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("smart_image_hover_lsp", { clear = true }),
        callback = function(args)
          vim.keymap.set("n", "K", smart_hover, { buffer = args.buf, desc = "Smart Hover (Mermaid/Image or LSP)" })
        end,
      })

      -- 4. User Commands
      vim.api.nvim_create_user_command("ImageHover", function()
        Snacks.image.hover()
      end, { desc = "Hover preview for Mermaid diagram or Image at cursor" })

      local auto_hover_enabled = true
      vim.api.nvim_create_user_command("ImageHoverToggle", function()
        auto_hover_enabled = not auto_hover_enabled
        if auto_hover_enabled then
          Snacks.image.config.doc.float = true
          vim.notify("Auto Image Hover enabled", vim.log.levels.INFO, { title = "Image Hover" })
        else
          Snacks.image.config.doc.float = false
          if Snacks.image.doc and Snacks.image.doc.hover_close then
            Snacks.image.doc.hover_close()
          end
          vim.notify("Auto Image Hover disabled (use K or <leader>mi)", vim.log.levels.INFO, { title = "Image Hover" })
        end
      end, { desc = "Toggle automatic hover preview on cursor movement" })

      vim.keymap.set("n", "<leader>uI", "<cmd>ImageHoverToggle<cr>", { desc = "Toggle Auto Image Hover" })
    end,
  },
}
