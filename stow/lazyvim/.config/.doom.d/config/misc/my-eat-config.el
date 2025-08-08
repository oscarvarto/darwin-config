;;; my-eat-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package eat
  :config
  (setq eat-shell "nu")
  ;; For `eat-eshell-mode'.
  (add-hook 'eshell-load-hook #'eat-eshell-mode)
  ;; For `eat-eshell-visual-command-mode'.
  (add-hook 'eshell-load-hook #'eat-eshell-visual-command-mode))

(provide 'my-eat-config)
