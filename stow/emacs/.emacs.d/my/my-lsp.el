;;; my-lsp.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; LSP-mode configuration for Java and Clojure
;; Note: Rust continues to use eglot (configured in my-rust.el)

(require 'cl-lib)
(require 'subr-x)

;; CRITICAL: lsp-use-plists MUST be set BEFORE lsp-mode loads
(setq lsp-use-plists t)

;; Disable snippets if yasnippet is not available
(setq lsp-enable-snippet nil)

;; ============================================================================
;; LSP Booster - Performance optimization for lsp-mode
;; ============================================================================
;; CRITICAL: These advices MUST be installed BEFORE lsp-mode loads/compiles
;; Requires: emacs-lsp-booster binary (install via: cargo install emacs-lsp-booster)

(defun lsp-booster--advice-json-parse (old-fn &rest args)
  "Try to parse bytecode instead of json."
  (or
   (when (equal (following-char) ?#)
     (let ((bytecode (read (current-buffer))))
       (when (byte-code-function-p bytecode)
         (funcall bytecode))))
   (apply old-fn args)))

(advice-add (if (progn (require 'json)
                       (fboundp 'json-parse-buffer))
                'json-parse-buffer
              'json-read)
            :around
            #'lsp-booster--advice-json-parse)

(defun lsp-booster--advice-final-command (old-fn cmd &optional test?)
  "Prepend emacs-lsp-booster command to lsp CMD."
  (let ((orig-result (funcall old-fn cmd test?)))
    (if (and (not test?)                             ;; for check lsp-server-present?
             (not (file-remote-p default-directory)) ;; see lsp-resolve-final-command
             lsp-use-plists
             (not (functionp 'json-rpc-connection))  ;; native json-rpc
             (executable-find "emacs-lsp-booster"))
        (progn
          (when-let* ((command-from-exec-path (executable-find (car orig-result))))
            (setcar orig-result command-from-exec-path))
          (message "Using emacs-lsp-booster for %s!" orig-result)
          (cons "emacs-lsp-booster" orig-result))
      orig-result)))

(advice-add 'lsp-resolve-final-command :around #'lsp-booster--advice-final-command)

;; Note: lsp-mode, lsp-ui, lsp-treemacs, and lsp-java are installed
;; via elpaca in my-elpaca.el, so no :ensure t needed here

;; Basic lsp-mode configuration
(with-eval-after-load 'lsp-mode
  ;; Set keymap prefix
  (setq lsp-keymap-prefix "C-c l")

  ;; Disable company-mode integration (using corfu instead)
  (setq lsp-completion-provider :none)

  ;; Performance settings
  (setq lsp-idle-delay 0.6)
  (setq lsp-log-io nil)  ; Disable IO logging for performance
  (setq lsp-enable-indentation nil)

  ;; File watching
  (setq lsp-file-watch-threshold 50000)

  ;; Add comprehensive ignore patterns
  (cl-pushnew "[/\\\\]target\\(/.*\\)?'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]\\.cargo\\(/.*\\)?'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]dependencies'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]node_modules\\(/.*\\)?'" lsp-file-watch-ignored-directories :test #'equal)
  (cl-pushnew "[/\\\\]\\.git\\(/.*\\)?'" lsp-file-watch-ignored-directories :test #'equal)

  ;; Add file patterns to ignore
  (cl-pushnew "\\.zip\\'" lsp-file-watch-ignored-files :test #'equal)
  (cl-pushnew "\\.tar\\.gz\\'" lsp-file-watch-ignored-files :test #'equal)
  (cl-pushnew "\\.rlib\\'" lsp-file-watch-ignored-files :test #'equal)

  ;; Enable inlay hints
  (setq lsp-inlay-hint-enable t)

  ;; Enable which-key integration
  (add-hook 'lsp-mode-hook #'lsp-enable-which-key-integration)

  ;; Configure eldoc for lsp-mode buffers
  (add-hook 'lsp-mode-hook
            (lambda ()
              ;; Enable eldoc-mode
              (eldoc-mode 1)
              ;; Set buffer-local eldoc strategy for better async support
              (setq-local eldoc-documentation-strategy 'eldoc-documentation-compose)
              ;; Reduce eldoc idle delay for more responsive documentation
              (setq-local eldoc-idle-delay 0.2))))

;; LSP UI configuration
(with-eval-after-load 'lsp-ui
  ;; Disable lsp-ui-doc to prevent interference with eldoc/eldoc-box
  ;; lsp-ui-doc has its own hover mechanism that conflicts with eldoc integration
  (setq lsp-ui-doc-enable nil                  ; Disable to allow eldoc to work
        lsp-ui-doc-show-with-cursor nil        ; Ensure no automatic popup
        lsp-ui-doc-show-with-mouse nil         ; Ensure no automatic popup
        lsp-ui-peek-always-show nil))

;; LSP treemacs integration (optional)
(with-eval-after-load 'lsp-treemacs
  ;; Enable bidirectional synchronization
  (lsp-treemacs-sync-mode 1))

;; LSP eldoc settings
(with-eval-after-load 'lsp-mode
  (setq lsp-eldoc-render-all t)
  (setq lsp-eldoc-enable-hover t)  ; Ensure hover is enabled
  (setq lsp-signature-auto-activate t)

  ;; Configure eldoc to work properly with lsp-mode
  ;; Use eldoc-documentation-compose to combine multiple sources
  (setq eldoc-documentation-strategy 'eldoc-documentation-compose))

(provide 'my-lsp)
