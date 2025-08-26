-- Fix catppuccin/bufferline integration issue
-- The issue: catppuccin changed get() to get_theme() but LazyVim hasn't updated yet
return {
  -- Use the exact spec from LazyVim docs but with our flavour
  {
    "catppuccin/nvim",
    lazy = true,
    name = "catppuccin",
    opts = {
      flavour = "latte", -- Add our preferred flavour
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
      require("catppuccin").setup(opts)
      
      -- Monkey-patch the old get() method to use the new get_theme() API
      local bufferline_integration = require("catppuccin.groups.integrations.bufferline")
      if not bufferline_integration.get and bufferline_integration.get_theme then
        bufferline_integration.get = function()
          local theme_func = bufferline_integration.get_theme()
          if type(theme_func) == "function" then
            return theme_func()
          end
          return theme_func
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
