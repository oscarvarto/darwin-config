return {
  {
    -- Local config only (no external plugin). Hook into LazyVim to define commands.
    "LazyVim/LazyVim",
    ft = { "markdown" },
    config = function()
      -- Ensure sensible formatting options for markdown without auto-wrap
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          local tw = tonumber(vim.g.markdown_fill_textwidth or 80) or 80
          vim.opt_local.textwidth = tw
          -- Keep formatting with gq (q), no autowrap while typing (remove t)
          vim.opt_local.formatoptions:remove({ "t" })
          vim.opt_local.formatoptions:append({ "q" })
        end,
      })

      local function is_fence(line)
        return line:match("^%s*```") or line:match("^%s*~~~")
      end
      local function is_blank(line)
        return line:match("^%s*$") ~= nil
      end
      local function is_indented_code(line)
        return line:match("^%s%s%s%s") ~= nil or line:match("^\t") ~= nil
      end

      local function fill_range(s, e)
        if s and e and s <= e then
          vim.cmd(("%d,%dgq"):format(s, e))
        end
      end

      local function in_fenced_block_at(lines, idx)
        local in_fence = false
        for i = 1, idx do
          if is_fence(lines[i]) then
            in_fence = not in_fence
          end
        end
        return in_fence
      end

      local function fill_paragraph_at_cursor()
        local bufnr = 0
        local row = vim.api.nvim_win_get_cursor(0)[1] -- 1-based
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        if in_fenced_block_at(lines, row) or is_indented_code(lines[row] or "") then
          return
        end
        local s = row
        while s > 1 do
          local l = lines[s]
          if is_blank(l) or is_fence(l) or is_indented_code(l) then
            s = s + 1
            break
          end
          s = s - 1
        end
        if s == 0 then
          s = 1
        end
        local e = row
        local n = #lines
        while e <= n do
          local l = lines[e]
          if is_blank(l) or is_fence(l) or is_indented_code(l) then
            e = e - 1
            break
          end
          e = e + 1
        end
        if e > n then
          e = n
        end
        if s <= e then
          fill_range(s, e)
        end
      end

      local function fill_region(s, e)
        local bufnr = 0
        local lines = vim.api.nvim_buf_get_lines(bufnr, 0, -1, false)
        local in_fence = false
        local ps = nil
        local function flush()
          if ps ~= nil then
            -- trim trailing blanks from paragraph end
            local pe = ps
            while pe <= e do
              local l = lines[pe]
              if not l or is_blank(l) or is_fence(l) or is_indented_code(l) then
                pe = pe - 1
                break
              end
              pe = pe + 1
            end
            if pe < ps then
              ps = nil
              return
            end
            fill_range(ps, pe)
            ps = nil
          end
        end
        for i = s, e do
          local l = lines[i]
          if is_fence(l) then
            in_fence = not in_fence
            flush()
          elseif in_fence or is_indented_code(l) then
            flush()
          elseif is_blank(l) then
            flush()
          else
            if ps == nil then
              ps = i
            end
          end
        end
        flush()
      end

      vim.api.nvim_create_user_command("FillParagraph", function()
        if vim.bo.filetype ~= "markdown" then
          return
        end
        fill_paragraph_at_cursor()
      end, { desc = "Fill paragraph (markdown, skip code blocks)" })

      vim.api.nvim_create_user_command("FillBuffer", function()
        if vim.bo.filetype ~= "markdown" then
          return
        end
        local n = vim.api.nvim_buf_line_count(0)
        fill_region(1, n)
      end, { desc = "Fill entire buffer (markdown, skip code blocks)" })

      vim.api.nvim_create_user_command("FillRegion", function()
        if vim.bo.filetype ~= "markdown" then
          return
        end
        local s = vim.fn.getpos("'<")[2]
        local e = vim.fn.getpos("'>")[2]
        if s > 0 and e > 0 and s <= e then
          fill_region(s, e)
        end
      end, { desc = "Fill selected region (markdown, skip code blocks)" })

      -- Markdown-local keymaps
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "markdown" },
        callback = function()
          vim.keymap.set("n", "<leader>fm", ":FillParagraph<CR>", { buffer = true, desc = "Fill paragraph" })
          vim.keymap.set("n", "<leader>fB", ":FillBuffer<CR>", { buffer = true, desc = "Fill buffer" })
          vim.keymap.set("v", "<leader>fr", ":FillRegion<CR>", { buffer = true, desc = "Fill region" })
        end,
      })
    end,
  },
}
