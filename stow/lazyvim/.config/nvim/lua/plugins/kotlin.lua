-- Kotlin LSP configuration with diagnostic filtering
local filtered_codes = {
  FunctionName = true,
}

local function should_filter_diagnostic(diagnostic)
  local code = diagnostic.code
  if not code and diagnostic.user_data and diagnostic.user_data.lsp then
    code = diagnostic.user_data.lsp.code
  end
  return code and filtered_codes[code] or false
end

local function filter_diagnostics(diagnostics)
  return vim.tbl_filter(function(d)
    return not should_filter_diagnostic(d)
  end, diagnostics)
end

local function filter_workspace_items(items)
  for _, item in ipairs(items) do
    if item.items then
      item.items = filter_diagnostics(item.items)
    end
  end
end

local function wrap_diagnostic_handler(handler)
  return function(err, result, ctx, config)
    if result then
      if result.diagnostics then
        result.diagnostics = filter_diagnostics(result.diagnostics)
      elseif result.items then
        if result.items[1] and result.items[1].items then
          filter_workspace_items(result.items)
        else
          result.items = filter_diagnostics(result.items)
        end
      end
    end
    return handler(err, result, ctx, config)
  end
end

local function is_kotlin_client(client)
  if client.name == "kotlin_language_server" then
    return true
  end
  local filetypes = client.config and client.config.filetypes or {}
  for _, ft in ipairs(filetypes) do
    if ft == "kotlin" then
      return true
    end
  end
  return false
end

local function attach_kotlin_handlers(client)
  if not is_kotlin_client(client) or client._kotlin_diag_filter then
    return
  end
  client._kotlin_diag_filter = true
  client.handlers = client.handlers or {}
  for _, method in ipairs({ "textDocument/publishDiagnostics", "textDocument/diagnostic", "workspace/diagnostic" }) do
    local handler = client.handlers[method] or vim.lsp.handlers[method]
    if handler then
      client.handlers[method] = wrap_diagnostic_handler(handler)
    end
  end
end

return {
  -- Ensure ktlint is installed via Mason
  {
    "mason-org/mason.nvim",
    opts = function(_, opts)
      opts.ensure_installed = opts.ensure_installed or {}
      vim.list_extend(opts.ensure_installed, {
        "ktlint",
      })
    end,
  },

  -- Formatting with ktlint
  {
    "stevearc/conform.nvim",
    keys = {
      {
        "<leader>cK",
        function()
          require("conform").format({ async = false, lsp_fallback = false })
        end,
        mode = { "n", "v" },
        desc = "Format (ktlint)",
      },
    },
    opts = {
      formatters_by_ft = {
        kotlin = { "ktlint" },
      },
    },
  },

  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        kotlin_language_server = {
          cmd = { vim.fn.expand("~/.local/share/nvim/mason/packages/kotlin-lsp/bin/kotlin-lsp"), "--stdio" },
          root_dir = require("lspconfig.util").root_pattern(
            "pom.xml", -- Maven
            "settings.gradle", -- Gradle (multi-project)
            "settings.gradle.kts", -- Gradle (multi-project)
            "build.gradle", -- Gradle
            "build.gradle.kts" -- Gradle
          ),
        },
      },
    },
    init = function()
      local group = vim.api.nvim_create_augroup("KotlinLspDiagnostics", { clear = true })
      vim.api.nvim_create_autocmd("LspAttach", {
        group = group,
        callback = function(args)
          local client = vim.lsp.get_client_by_id(args.data.client_id)
          if client then
            attach_kotlin_handlers(client)
          end
        end,
      })
    end,
  },
}
