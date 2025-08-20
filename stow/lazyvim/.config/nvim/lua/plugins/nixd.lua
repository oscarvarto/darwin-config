return {
  {
    "neovim/nvim-lspconfig",
    opts = {
      servers = {
        nixd = {
          mason = false, -- use system nixd from Nix
          settings = {
            nixd = {
              nixpkgs = {
                -- Use simple nixpkgs path instead of flake evaluation
                expr = "import <nixpkgs> { }",
              },
              options = {
                -- Disable heavy option evaluations to prevent hanging
                -- These can be enabled later if needed for completion
                -- nixos = {
                --   expr = '(builtins.getFlake "/Users/oscarvarto/darwin-config").darwinConfigurations.predator.options',
                -- },
                -- home_manager = {
                --   expr = '(builtins.getFlake "/Users/oscarvarto/darwin-config").darwinConfigurations.predator.options.home-manager.users.type.getSubOptions []',
                -- },
              },
            },
          },
        },
        -- Explicitly disable nil_ls so it doesn't get configured
        nil_ls = { enabled = false },
      },
      setup = {
        -- Prevent LazyVim from setting up nil_ls
        nil_ls = function()
          return true
        end,
      },
    },
  },
}
