return {
  {
    "LazyVim/LazyVim",
    init = function()
      -- Snacks' dashboard can fire before LazyVim's VeryLazy hook registers :LazyExtras.
      -- Guard by defining the command eagerly when it is missing so dashboard actions don't error.
      if vim.fn.exists(":LazyExtras") == 0 then
        vim.api.nvim_create_user_command("LazyExtras", function()
          require("lazyvim.util").extras.show()
        end, { desc = "Manage LazyVim extras" })
      end
    end,
  },
}

