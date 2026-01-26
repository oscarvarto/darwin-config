;;; my-nushell.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Nushell language support with lsp-mode and nu --lsp

(require 'use-package)

;; Configure nushell-mode (already installed via elpaca in my-elpaca.el)
(use-package nushell-mode
  :ensure nil)

;; Configure nushell language server
(with-eval-after-load 'lsp-mode
  ;; Register nushell language ID
  (add-to-list 'lsp-language-id-configuration '(nushell-mode . "nushell"))

  ;; Register nushell language server client
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection (lambda () '("nu" "--lsp")))
                    :major-modes '(nushell-mode)
                    :server-id 'nushell)))

;; Add file associations for nushell files
(mapc (lambda (extension)
        (add-to-list 'auto-mode-alist (cons (concat "\\." extension "\\'") 'nushell-mode)))
      '("nu" "nuon"))

;; Enable lsp-mode for nushell-mode
(add-hook 'nushell-mode-hook #'lsp-deferred)

(provide 'my-nushell)
