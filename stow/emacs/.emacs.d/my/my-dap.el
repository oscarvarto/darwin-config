;;; my-dap.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; DAP (Debug Adapter Protocol) configuration for Java and Clojure
;; Note: Rust debugging uses dape (configured in my-defaults.el)

(require 'use-package)

;; Configure dap-mode (already installed via elpaca in my-elpaca.el)
(use-package dap-mode
  :ensure nil
  :after lsp-mode
  :config
  ;; Enable dap-mode
  (dap-mode 1)
  (dap-ui-mode 1)
  (dap-ui-controls-mode 1)
  (dap-auto-configure-mode)

  ;; Require Java debugging support
  (require 'dap-java)

  ;; Enable TestNG support for Java
  (setq dap-java-use-testng +1)

  ;; Tooltips and UI configuration
  (dap-tooltip-mode 1)
  (tooltip-mode 1)

  ;; Configure mouse-based debugging features
  (setq dap-breakpoint-global-mode t))

;; Keybindings for dap-mode (optional - uses default prefix C-x C-a)
;; You can customize the prefix by setting dap-key-prefix before loading dap-mode

;; Enable dap-mode for Java buffers
(add-hook 'java-mode-hook #'dap-mode)
(add-hook 'java-ts-mode-hook #'dap-mode)

;; Enable dap-mode for Clojure buffers (optional, for debugging JVM Clojure)
;; Note: Most Clojure debugging is done via cider, but dap-mode can be useful
;; for low-level JVM debugging
(add-hook 'clojure-mode-hook #'dap-mode)
(add-hook 'clojure-ts-mode-hook #'dap-mode)

(provide 'my-dap)
