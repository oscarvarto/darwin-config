-- Fix catppuccin/bufferline integration issue
-- The issue: catppuccin changed get() to get_theme() but LazyVim hasn't updated yet
return {
  -- Use the exact spec from LazyVim docs but with our flavour
  {
    "catppuccin/nvim",
    name = "catppuccin",
    lazy = false,          -- load immediately so colors are ready
    priority = 1000,       -- load before other UI plugins
    opts = {
      flavour = "mocha", -- Add our preferred flavour
      integrations = {
        aerial = true,
        alpha = true,
        cmp = true,
        dashboard = true,
        flash = true,
        fzf = true,
        grug_far = true,
        gitsigns = true,
        headlines = true,
        illuminate = true,
        indent_blankline = { enabled = true },
        leap = true,
        lsp_trouble = true,
        mason = true,
        markdown = true,
        mini = true,
        native_lsp = {
          enabled = true,
          underlines = {
            errors = { "undercurl" },
            hints = { "undercurl" },
            warnings = { "undercurl" },
            information = { "undercurl" },
          },
        },
        navic = { enabled = true, custom_bg = "lualine" },
        neotest = true,
        neotree = true,
        noice = true,
        notify = true,
        semantic_tokens = true,
        snacks = true,
        telescope = true,
        treesitter = true,
        treesitter_context = true,
        which_key = true,
      },
    },
    -- Patch the breaking change in catppuccin's API
    config = function(_, opts)
      -- Ensure proper color support and light background for Latte
      vim.opt.termguicolors = true
      vim.o.background = "light"
      require("catppuccin").setup(opts)
      -- In case LazyVim colorscheme apply happens earlier, enforce it here too
      pcall(vim.cmd.colorscheme, "catppuccin")
      
      -- Monkey-patch the old get() method to use the new get_theme() API
      local ok, bufferline_integration = pcall(require, "catppuccin.groups.integrations.bufferline")
      if not ok then
        ok, bufferline_integration = pcall(require, "catppuccin.special.bufferline")
      end
      if ok and bufferline_integration and not bufferline_integration.get and bufferline_integration.get_theme then
        bufferline_integration.get = function(user_config)
          local theme = bufferline_integration.get_theme(user_config)
          if type(theme) == "function" then
            return theme()
          end
          return theme
        end
      end
    end,
  },
  
  -- Configure LazyVim to use catppuccin
  {
    "LazyVim/LazyVim",
    opts = {
      colorscheme = "catppuccin",
    },
  },
}
