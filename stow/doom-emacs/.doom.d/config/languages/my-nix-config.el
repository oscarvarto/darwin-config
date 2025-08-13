;;; my-nix-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(with-eval-after-load 'lsp-mode
  (lsp-register-client
    (make-lsp-client :new-connection (lsp-stdio-connection "nixd")
                     :major-modes '(nix-mode)
                     :priority 0
                     :server-id 'nixd)))

(provide 'my-nix-config)
