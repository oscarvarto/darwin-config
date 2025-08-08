;;; my-tree-sitter-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Define modes where tree-sitter should never be enabled
(defvar my/tree-sitter-disabled-modes
  '(conf-mode
    dockerfile-mode
    lisp-data-mode
    fundamental-mode
    gnuplot-mode
    Info-mode
    text-mode) ;; Add more modes as needed
  "List of major modes where tree-sitter should never be enabled.")

;; Function to check if tree-sitter grammar is available for a mode
(defun my/tree-sitter-language-available-p (mode)
  "Check if tree-sitter grammar is available for MODE."
  (when-let ((language (alist-get mode tree-sitter-major-mode-language-alist)))
    (condition-case nil
        (tree-sitter-require language)
      (error nil))))

;; Function to determine if tree-sitter should be enabled
(defun my/should-enable-tree-sitter-p ()
  "Check if tree-sitter should be enabled for current major mode."
  (and (not (memq major-mode my/tree-sitter-disabled-modes))
       (my/tree-sitter-language-available-p major-mode)))

;; Safe tree-sitter mode activation
(defun my/safe-tree-sitter-mode ()
  "Enable tree-sitter mode only if grammar is available for current major mode."
  (when (and (fboundp 'tree-sitter-mode)
             (my/should-enable-tree-sitter-p))
    (condition-case err
        (tree-sitter-mode +1)
      (error
       (message "Tree-sitter failed for %s: %s" major-mode (error-message-string err))))))

;; Use Doom variables for paths if available, otherwise keep original logic
;; (add-to-list 'tree-sitter-load-path (expand-file-name "tree-sitter" doom-cache-dir))
;; (add-to-list 'tree-sitter-load-path (expand-file-name "straight/build-30.1/tree-sitter-langs/bin/" doom-local-dir))
;; Original paths:
;; (add-to-list 'tree-sitter-load-path "/Users/oscarvarto/.emacs.d/.local/cache/tree-sitter/")
;; (add-to-list 'tree-sitter-load-path "/Users/oscarvarto/.emacs.d/.local/straight/build-30.1/tree-sitter-langs/bin/")

(use-package tree-sitter
  :config
  ;; Configure Doom's tree-sitter settings more carefully
  (setq +tree-sitter-hl-enabled-modes
        `(not ,@my/tree-sitter-disabled-modes))

  ;; Conditional tree-sitter highlighting
  (defun my/conditional-tree-sitter-hl-mode ()
    "Enable tree-sitter highlighting only if appropriate."
    (when (my/should-enable-tree-sitter-p)
      (condition-case err
          (tree-sitter-hl-mode +1)
        (error
         (message "Tree-sitter highlighting failed for %s: %s" major-mode (error-message-string err))))))

  ;; Replace the direct hook with conditional version
  (add-hook 'tree-sitter-after-on-hook #'my/conditional-tree-sitter-hl-mode)

  ;; Enable tree-sitter mode conditionally via hook instead of globally
  (add-hook 'prog-mode-hook #'my/safe-tree-sitter-mode)

  ;; Disable tree-sitter for specific modes that cause issues
  (dolist (mode my/tree-sitter-disabled-modes)
    (let ((hook-name (intern (concat (symbol-name mode) "-hook"))))
      (when (boundp hook-name)
        (add-hook hook-name
                  (lambda ()
                    (when (bound-and-true-p tree-sitter-mode)
                      (tree-sitter-mode -1))))))))

(setq major-mode-remap-alist
      (append '((css-mode  . css-ts-mode)
                (scss-mode . css-ts-mode))
              major-mode-remap-alist))

(setq tree-sitter-major-mode-language-alist
      (append
       tree-sitter-major-mode-language-alist
       '((css-ts-mode . css))))

(use-package! line-reminder
  :config
  ;; Configuration
  (setq line-reminder-show-option 'linum)
  (setq line-reminder-fringe-placed 'right-fringe)

  ;; Simple buffer size check without dependencies
  (defun my/line-reminder-buffer-too-large-p ()
    "Check if buffer is too large for line-reminder."
    (and buffer-file-name
         (> (buffer-size) (* 2 1024 1024)))) ;; 2MB threshold

  ;; Add buffer size validation to prevent out-of-range errors
  (defun my/line-reminder-safe-p ()
    "Check if it's safe to use line-reminder in current buffer."
    (and (buffer-file-name)
         (> (buffer-size) 0)
         (not (my/line-reminder-buffer-too-large-p))
         (not (buffer-narrowed-p))
         (not (minibufferp))
         (not (string-match-p "\*" (buffer-name))))) ;; Avoid special buffers

  ;; Safe line-reminder mode activation with error handling
  (defun my/safe-line-reminder-mode ()
    "Enable line-reminder mode only for safe conditions with error handling."
    (when (and (my/line-reminder-safe-p)
               (my/should-enable-tree-sitter-p))
      (condition-case err
          (line-reminder-mode +1)
        (args-out-of-range
         (message "Line-reminder args-out-of-range error prevented for %s" (buffer-name)))
        (error
         (message "Line-reminder failed for %s: %s" major-mode (error-message-string err))))))

  ;; Hook with delay to avoid race conditions
  (defun my/delayed-line-reminder-setup ()
    "Setup line-reminder with a small delay to avoid race conditions."
    (when (my/line-reminder-safe-p)
      (run-with-timer 0.2 nil #'my/safe-line-reminder-mode)))

  :hook (prog-mode . my/delayed-line-reminder-setup))

(use-package! ts-fold
  :config
  ;; Safe ts-fold mode activation
  (defun my/safe-ts-fold-mode ()
    "Enable ts-fold mode only for safe tree-sitter modes."
    (when (my/should-enable-tree-sitter-p)
      (ts-fold-mode +1)))

  (defun my/safe-ts-fold-indicators-mode ()
    "Enable ts-fold-indicators mode only for safe tree-sitter modes."
    (when (my/should-enable-tree-sitter-p)
      (ts-fold-indicators-mode +1)))

  (add-hook! 'prog-mode-hook #'my/safe-ts-fold-mode)
  (add-hook! 'prog-mode-hook #'my/safe-ts-fold-indicators-mode)
  (map! :after ts-fold
        :leader
        (:prefix ("t" . "toggle")
                 (:prefix ("z" . "fold")
                  :desc "Toggle fold at point" "t" #'ts-fold-toggle
                  :desc "Close fold at point" "c" #'ts-fold-close
                  :desc "Open fold at point" "o" #'ts-fold-open
                  :desc "Open fold recursively" "O" #'ts-fold-open-recursively
                  :desc "Close all folds" "C" #'ts-fold-close-all
                  :desc "Open all folds" "a" #'ts-fold-open-all))))

;; Configure ts-fold integration with line-reminder safely
(with-eval-after-load 'line-reminder
  ;; Safe integration functions
  (when (fboundp 'line-reminder--get-face)
    (setq ts-fold-indicators-face-function
          (lambda (pos &rest _)
            ;; Return the face of it's function.
            (condition-case nil
                (when (and (integerp pos)
                           (> pos 0)
                           (<= pos (point-max)))
                  (line-reminder--get-face (line-number-at-pos pos t)))
              (error 'default)))))

  (when (fboundp 'ts-fold--overlays-in)
    (setq line-reminder-add-line-function
          (lambda (&rest _)
            (condition-case nil
                (and (not (buffer-narrowed-p))
                     (null (ts-fold--overlays-in 'ts-fold-indicators-window (selected-window)
                                                 (line-beginning-position) (line-end-position))))
              (error t))))))

(use-package combobulate
  :config
  (defun my/safe-combobulate-mode ()
    "Enable combobulate-mode only for safe tree-sitter modes."
    (when (my/should-enable-tree-sitter-p)
      (combobulate-mode +1)))
  :custom
  ;; You can customize Combobulate's key prefix here.
  ;; Note that you may have to restart Emacs for this to take effect!
  (combobulate-key-prefix "C-c o")
  :hook ((prog-mode . #'my/safe-combobulate-mode)))

(provide 'my-tree-sitter-config)
