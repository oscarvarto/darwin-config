;;; my-api-testing-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'impostman)

(with-eval-after-load 'org
  (define-key org-mode-map (kbd "C-c C-r") verb-command-map))

(provide 'my-api-testing-config)
