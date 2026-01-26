return {
  -- Lightweight trailing whitespace tools (Neovim-native)
  {
    "nvim-mini/mini.trailspace",
    event = "VeryLazy",
    opts = {},
    config = function(_, opts)
      require("mini.trailspace").setup(opts)

      -- Default: do NOT highlight trailing whitespace anywhere.
      -- We keep on-demand trim commands only to avoid theme conflicts.
      vim.g.minitrailspace_disable = true

      -- Do not highlight in dashboards or special buffers
      local disable_ft = {
        "alpha",
        "dashboard",
        "lazy",
        "mason",
        "help",
        "TelescopePrompt",
        "neo-tree",
        "NvimTree",
        "noice",
        "notify",
        "oil",
        "trouble",
      }
      -- If you prefer selective highlight later, you can re-enable on demand:
      -- :let g:minitrailspace_disable = 0

      -- User commands for on-demand cleanup
      vim.api.nvim_create_user_command("WhitespaceTrim", function()
        require("mini.trailspace").trim()
        require("mini.trailspace").trim_last_lines()
      end, { desc = "Trim trailing whitespace and final blank lines" })

      -- Convert spaces/tabs across the buffer based on current setting
      vim.api.nvim_create_user_command("Untabify", function()
        vim.bo.expandtab = true
        vim.cmd("retab!")
      end, { desc = "Convert tabs to spaces using current indent settings" })

      vim.api.nvim_create_user_command("Tabify", function()
        vim.bo.expandtab = false
        vim.cmd("retab!")
      end, { desc = "Convert spaces to tabs using current indent settings" })
    end,
    keys = {
      { "<leader>cw", ":WhitespaceTrim<cr>", desc = "Trim trailing whitespace" },
      { "<leader>cT", ":Untabify<cr>", desc = "Untabify (tabs -> spaces)" },
      { "<leader>ct", ":Tabify<cr>", desc = "Tabify (spaces -> tabs)" },
    },
  },

  -- Optional alternative: ntpeters/vim-better-whitespace (kept disabled by default)
  -- Uncomment to use instead of mini.trailspace. It works in Neovim, but we
  -- prefer mini.trailspace for native Lua and smaller footprint.
  -- {
  --   "ntpeters/vim-better-whitespace",
  --   enabled = false,
  --   init = function()
  --     vim.g.better_whitespace_enabled = 1
  --     vim.g.strip_whitespace_on_save = 0 -- on-demand only
  --     vim.g.better_whitespace_filetypes_blacklist = {
  --       "alpha",
  --       "dashboard",
  --       "lazy",
  --       "mason",
  --       "help",
  --       "TelescopePrompt",
  --       "neo-tree",
  --       "NvimTree",
  --       "noice",
  --       "notify",
  --       "oil",
  --       "trouble",
  --     }
  --   end,
  --   keys = {
  --     { "<leader>cw", ":StripWhitespace<cr>", desc = "Strip whitespace (vim-better-whitespace)" },
  --   },
  -- },
}
