;;; my-claude-config.el -*- lexical-binding: t; no-byte-compile:t; -*-

(use-package claude-code-ide
  :bind ("C-c C-'" . claude-code-ide-menu) ; Set your favorite keybinding
  :config
  (claude-code-ide-emacs-tools-setup)) ; Optionally enable Emacs MCP tools

(provide 'my-claude-config.el)
