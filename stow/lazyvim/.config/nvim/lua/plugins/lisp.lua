return {
  -- Enhanced Treesitter support for Lisp languages
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "clojure",
        "scheme",
        "fennel",
      })
      
      -- Explicitly disable tree-sitter for elisp and lisp filetypes to prevent errors
      opts.highlight = opts.highlight or {}
      opts.highlight.disable = opts.highlight.disable or {}
      vim.list_extend(opts.highlight.disable, { "elisp", "lisp" })
    end,
  },

  -- Parinfer for structural editing of Lisp code
  {
    "gpanders/nvim-parinfer",
    ft = { "clojure", "scheme", "fennel" },
    config = function()
      vim.g.parinfer_mode = "smart"
      vim.g.parinfer_force_balance = true
      vim.g.parinfer_comment_chars = { ";", "#" }
    end,
  },

  -- Rainbow parentheses for better bracket visualization
  {
    "HiPhish/rainbow-delimiters.nvim",
    ft = { "clojure", "scheme", "fennel" },
    submodules = false, -- upstream tests use a submodule we don't need
    config = function()
      local rainbow_delimiters = require("rainbow-delimiters")
      vim.g.rainbow_delimiters = {
        strategy = {
          [""] = rainbow_delimiters.strategy["global"],
          vim = rainbow_delimiters.strategy["local"],
        },
        query = {
          [""] = "rainbow-delimiters",
          lua = "rainbow-blocks",
        },
        highlight = {
          "RainbowDelimiterRed",
          "RainbowDelimiterYellow",
          "RainbowDelimiterBlue",
          "RainbowDelimiterOrange",
          "RainbowDelimiterGreen",
          "RainbowDelimiterViolet",
          "RainbowDelimiterCyan",
        },
      }
    end,
  },

  -- LSP configuration for Lisp languages
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        -- Emacs Lisp LSP (using built-in Emacs server if available)
        -- You may need to install additional LSP servers via your Nix configuration
        
        -- Clojure LSP (clojure-lsp)
        clojure_lsp = {
          -- Configuration will be handled by the Clojure extra
        },
        
        -- For other Lisps, we'll rely on basic syntax highlighting and parinfer
      },
    },
  },

  -- Enhanced Clojure support (extending existing clojure extra)
  {
    "Olical/conjure",
    ft = { "clojure", "fennel", "scheme" },
    config = function()
      -- Conjure configuration for REPL interaction
      vim.g["conjure#mapping#doc_word"] = "K"
      vim.g["conjure#mapping#def_word"] = "gd"
      vim.g["conjure#client#clojure#nrepl#eval#auto_require"] = false
      vim.g["conjure#client#clojure#nrepl#connection#auto_repl#enabled"] = false

      -- Explicitly disable Conjure for elisp and common lisp to avoid tree-sitter issues
      vim.g["conjure#filetype#elisp"] = false
      vim.g["conjure#filetype#lisp"] = false

      -- Scheme support
      vim.g["conjure#client#scheme#stdio#command"] = "mit-scheme"
      vim.g["conjure#client#scheme#stdio#prompt_pattern"] = "=> "
    end,
    keys = {
      { "<localleader>ee", "<cmd>ConjureEval<cr>", desc = "Evaluate current form", ft = { "clojure", "scheme" } },
      { "<localleader>er", "<cmd>ConjureEvalRoot<cr>", desc = "Evaluate root form", ft = { "clojure", "scheme" } },
      { "<localleader>eb", "<cmd>ConjureEvalBuf<cr>", desc = "Evaluate buffer", ft = { "clojure", "scheme" } },
      { "<localleader>ef", "<cmd>ConjureEvalFile<cr>", desc = "Evaluate file", ft = { "clojure", "scheme" } },
      { "<localleader>cs", "<cmd>ConjureConnect<cr>", desc = "Connect to REPL", ft = { "clojure", "scheme" } },
      { "<localleader>cq", "<cmd>ConjureQuit<cr>", desc = "Quit REPL connection", ft = { "clojure", "scheme" } },
    },
  },

  -- Completion support for Conjure
  {
    "hrsh7th/nvim-cmp",
    dependencies = {
      {
        "PaterJason/cmp-conjure",
        ft = { "clojure", "fennel", "scheme" },
      },
    },
    opts = function(_, opts)
      table.insert(opts.sources, { name = "conjure" })
      return opts
    end,
  },

  -- S-expression text objects and motions
  {
    "guns/vim-sexp",
    ft = { "clojure", "scheme", "fennel" },
    dependencies = { "tpope/vim-sexp-mappings-for-regular-people" },
    config = function()
      -- Disable default mappings to avoid conflicts
      vim.g.sexp_enable_insert_mode_mappings = 0
      vim.g.sexp_filetypes = "clojure,scheme,fennel"
    end,
  },

  -- Additional Lisp-friendly mappings
  {
    "tpope/vim-sexp-mappings-for-regular-people",
    ft = { "clojure", "scheme", "fennel" },
  },

  -- Fennel support (Lua Lisp)
  {
    "bakpakin/fennel.vim",
    ft = "fennel",
  },

  -- File type detection and basic settings
  {
    "nvim-treesitter/nvim-treesitter",
    opts = function(_, opts)
      -- Basic filetype detection for supported Lisp dialects
      vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
        pattern = { "*.scm", "*.ss", "*.rkt" },
        callback = function()
          vim.bo.filetype = "scheme"
        end,
      })
      
      vim.api.nvim_create_autocmd({ "BufNewFile", "BufRead" }, {
        pattern = "*.fnl",
        callback = function()
          vim.bo.filetype = "fennel"
        end,
      })
    end,
  },

  -- Lisp-specific keymaps and settings
  {
    "LazyVim/LazyVim",
    opts = function(_, opts)
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "clojure", "scheme", "fennel" },
        callback = function()
          -- Set up Lisp-friendly options
          vim.bo.lisp = true
          vim.bo.lispwords = vim.bo.lispwords .. ",when-let,if-let,when-some,if-some,defn-,defmacro-"
          
          -- Enable proper indentation
          vim.opt_local.formatoptions:remove("t")
          vim.opt_local.formatoptions:append("croql")
          
          -- Set up local keymaps
          local opts_local = { buffer = true, silent = true }
          
          -- Structural editing keymaps
          vim.keymap.set("n", "<localleader>w(", "viw<Esc>`<i(<Esc>`>la)<Esc>", opts_local)
          vim.keymap.set("n", "<localleader>w[", "viw<Esc>`<i[<Esc>`>la]<Esc>", opts_local)
          vim.keymap.set("n", "<localleader>w{", "viw<Esc>`<i{<Esc>`>la}<Esc>", opts_local)
          
          -- Slurp and barf (if using vim-sexp)
          vim.keymap.set("n", "<localleader>)", "<Plug>(sexp_emit_tail_element)", opts_local)
          vim.keymap.set("n", "<localleader>(", "<Plug>(sexp_capture_next_element)", opts_local)
          vim.keymap.set("n", "<localleader>}", "<Plug>(sexp_emit_head_element)", opts_local)
          vim.keymap.set("n", "<localleader>{", "<Plug>(sexp_capture_prev_element)", opts_local)
          
          -- Documentation and evaluation shortcuts
          vim.keymap.set("n", "K", function()
            if vim.bo.filetype == "clojure" then
              -- Use Conjure's doc lookup
              vim.cmd("ConjureDocWord")
            else
              vim.cmd("normal! K")
            end
          end, opts_local)
        end,
      })
      
      -- Explicitly handle lisp filetype to disable Conjure and tree-sitter
      vim.api.nvim_create_autocmd("FileType", {
        pattern = { "lisp", "elisp" },
        callback = function()
          -- Disable Conjure to prevent tree-sitter completion errors
          vim.b.conjure_disabled = true
          -- Use basic syntax highlighting instead of tree-sitter
          if vim.treesitter and vim.treesitter.stop then
            vim.treesitter.stop()
          end
        end,
      })
    end,
  },

  -- Mason tool installation for Lisp support
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      vim.list_extend(opts.ensure_installed, {
        "clojure-lsp",
        "clj-kondo", -- Clojure linter
      })
    end,
  },

  -- Formatting and linting with conform and nvim-lint (LazyVim's preferred approach)
  {
    "stevearc/conform.nvim",
    opts = {
      formatters_by_ft = {
        clojure = { "cljfmt" },
        -- Add other Lisp formatters as needed
      },
    },
  },

  {
    "mfussenegger/nvim-lint",
    opts = {
      linters_by_ft = {
        clojure = { "clj-kondo" },
      },
    },
  },
}
