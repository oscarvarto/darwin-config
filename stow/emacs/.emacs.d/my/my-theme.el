;; -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package catppuccin-theme
  :ensure t
  :demand t
  :config
  (load-theme 'catppuccin :no-confirm)
  (setq catppuccin-flavor 'mocha)
  (catppuccin-reload))

(provide 'my-theme)
