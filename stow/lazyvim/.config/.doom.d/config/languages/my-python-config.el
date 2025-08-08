;;; my-python-config.el. -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:
;; LSP Clients for the Python(pyrefly) Type Checker.
;;; Code:

(require 'lsp-mode)

(defgroup lsp-python-refly nil
  "LSP support for Python (pyrefly)."
  :group 'lsp-mode
  :link '(url-link "https://pyrefly.org"))

(defcustom lsp-python-refly-clients-server-command '("pyrefly" "lsp")
  "Command to start the python pyrefly language server."
  :group 'lsp-python-refly
  :risky t
  :type '(repeat string))

(lsp-register-client
 (make-lsp-client :new-connection (lsp-stdio-connection (lambda () lsp-python-refly-clients-server-command))
                  :activation-fn (lsp-activate-on "python")
                  :priority -1
                  :add-on? t
                  :server-id 'py-refly))

(lsp-consistency-check lsp-python-refly)

(provide 'my-python-config)
