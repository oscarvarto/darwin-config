-- Options are automatically loaded before lazy.nvim startup
-- Default options that are always set: https://github.com/LazyVim/LazyVim/blob/main/lua/lazyvim/config/options.lua
-- Add any additional options here

vim.opt.relativenumber = false
-- Remap semicolon to colon for entering command mode
vim.keymap.set({ "n", "v" }, ";", ":", { noremap = true })
