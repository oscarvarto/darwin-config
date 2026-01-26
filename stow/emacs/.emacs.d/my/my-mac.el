;; -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package exec-path-from-shell
    :ensure (:wait t
             :depth 1)
    :demand t
    :init
    (setq exec-path-from-shell-shell-name "/Users/oscarvarto/.nix-profile/bin/zsh")
    (when (memq window-system '(mac ns x))
      (exec-path-from-shell-initialize)))

(use-package kkp
    :ensure t
    :config
    (global-kkp-mode +1))

(provide 'my-mac)
