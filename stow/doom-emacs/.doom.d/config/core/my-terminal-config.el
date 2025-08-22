;;; my-terminal-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; =============================================================================
;; TERMINAL ENHANCEMENTS FOR DOOM EMACS
;; =============================================================================
;; 
;; Terminal compatibility is handled by Nix (terminal-support.nix)
;; This file provides enhanced terminal features and integrations.

;; =============================================================================
;; ENHANCED TERMINAL FEATURES
;; =============================================================================

;; Enable mouse support in terminal
(when (not (display-graphic-p))
  (xterm-mouse-mode 1)
  ;; Enable mouse wheel scrolling
  (global-set-key [mouse-4] 'scroll-down-line)
  (global-set-key [mouse-5] 'scroll-up-line))

;; Better terminal colors
(when (not (display-graphic-p))
  ;; Force 256-color support
  (setq-default display-color-cells 256))

;; =============================================================================
;; ZSH INTEGRATION
;; =============================================================================

;; Use zsh as the default shell for terminal operations
(when (executable-find "zsh")
  ;; Set zsh as the default shell for terminal operations when available
  (setq shell-file-name (executable-find "zsh"))
  (setq explicit-shell-file-name (executable-find "zsh")))

;; =============================================================================
;; DEBUG HELPERS
;; =============================================================================

;;;###autoload
(defun my/terminal-info ()
  "Show current terminal information for debugging."
  (interactive)
  (let ((term-type (getenv "TERM"))
        (display-type (if (display-graphic-p) "GUI" "Terminal"))
        (colors (display-color-cells))
        (mouse-enabled (if xterm-mouse-mode "Yes" "No")))
    (message "Terminal Info - Type: %s, Display: %s, Colors: %s, Mouse: %s"
             (or term-type "Unknown")
             display-type
             (or colors "Unknown")
             mouse-enabled)
    (when (called-interactively-p 'interactive)
      (with-current-buffer (get-buffer-create "*Terminal Info*")
        (erase-buffer)
        (insert (format "=== TERMINAL INFORMATION ===\n\n"))
        (insert (format "TERM environment: %s\n" (or term-type "Not set")))
        (insert (format "Display type: %s\n" display-type))
        (insert (format "Color cells: %s\n" (or colors "Unknown")))
        (insert (format "Mouse mode: %s\n" mouse-enabled))
        (insert (format "Frame parameters:\n"))
        (dolist (param (frame-parameters))
          (insert (format "  %s: %s\n" (car param) (cdr param))))
        (display-buffer (current-buffer))))))

(provide 'my-terminal-config)
