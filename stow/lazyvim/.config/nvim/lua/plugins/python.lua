return {
  -- Ensure nvim-dap-python uses the system Python (from Nix) that already has debugpy
  {
    "mfussenegger/nvim-dap-python",
    dependencies = { "mfussenegger/nvim-dap" },
    config = function()
      -- Prefer python3 in PATH (Nix provides one with debugpy per your config)
      local python = vim.fn.exepath("python3")
      if python == nil or python == "" then
        python = "python3"
      end
      require("dap-python").setup(python)
    end,
  },

  -- Prevent Mason from managing the Python DAP adapter so it doesn't expect /venv/bin/python
  {
    "jay-babu/mason-nvim-dap.nvim",
    optional = true,
    opts = function(_, opts)
      opts = opts or {}
      opts.ensure_installed = opts.ensure_installed or {}
      -- remove "python" adapter from ensure_installed if present
      for i = #opts.ensure_installed, 1, -1 do
        if opts.ensure_installed[i] == "python" then
          table.remove(opts.ensure_installed, i)
        end
      end
      opts.handlers = opts.handlers or {}
      -- no-op handler for python so Mason doesn't try to set it up
      opts.handlers.python = function() end
      return opts
    end,
  },
}
