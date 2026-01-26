return {
  {
    "nvim-treesitter/nvim-treesitter",
    opts = {
      ensure_installed = {
        "latex", "svelte", "typst", "vue",
        -- add other languages you use
      },
    },
  },
}
