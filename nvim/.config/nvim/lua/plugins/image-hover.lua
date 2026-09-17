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
          float = false, -- Default to false (on-demand via K; no auto-popup spam while editing)
          max_width = 80,
          max_height = 40,
        },
        convert = {
          notify = false,
          mermaid = function()
            local theme = vim.o.background == "light" and "neutral" or "dark"
            return { "-i", "{src}", "-o", "{file}", "-b", "transparent", "-t", theme, "-s", "{scale}" }
          end,
        },
      })

      opts.styles = vim.tbl_deep_extend("force", opts.styles or {}, {
        snacks_image = {
          relative = "editor",
          position = "float",
          border = "rounded",
          title = " 󰄧 Mermaid / Image Preview ",
          title_pos = "center",
          focusable = false,
          backdrop = false,
          col = -1, -- Sidecar layout: right margin leaves the code 100% visible on the left
          row = 1,  -- Top-aligned in the editor viewport
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

      -- 3. Auto-Hover Control & Smart Universal Hover Integration:
      -- By default, auto_hover_enabled is false for a clean, distraction-free editing experience.
      -- Hovering on-demand via 'K' or '<leader>mi' always works instantly.
      -- Toggle automatic hovering on cursor movement anytime via '<leader>uI'.
      -- 3. Smart Universal Hover Integration:
      -- 'K' previews image/mermaid in Sidecar if cursor is on link/block; falls back to LSP hover otherwise.
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

      vim.keymap.set("n", "K", smart_hover, { desc = "Smart Hover (Mermaid/Image Sidecar or LSP)" })
      vim.keymap.set("n", "<leader>mi", function()
        if Snacks.image and Snacks.image.doc then
          Snacks.image.doc.hover()
        end
      end, { desc = "Mermaid / Image Sidecar Preview at Cursor" })

      -- Re-bind K when LSP attaches so LSP does not clobber smart hover
      vim.api.nvim_create_autocmd("LspAttach", {
        group = vim.api.nvim_create_augroup("smart_image_hover_lsp", { clear = true }),
        callback = function(args)
          vim.keymap.set("n", "K", smart_hover, { buffer = args.buf, desc = "Smart Hover (Mermaid/Image Sidecar or LSP)" })
        end,
      })

      -- 4. Interactive Centered Lightbox Modal with Zoom & Pan:
      -- Opens the diagram or image under cursor in a dedicated, high-contrast centered modal.
      -- Controls:
      --   - Zoom in:  '+' or '=' or ']'
      --   - Zoom out: '-' or '_' or '['
      --   - Pan:      'h', 'j', 'k', 'l' or Arrow keys (fast pan: 'H', 'J', 'K', 'L')
      --   - Reset:    '0' (resets zoom to 100% and centers image)
      --   - Close:    'q' or '<Esc>'
      local function open_image_lightbox()
        if not (Snacks.image and Snacks.image.doc) then
          return
        end
        Snacks.image.doc.at_cursor(function(src)
          if not src or src == "" then
            vim.notify("No image or Mermaid diagram under cursor to inspect.", vim.log.levels.WARN, { title = "Image Lightbox" })
            return
          end

          -- Dismiss any open ephemeral hover window
          if Snacks.image.doc.hover_close then
            Snacks.image.doc.hover_close()
          end

          local zoom_factor = 1.0
          local pan_x = 0
          local pan_y = 0
          local placement = nil
          local win = nil

          local function update_view()
            if not (win and win:valid() and placement and placement:ready()) then
              return
            end
            local win_w = vim.api.nvim_win_get_width(win.win)
            local win_h = vim.api.nvim_win_get_height(win.win)
            if not (placement.img and placement.img.file and vim.fn.filereadable(placement.img.file) == 1) then
              return
            end
            local ok_fit, base_size = pcall(Snacks.image.util.fit, placement.img.file, { width = win_w - 4, height = win_h - 4 }, { info = placement.img.info })
            if not ok_fit or not base_size or not base_size.width or not base_size.height then
              return
            end

            local target_w = math.max(6, math.floor(base_size.width * zoom_factor))
            local target_h = math.max(3, math.floor(base_size.height * zoom_factor))

            local center_col = math.max(0, math.floor((win_w - target_w) / 2) + pan_x)
            local center_row = math.max(1, math.min(180, math.floor((win_h - target_h) / 2) + 1 + pan_y))

            placement.opts.width = target_w
            placement.opts.height = target_h
            placement.opts.pos = { center_row, center_col }
            placement:update()

            win:set_title(string.format(" 󰄧 Mermaid / Image Lightbox [Zoom: %d%%] ", math.floor(zoom_factor * 100)))
          end

          local function apply_zoom(delta)
            zoom_factor = math.min(3.5, math.max(0.25, zoom_factor + delta))
            update_view()
          end

          local function apply_pan(dx, dy)
            pan_x = pan_x + dx
            pan_y = pan_y + dy
            update_view()
          end

          local function reset_view()
            zoom_factor = 1.0
            pan_x = 0
            pan_y = 0
            update_view()
          end

          win = Snacks.win({
            relative = "editor",
            position = "float",
            width = 0.88,
            height = 0.88,
            border = "rounded",
            enter = true,
            backdrop = 60,
            title = " 󰄧 Mermaid / Image Lightbox [Zoom: 100%] ",
            title_pos = "center",
            footer = " [+/-: Zoom | h/j/k/l: Pan | 0: Reset | q/Esc: Close] ",
            footer_pos = "center",
            keys = {
              q = "close",
              ["<Esc>"] = "close",
              ["="] = function() apply_zoom(0.15) end,
              ["+"] = function() apply_zoom(0.15) end,
              ["-"] = function() apply_zoom(-0.15) end,
              ["_"] = function() apply_zoom(-0.15) end,
              ["]"] = function() apply_zoom(0.15) end,
              ["["] = function() apply_zoom(-0.15) end,
              ["0"] = function() reset_view() end,
              h = function() apply_pan(-4, 0) end,
              l = function() apply_pan(4, 0) end,
              j = function() apply_pan(0, 2) end,
              k = function() apply_pan(0, -2) end,
              H = function() apply_pan(-12, 0) end,
              L = function() apply_pan(12, 0) end,
              J = function() apply_pan(0, 6) end,
              K = function() apply_pan(0, -6) end,
              ["<Left>"] = function() apply_pan(-4, 0) end,
              ["<Right>"] = function() apply_pan(4, 0) end,
              ["<Down>"] = function() apply_pan(0, 2) end,
              ["<Up>"] = function() apply_pan(0, -2) end,
            },
            on_close = function()
              if placement then
                placement:close()
              end
            end,
            show = true,
          })

          -- CRITICAL: Populate buffer with lines so extmarks and row offsets attach reliably
          vim.bo[win.buf].modifiable = true
          vim.api.nvim_buf_set_lines(win.buf, 0, -1, false, vim.fn["repeat"]({ "" }, 200))
          vim.bo[win.buf].modifiable = false

          placement = Snacks.image.placement.new(win.buf, src, {
            pos = { 1, 0 },
            auto_resize = false,
          })

          -- Check readiness and schedule initial rendering
          local uv = vim.uv or vim.loop
          local ready_timer = uv.new_timer()
          local check_count = 0
          ready_timer:start(40, 60, function()
            check_count = check_count + 1
            vim.schedule(function()
              if (placement and placement:ready()) or check_count > 40 then
                pcall(function()
                  ready_timer:stop()
                  ready_timer:close()
                end)
                update_view()
              end
            end)
          end)
        end)
      end

      -- 5. User Commands & Keymaps
      vim.api.nvim_create_user_command("ImageHover", function()
        if Snacks.image and Snacks.image.doc then
          Snacks.image.doc.hover()
        end
      end, { desc = "Hover preview for Mermaid diagram or Image at cursor" })

      vim.api.nvim_create_user_command("ImageLightbox", open_image_lightbox, {
        desc = "Open interactive centered Lightbox modal with zoom and pan",
      })
      vim.api.nvim_create_user_command("ImageZoom", open_image_lightbox, {
        desc = "Open interactive centered Lightbox modal with zoom and pan",
      })

      vim.keymap.set("n", "<leader>mz", open_image_lightbox, { desc = "Mermaid / Image Lightbox Zoom Modal" })
      vim.keymap.set("n", "<leader>mI", open_image_lightbox, { desc = "Mermaid / Image Lightbox (Centered Modal)" })

      -- Toggle continuous auto-hover on CursorMoved (default: off)
      local auto_hover_enabled = false
      local function toggle_auto_hover()
        auto_hover_enabled = not auto_hover_enabled
        Snacks.image.config.doc.float = auto_hover_enabled
        local group = vim.api.nvim_create_augroup("snacks_image_auto_hover_toggle", { clear = true })
        if auto_hover_enabled then
          vim.api.nvim_create_autocmd("CursorMoved", {
            group = group,
            callback = vim.schedule_wrap(function()
              if auto_hover_enabled and Snacks.image and Snacks.image.doc then
                Snacks.image.doc.hover()
              end
            end),
          })
          if Snacks.image and Snacks.image.doc then
            Snacks.image.doc.hover()
          end
          vim.notify("󰄧 Auto Image Hover: Enabled (Continuous on CursorMoved)", vim.log.levels.INFO, { title = "Image Hover" })
        else
          if Snacks.image and Snacks.image.doc and Snacks.image.doc.hover_close then
            Snacks.image.doc.hover_close()
          end
          vim.notify("󰄧 Auto Image Hover: Disabled (Press 'K' for On-Demand Sidecar)", vim.log.levels.INFO, { title = "Image Hover" })
        end
      end

      vim.api.nvim_create_user_command("ImageHoverToggle", toggle_auto_hover, { desc = "Toggle automatic hover preview on cursor movement" })
      vim.keymap.set("n", "<leader>mt", toggle_auto_hover, { desc = "Toggle Auto Image Hover (Continuous vs On-Demand)" })
      vim.keymap.set("n", "<leader>um", toggle_auto_hover, { desc = "Toggle Auto Image Hover (UI Toggle)" })
    end,
  },
}
