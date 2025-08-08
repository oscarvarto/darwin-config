;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; TODO: Example of snippets (for rust) here: https://github.com/rksm/emacs-rust-config/tree/master/snippets/rustic-mode
(use-package yasnippet
  :config
  (yas-reload-all)
  (add-hook 'prog-mode-hook 'yas-minor-mode)
  (add-hook 'text-mode-hook 'yas-minor-mode))
(setq yas-trigger-key "s-<next>")
(global-set-key (kbd yas-trigger-key) 'yas-expand)
