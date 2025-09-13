;;; my-startup-benchmark.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; =============================================================================
;; DOOM STARTUP BENCHMARKING AND OPTIMIZATION UTILITIES
;; =============================================================================

(defvar my/startup-time nil
  "Time taken for Emacs to start up.")

(defvar my/startup-package-count nil
  "Number of packages loaded at startup.")

(defun my/benchmark-startup ()
  "Record startup time and package count."
  (when (and after-init-time before-init-time)
    (setq my/startup-time 
          (float-time (time-subtract after-init-time before-init-time)))
    ;; Use a safer way to count packages that doesn't rely on doom-packages
    (setq my/startup-package-count 
          (condition-case nil
              (cond
               ;; Try doom-packages if available
               ((fboundp 'doom-packages) (length (doom-packages)))
               ;; Fallback to straight packages if available
               ((and (fboundp 'straight--profile-get-packages)
                     (boundp 'straight-current-profile))
                (length (straight--profile-get-packages straight-current-profile)))
               ;; Last resort: count features
               (t (length features)))
            (error 0)))
    (message "🚀 Doom loaded %d packages in %.3fs" 
             my/startup-package-count my/startup-time)))

;; Run benchmark after startup
(add-hook 'after-init-hook #'my/benchmark-startup)

;; =============================================================================
;; QUICK ACCESS FUNCTIONS (OPTIMIZED)
;; =============================================================================

;;;###autoload
(defun my/quick-treemacs ()
  "Quick treemacs toggle with lazy loading."
  (interactive)
  (if (modulep! :ui treemacs)
      (if (get-buffer "*Treemacs*")
          (treemacs)
        (progn
          (require 'treemacs)
          (treemacs)))
    (message "Treemacs module not enabled")))

;;;###autoload  
(defun my/quick-magit ()
  "Quick magit status with lazy loading."
  (interactive)
  (if (modulep! :tools magit)
      (progn
        (require 'magit)
        (magit-status))
    (message "Magit module not enabled")))

;;;###autoload
(defun my/quick-vterm ()
  "Quick vterm with lazy loading."
  (interactive)
  (if (and (modulep! :term vterm) (package-installed-p 'vterm))
      (progn
        (require 'vterm)
        (vterm))
    (message "vterm not available")))

;;;###autoload
(defun my/quick-eshell ()
  "Quick eshell (always available in Doom)."
  (interactive)
  (eshell))

;;;###autoload
(defun my/quick-obsidian-capture ()
  "Quick obsidian capture with lazy loading."
  (interactive)
  (if (package-installed-p 'obsidian)
      (progn
        (require 'obsidian)
        (obsidian-capture))
    (message "Obsidian package not available")))

;; =============================================================================
;; STARTUP OPTIMIZATION HELPERS
;; =============================================================================

(defun my/show-slow-packages ()
  "Show packages that might be contributing to slow startup."
  (interactive)
  (let ((slow-packages '(treemacs lsp-mode dap-mode magit org pdf-tools
                         rustic clojure-mode vterm eat
                         tabnine obsidian gptel)))
    (message "Potentially slow packages in your config:")
    (dolist (pkg slow-packages)
      (when (package-installed-p pkg)
        (message "  - %s: %s" 
                 pkg 
                 (if (featurep pkg) "LOADED" "not loaded"))))))

(defun my/reload-config-fast ()
  "Reload Doom configuration with optimizations."
  (interactive)
  (let ((gc-cons-threshold most-positive-fixnum))
    (doom/reload)
    (message "Doom reloaded with GC optimization")))

;; =============================================================================
;; KEY BINDINGS FOR QUICK ACCESS
;; =============================================================================

(map! :leader
      :prefix ("q" . "quick access")
      :desc "Quick treemacs" "t" #'my/quick-treemacs
      :desc "Quick magit" "g" #'my/quick-magit
      :desc "Quick vterm" "v" #'my/quick-vterm  
      :desc "Quick eshell" "e" #'my/quick-eshell
      :desc "Quick obsidian capture" "o" #'my/quick-obsidian-capture
      :desc "Show slow packages" "s" #'my/show-slow-packages
      :desc "Benchmark info" "b" (lambda () 
                                  (interactive)
                                  (if my/startup-time
                                      (message "Last startup: %.3fs with %d packages"
                                               my/startup-time my/startup-package-count)
                                    (message "No startup benchmark available"))))

(provide 'my-startup-benchmark)
