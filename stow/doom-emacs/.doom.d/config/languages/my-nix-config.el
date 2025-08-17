;;; my-nix-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Ensure NIX_PATH is properly set for nixd to find nixpkgs
;; Match the same format used by nushell environment
(setenv "NIX_PATH" (or (getenv "NIX_PATH") "nixpkgs=flake:nixpkgs"))

(with-eval-after-load 'lsp-mode
  ;; Configure nixd language server for Nix files
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

;; Hook to start LSP in nix-mode when +lsp flag is enabled
(when (modulep! :lang nix +lsp)
  (add-hook 'nix-mode-hook #'lsp-deferred))

(provide 'my-nix-config)
