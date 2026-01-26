return {
  -- Simple Emacs Lisp support - formatting and syntax checking only
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      -- Disable auto-formatting on save for Elisp files
      vim.g.elisp_auto_format = false

      -- Helper function to format Elisp using elisp-formatter
      -- IMPORTANT: Operate on the current buffer contents (not on-disk file)
      -- to avoid losing unsaved edits when running on BufWritePre.
      local function format_elisp_buffer()
        local file = vim.fn.expand("%:p")
        if not (file and file ~= "") then
          return
        end

        -- Resolve formatter path (prefer repo path, then PATH)
        local home = os.getenv("HOME")
        local elisp_formatter_cmd = home .. "/darwin-config/modules/elisp-formatter/elisp-formatter.js"
        if vim.fn.executable(elisp_formatter_cmd) == 0 then
          elisp_formatter_cmd = "elisp-formatter.js"
          if vim.fn.executable(elisp_formatter_cmd) == 0 then
            vim.notify("elisp-formatter.js not found", vim.log.levels.WARN)
            return
          end
        end

        -- Save cursor position and view
        local cursor_pos = vim.api.nvim_win_get_cursor(0)
        local view = vim.fn.winsaveview()

        -- Write current buffer to a temporary file to give the formatter
        -- the in-memory edits, not the last on-disk state.
        local tmpfile = vim.fn.tempname() .. ".el"
        local buf_lines = vim.api.nvim_buf_get_lines(0, 0, -1, false)
        local ok, write_err = pcall(vim.fn.writefile, buf_lines, tmpfile)
        if not ok then
          vim.notify("Failed to prepare temp file for formatting: " .. tostring(write_err), vim.log.levels.ERROR)
          return
        end

        -- Run formatter against the temp file
        local cmd = string.format("%s elisp '%s'", elisp_formatter_cmd, tmpfile)
        local result = vim.fn.system(cmd)
        local shell_ok = (vim.v.shell_error == 0)

        if shell_ok then
          -- Prefer reading back from the temp file (formatter likely writes in-place).
          -- If it instead prints to stdout, fall back to system() output.
          local new_lines
          local tmp_read_ok, tmp_lines = pcall(vim.fn.readfile, tmpfile)
          if tmp_read_ok and tmp_lines and #tmp_lines > 0 then
            new_lines = tmp_lines
          else
            -- Fallback: use stdout (split into lines)
            if type(result) == "string" and #result > 0 then
              new_lines = vim.split(result, "\n", { plain = true })
            else
              -- Nothing to apply
              new_lines = buf_lines
            end
          end

          -- Update buffer with formatted content
          vim.api.nvim_buf_set_lines(0, 0, -1, false, new_lines)

          -- Restore cursor position and view
          vim.fn.winrestview(view)
          pcall(vim.api.nvim_win_set_cursor, 0, cursor_pos)

          -- Trigger syntax highlighting refresh
          vim.cmd("syntax sync fromstart")

          vim.notify("Elisp buffer formatted", vim.log.levels.INFO)
        else
          vim.notify("Elisp formatting failed: " .. result, vim.log.levels.ERROR)
        end

        -- Cleanup temp file
        pcall(vim.fn.delete, tmpfile)
      end

      -- Helper function to check Elisp syntax
      local function check_elisp_syntax()
        local file = vim.fn.expand("%:p")
        if file and file ~= "" then
          -- Try full path first, then fallback to PATH resolution
          local home = os.getenv("HOME")
          local elisp_formatter_cmd = home .. "/darwin-config/modules/elisp-formatter/elisp-formatter.js"
          if vim.fn.executable(elisp_formatter_cmd) == 0 then
            elisp_formatter_cmd = "elisp-formatter.js"
            if vim.fn.executable(elisp_formatter_cmd) == 0 then
              vim.notify("elisp-formatter.js not found", vim.log.levels.WARN)
              return
            end
          end

          local cmd = string.format("%s check '%s'", elisp_formatter_cmd, file)
          local result = vim.fn.system(cmd)
          if vim.v.shell_error == 0 then
            vim.notify("Elisp syntax is valid", vim.log.levels.INFO)
          else
            vim.notify("Elisp syntax errors: " .. result, vim.log.levels.WARN)
          end
        end
      end

      -- Make functions globally available
      _G.format_elisp_buffer = format_elisp_buffer
      _G.check_elisp_syntax = check_elisp_syntax

      -- Create user commands
      vim.api.nvim_create_user_command("ElispFormat", function()
        format_elisp_buffer()
      end, { desc = "Format Elisp buffer using elisp-formatter" })

      vim.api.nvim_create_user_command("ElispCheck", function()
        check_elisp_syntax()
      end, { desc = "Check Elisp syntax using elisp-formatter" })
    end,
  },

  -- Emacs Lisp specific keymaps and autocommands
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "elisp",
        callback = function()
          local opts_local = { buffer = true, silent = true }
          
          -- Formatting and linting keymaps
          vim.keymap.set("n", "<localleader>cf", ":ElispFormat<CR>", 
            vim.tbl_extend("force", opts_local, { desc = "Format Elisp buffer" }))
          vim.keymap.set("n", "<localleader>cc", ":ElispCheck<CR>", 
            vim.tbl_extend("force", opts_local, { desc = "Check Elisp syntax" }))
          
          -- Set buffer-local options for Elisp
          vim.bo.commentstring = ";; %s"
          vim.opt_local.shiftwidth = 2
          vim.opt_local.tabstop = 2
          vim.opt_local.expandtab = true
          
          -- Enable auto-formatting on save with elisp-formatter (optional)
          if vim.g.elisp_auto_format ~= false then
            vim.api.nvim_create_autocmd("BufWritePre", {
              buffer = 0,
              callback = function()
                _G.format_elisp_buffer()
              end,
            })
          end
        end,
      })
      
      -- Auto-detect Emacs Lisp files
      vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
        pattern = { 
          "*.el", 
          "*.emacs", 
          ".emacs.d/*",
          ".doom.d/*",
          "init.el",
          "config.el",
          "packages.el"
        },
        callback = function()
          vim.bo.filetype = "elisp"
          -- Explicitly disable Conjure for this buffer to prevent tree-sitter errors
          vim.b.conjure_disabled = true
        end,
      })
      
      -- Additional autocmd to ensure Conjure is disabled for elisp filetype
      vim.api.nvim_create_autocmd("FileType", {
        pattern = "elisp",
        callback = function()
          -- Disable Conjure to prevent tree-sitter completion errors
          vim.b.conjure_disabled = true
          -- Disable tree-sitter highlighting for this buffer
          if vim.treesitter and vim.treesitter.stop then
            vim.treesitter.stop()
          end
        end,
      })
    end,
  },

  -- Basic syntax highlighting for Elisp using Vim's built-in support
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Use additional vim regex highlighting for elisp since treesitter parser is not available
      opts.highlight = opts.highlight or {}
      opts.highlight.additional_vim_regex_highlighting = 
        opts.highlight.additional_vim_regex_highlighting or {}
      table.insert(opts.highlight.additional_vim_regex_highlighting, "elisp")
    end,
  },

  -- Integration with which-key for Elisp keybindings
  {
    "folke/which-key.nvim",
    opts = function(_, opts)
      opts.spec = opts.spec or {}
      table.insert(opts.spec, {
        mode = { "n" },
        { "<localleader>c", group = "code" },
        { "<localleader>cf", desc = "Format" },
        { "<localleader>cc", desc = "Check syntax" },
      })
    end,
  },
}
