;;; my-lsp-nu-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

(after! (nushell-mode lsp-mode)
  (add-to-list 'lsp-language-id-configuration '(nushell-mode . "nushell"))
  (lsp-register-client
   (make-lsp-client :new-connection (lsp-stdio-connection (lambda () '("nu" "--lsp")))
                    :major-modes '(nushell-mode)
                    :server-id 'nushell)))

;;(add-to-list 'auto-mode-alist '("\\.nu\\'" . nushell-mode))
(mapc (lambda (extension)
        (add-to-list 'auto-mode-alist (cons (concat "\\." extension "\\'") 'nushell-mode)))
      '("nu" "nuon"))

(provide 'my-lsp-nu-config)

;;; my-lsp-nu-config.el ends here
