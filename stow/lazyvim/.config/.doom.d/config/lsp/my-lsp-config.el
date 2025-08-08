;;; my-lsp-config.el  -*- lexical-binding: t; no-byte-compile: t; -*-
(setenv "NODE_PATH" "/Users/oscarvarto/.volta/bin")

(after! (:or lsp-mode rust-mode rustic)
  ;; Increase threshold significantly for Rust projects
  (setq lsp-file-watch-threshold 50000)
  ;; Optionally disable file watchers entirely for better performance
  ;; (setq lsp-enable-file-watchers nil)
  (require 'cl-lib)

  ;; Daemon-mode safety: delay LSP initialization if needed
  ;; (when (daemonp)
  ;;   (message "Running in daemon mode, applying LSP safety measures")
  ;;   ;; Add a small delay to ensure environment is fully loaded
  ;;   (run-with-timer 1 nil
  ;;                   (lambda ()
  ;;                     (message "LSP daemon initialization delay completed"))))

  ;; Add comprehensive ignore patterns for Rust projects
  (cl-pushnew "[/\\\\]target\\(/.*\\)?\\'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]\\.cargo\\(/.*\\)?\\'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "/Users/oscarvarto/\\.cargo\\(/.*\\|\\'\\)"
              lsp-file-watch-ignored-directories
              :test #'equal)
  (cl-pushnew "[/\\\\]dependencies\\'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]node_modules\\(/.*\\)?\\'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]\\.git\\(/.*\\)?\\'" lsp-file-watch-ignored-directories :test #'equal)

  ;; Add file patterns to ignore
  (cl-pushnew "\\.zip\\'" lsp-file-watch-ignored-files :test #'equal)
  (cl-pushnew "\\.tar\\.gz\\'" lsp-file-watch-ignored-files :test #'equal)
  (cl-pushnew "\\.rlib\\'" lsp-file-watch-ignored-files :test #'equal))

(use-package lsp-mode
  :init
  (setq lsp-keymap-prefix "C-c l")
  (setq lsp-enable-indentation nil)
  (setq lsp-log-io nil)
  :custom
  (lsp-idle-delay 0.6)
  (lsp-inlay-hint-enable t)
  :hook ((java-ts-mode java-mode) . lsp)
  :hook ((java-ts-mode java-mode) . ts-fold-indicators-mode)
  :hook ((scala-ts-mode scala-mode) . lsp)
  :hook ((scala-ts-mode scala-mode) . ts-fold-indicators-mode)
  :hook ((typescript-ts-mode typescript-mode) . lsp)
  :hook ((typescript-ts-mode typescript-mode) . ts-fold-indicators-mode)
  ;; if you want which-key integration
  :hook (lsp-mode . lsp-enable-which-key-integration)
  :commands lsp)

(use-package lsp-ui
  :init
  (setq lsp-ui-doc-enable t                    ; Keep doc functionality available
        lsp-ui-doc-show-with-cursor nil        ; Disable automatic popup on cursor hover
        lsp-ui-doc-show-with-mouse nil         ; Disable automatic popup on mouse hover
        lsp-ui-doc-popup-enabled t             ; Keep popup capability for manual use
        lsp-ui-doc-popup-max-width 0.8
        lsp-ui-doc-delay 1.0                   ; Add delay if somehow triggered
        lsp-ui-peek-always-show nil)
  :commands lsp-ui-mode)

(use-package lsp-treemacs
  :commands lsp-treemacs-errors-list)

(load! "my-lsp-booster-config")
;; (load! "my-lsp-java-config")
;; (require 'dap-netcore)
;; (setq dap-netcore-download-url "file:///Users/oscarvarto/git-repos/netcoredbg/netcoredbg-osx-arm64.tar.gz")

(load! "my-lsp-nu-config")

;; Enable word wrap in echo area
(setq resize-mini-windows t)
(setq truncate-partial-width-windows nil)
(setq truncate-lines nil)

;; Specifically for eldoc - disable automatic display but keep functionality
(setq eldoc-echo-area-use-multiline-p t)
(setq eldoc-idle-delay 3600)  ; Very large delay to effectively disable automatic display
(setq eldoc-echo-area-display-truncation-message nil)

;; Configure eldoc to work manually but not automatically
(after! eldoc
  (setq eldoc-documentation-strategy 'eldoc-documentation-compose)
  ;; Keep eldoc-display-functions for manual use
  ;; This allows manual functions to work while preventing automatic display
  (setq eldoc-display-functions '(eldoc-display-in-echo-area))
  ;; But make sure automatic display is effectively disabled with the large delay
  (global-eldoc-mode 1))  ; Keep eldoc mode enabled for manual use

;; Additional safeguards to prevent automatic eldoc popup
(after! (:any lsp-mode lsp-ui)
  (setq lsp-eldoc-render-all t)
  (setq lsp-signature-auto-activate t)
  (setq lsp-ui-doc-show-with-cursor nil)
  (setq lsp-ui-doc-show-with-mouse nil))

;; Set maximum width for echo area (120 characters)
(setq max-mini-window-height 0.5)
(setq resize-mini-windows-safe t)
(setq truncate-string-ellipsis "...")
(setq message-truncate-lines nil)

(setq-default fill-column 120)
(add-hook 'help-mode-hook #'visual-line-mode)
(add-hook 'help-mode-hook #'visual-fill-column-mode)

(provide 'my-lsp-config)
