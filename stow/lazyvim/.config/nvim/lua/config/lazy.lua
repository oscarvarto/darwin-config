local lazypath = vim.fn.stdpath("data") .. "/lazy/lazy.nvim"
if not (vim.uv or vim.loop).fs_stat(lazypath) then
  local lazyrepo = "https://github.com/folke/lazy.nvim.git"
  local out = vim.fn.system({ "git", "clone", "--filter=blob:none", "--branch=stable", lazyrepo, lazypath })
  if vim.v.shell_error ~= 0 then
    vim.api.nvim_echo({
      { "Failed to clone lazy.nvim:\n", "ErrorMsg" },
      { out, "WarningMsg" },
      { "\nPress any key to exit..." },
    }, true, {})
    vim.fn.getchar()
    os.exit(1)
  end
end
vim.opt.rtp:prepend(lazypath)

local secrets = {}
local secrets_file = vim.fn.expand("~/.config/nvim/secrets.lua")
if vim.fn.filereadable(secrets_file) == 1 then
  secrets = dofile(secrets_file)
  -- Set env vars from secrets for plugins that read from environment
  if secrets.TAVILY_API_KEY then
    vim.env.TAVILY_API_KEY = secrets.TAVILY_API_KEY
  end
  if secrets.ANTHROPIC_API_KEY then
    vim.env.ANTHROPIC_API_KEY = secrets.ANTHROPIC_API_KEY
  end
  if secrets.MORPH_API_KEY then
    vim.env.MORPH_API_KEY = secrets.MORPH_API_KEY
  end
end

require("lazy").setup({
  spec = {
    -- add LazyVim and import its plugins
    { "LazyVim/LazyVim", import = "lazyvim.plugins" },
    -- import/override with your plugins
    { import = "plugins" },
    {
      "yetone/avante.nvim",
      --"ghosert/avante.nvim",
      build = vim.fn.has("win32") ~= 0 and "powershell -ExecutionPolicy Bypass -File Build.ps1 -BuildFromSource false"
        or "PATH=$HOME/.cargo/bin:$PATH make BUILD_FROM_SOURCE=true",
      event = "VeryLazy",
      version = false, -- Never set this value to "*"! Never!
      ---@module 'avante'
      ---@type avante.Config
      opts = {
        instructions_file = "AGENTS.md", -- Default is "avante.md"
        provider = "claude",
        -- auto_suggestions_provider = "claude",
        providers = {
          claude = {
            endpoint = "https://api.anthropic.com",
            auth_type = "max", -- "api", -- Set to "max" to sign in with Claude Pro/Max subscription
            model = "claude-opus-4-5-20251101",
            extra_request_body = {
              temperature = 0.75,
              max_tokens = 64000,
            },
          },
        },
        selection = {
          hint_display = "delayed",
        },
        behaviour = {
          auto_set_keymaps = true,
          enable_fastapply = true,
        },
        acp_providers = {
          ["claude-code"] = {
            command = "claude-code-acp",
            args = {},
            env = {
              NODE_NO_WARNINGS = "1",
              ANTHROPIC_API_KEY = secrets.ANTHROPIC_API_KEY or os.getenv("ANTHROPIC_API_KEY"),
              ACP_PATH_TO_CLAUDE_CODE_EXECUTABLE = vim.fn.exepath("claude"),
              ACP_PERMISSION_MODE = "bypassPermissions",
            },
          },
        },
        web_search_engine = {
          provider = "tavily",
        }
      },
      cmd = {
        "AvanteAsk",
        "AvanteBuild",
        "AvanteChat",
        "AvanteClear",
        "AvanteEdit",
        "AvanteFocus",
        "AvanteHistory",
        "AvanteModels",
        "AvanteRefresh",
        "AvanteShowRepoMap",
        "AvanteStop",
        "AvanteSwitchProvider",
        "AvanteToggle",
      },
    },
    {
      -- support for image pasting
      "HakonHarnes/img-clip.nvim",
      event = "VeryLazy",
      opts = {
        -- recommended settings
        default = {
          embed_image_as_base64 = false,
          prompt_for_file_name = false,
          drag_and_drop = {
            insert_mode = true,
          },
        },
      },
    },
    {
      "MeanderingProgrammer/render-markdown.nvim",
      opts = {
        file_types = { "markdown", "Avante" },
      },
      ft = { "markdown", "Avante" },
    },
    {
      "saghen/blink.cmp",
      specs = { "Kaiser-Yang/blink-cmp-avante" },
      opts = {
        sources = {
          default = { "avante" },
          providers = { avante = { module = "blink-cmp-avante", name = "Avante" } },
        },
      },
    }
  },
  defaults = {
    -- By default, only LazyVim plugins will be lazy-loaded. Your custom plugins will load during startup.
    -- If you know what you're doing, you can set this to `true` to have all your custom plugins lazy-loaded by default.
    lazy = false,
    -- It's recommended to leave version=false for now, since a lot the plugin that support versioning,
    -- have outdated releases, which may break your Neovim install.
    version = false, -- always use the latest git commit
    -- version = "*", -- try installing the latest stable version for plugins that support semver
  },
  rocks = {
    enabled = false,
  },
  install = { colorscheme = { "catppuccin", "tokyonight", "habamax" } },
  checker = {
    enabled = true, -- check for plugin updates periodically
    notify = false, -- notify on update
  }, -- automatically check for plugin updates
  performance = {
    rtp = {
      -- disable some rtp plugins
      disabled_plugins = {
        "gzip",
        -- "matchit",
        -- "matchparen",
        -- "netrwPlugin",
        "tarPlugin",
        "tohtml",
        "tutor",
        "zipPlugin",
      },
    },
  },
})
