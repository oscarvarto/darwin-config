return {
  -- Simple Emacs Lisp support without server integration
  {
    "nvim-lua/plenary.nvim",
    config = function()
      -- Helper function to format Elisp using your elisp-formatter
      local function format_elisp_buffer()
        local file = vim.fn.expand("%:p")
        if file and file ~= "" then
          local cmd = string.format("elisp-formatter.js elisp '%s'", file)
          local result = vim.fn.system(cmd)
          if vim.v.shell_error == 0 then
            vim.cmd("edit!") -- Reload the file
            vim.notify("Elisp buffer formatted successfully", vim.log.levels.INFO)
          else
            vim.notify("Elisp formatting failed: " .. result, vim.log.levels.ERROR)
          end
        end
      end

      -- Helper function to check Elisp syntax
      local function check_elisp_syntax()
        local file = vim.fn.expand("%:p")
        if file and file ~= "" then
          local cmd = string.format("elisp-formatter.js check '%s'", file)
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
      end, {})

      vim.api.nvim_create_user_command("ElispCheck", function()
        check_elisp_syntax()
      end, {})
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
