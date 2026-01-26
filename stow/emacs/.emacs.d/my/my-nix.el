;;; my-nix.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Nix language support with lsp-mode and nixd language server

(require 'use-package)

;; Configure nix-mode (already installed via elpaca in my-elpaca.el)
(use-package nix-mode
  :ensure nil
  :mode "\\.nix\\'")

;; Ensure NIX_PATH is properly set for nixd to find nixpkgs
;; Match the same format used by nushell environment
(setenv "NIX_PATH" (or (getenv "NIX_PATH") "nixpkgs=flake:nixpkgs"))

;; Configure nixd language server for Nix files
(with-eval-after-load 'lsp-mode
  (lsp-register-client
   (make-lsp-client
    :new-connection (lsp-stdio-connection "nixd")
    :major-modes '(nix-mode)
    :priority 1
    :server-id 'nixd
    :environment-fn
    (lambda ()
      ;; Ensure NIX_PATH is available for nixd with proper format
      (let ((nix-path (or (getenv "NIX_PATH") "nixpkgs=flake:nixpkgs")))
        (list (cons "NIX_PATH" nix-path))))
    ;; Use minimal configuration to avoid complex option evaluations
    :initialization-options
    (lambda ()
      (list :nixd
            (list :nixpkgs (list :expr "import <nixpkgs> { }")
                  :formatting (list :command "alejandra"))))
    :download-server-fn
    (lambda (_client callback error-callback _update?)
      ;; Use system nixd, don't download
      (funcall callback)))))

;; Enable lsp-mode for nix-mode
(add-hook 'nix-mode-hook #'lsp-deferred)

(provide 'my-nix)
