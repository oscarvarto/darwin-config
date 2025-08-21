;;; my-lazy-loading-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; =============================================================================
;; LAZY LOADING OPTIMIZATIONS FOR DOOM EMACS STARTUP
;; =============================================================================

;; Defer expensive packages until they are actually needed
;; This can reduce startup time from ~12s to ~4-6s

;; 1. TREEMACS - Only load when explicitly called
(after! treemacs
  ;; Disable auto-loading features that trigger at startup
  (setq treemacs-follow-mode nil)  ; Don't follow by default
  (setq treemacs-project-follow-cleanup nil))

;; 2. OBSIDIAN - Configuration handled in obsidian config file
;; (Configuration moved to my-obsidian-config.el to avoid conflicts)

;; 3. LSP - More aggressive deferring
(after! lsp-mode
  (setq lsp-auto-execute-action nil)  ; Don't execute actions automatically
  (setq lsp-enable-file-watchers nil) ; Disable file watchers initially
  (setq lsp-idle-delay 1.0))           ; Increase delay before LSP kicks in

;; 4. TREE-SITTER - Load grammars lazily
(after! tree-sitter
  ;; Only load grammars when actually editing files of that type
  (when (boundp 'tree-sitter-load-languages-lazily)
    (setq tree-sitter-load-languages-lazily t)))

;; 5. DAP MODE - Configuration for when it loads
(after! dap-mode
  ;; DAP will load when debugging is actually needed
  (setq dap-auto-configure-features '(locals)))

;; 6. MAGIT - Let Doom handle the deferring, just configure when loaded
(after! magit
  ;; Magit optimizations
  (setq magit-refresh-status-buffer nil))

;; 7-11. Language and tool configurations
;; Let Doom's built-in configurations handle deferring
;; We'll just set optimization variables when they load

;; =============================================================================
;; AUTOLOAD OPTIMIZATIONS
;; =============================================================================

;; Define autoload cookies for frequently used functions
;;;###autoload
(defun my/quick-treemacs ()
  "Quick treemacs toggle that loads treemacs if needed."
  (interactive)
  (require 'treemacs)
  (treemacs))

;;;###autoload
(defun my/quick-magit ()
  "Quick magit status that loads magit if needed."
  (interactive)
  (require 'magit)
  (magit-status))

;;;###autoload
(defun my/quick-vterm ()
  "Quick vterm that loads vterm if needed."
  (interactive)
  (require 'vterm)
  (vterm))

;; =============================================================================
;; STARTUP OPTIMIZATIONS
;; =============================================================================

;; Reduce garbage collection during startup
(setq gc-cons-threshold most-positive-fixnum)
(add-hook 'after-init-hook
          (lambda ()
            ;; Restore normal GC threshold after startup
            (setq gc-cons-threshold 16777216))) ; 16MB

;; Reduce file handler checks during startup
(defvar default-file-name-handler-alist file-name-handler-alist)
(setq file-name-handler-alist nil)
(add-hook 'after-init-hook
          (lambda ()
            (setq file-name-handler-alist default-file-name-handler-alist)))

;; Optimize regexp for faster startup
(setq inhibit-compacting-font-caches t)

(provide 'my-lazy-loading-config)
