return {
  {
    "mfussenegger/nvim-lint",
    opts = function(_, opts)
      opts.linters_by_ft = opts.linters_by_ft or {}
      opts.linters_by_ft.markdown = {} -- Empty table disables all linters for markdown filetypes
      local lint = require("lint")
      local ktlint = lint.linters.ktlint
      if ktlint then
        local filtered_messages = {
          "Newline expected after opening parenthesis",
          "Parameter should start on a newline",
          "Newline expected before closing parenthesis",
        }
        ktlint.args = {
          "--reporter=json",
          "--stdin",
          "--stdin-path",
          function()
            return vim.api.nvim_buf_get_name(0)
          end,
        }
        if not ktlint._filtered_parser then
          local orig_parser = ktlint.parser
          ktlint.parser = function(output, bufnr)
            local diagnostics = orig_parser(output, bufnr)
            return vim.tbl_filter(function(diagnostic)
              local message = diagnostic.message or ""
              for _, pattern in ipairs(filtered_messages) do
                if message:find(pattern, 1, true) then
                  return false
                end
              end
              return true
            end, diagnostics)
          end
          ktlint._filtered_parser = true
        end
      end
    end,
  },
}
