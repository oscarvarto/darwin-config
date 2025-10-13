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

;; Function to determine if treesit should be enabled
(defun my/should-enable-treesit-p ()
  "Check if treesit should be enabled for current major mode."
  (and (treesit-available-p)
       (not (memq major-mode my/tree-sitter-disabled-modes))
       (treesit-language-at (point))))

;; Safe treesit mode activation (mainly for compatibility with hooks)
(defun my/safe-treesit-mode ()
  "Ensure treesit is available for current major mode."
  (when (and (treesit-available-p)
             (not (memq major-mode my/tree-sitter-disabled-modes)))
    (condition-case err
        (when (treesit-language-at (point))
          (message "Treesit available for %s" major-mode))
      (error
       (message "Treesit failed for %s: %s" major-mode (error-message-string err))))))

(use-package treesit
  :config
  ;; Set a safer default font-lock level
  (setq treesit-font-lock-level 3)

  ;; Auto-enable treesit modes for supported languages
  ;; Note: rust-mode is NOT remapped here because rustic-mode (enabled via Doom's rust module)
  ;; handles .rs files and has its own tree-sitter integration
  (setq major-mode-remap-alist
        (append '((c-mode . c-ts-mode)
                  (c++-mode . c++-ts-mode)
                  (cmake-mode . cmake-ts-mode)
                  (conf-toml-mode . toml-ts-mode)
                  (css-mode . css-ts-mode)
                  (js-mode . js-ts-mode)
                  (javascript-mode . js-ts-mode)
                  (json-mode . json-ts-mode)
                  (python-mode . python-ts-mode)
                  (sh-mode . bash-ts-mode)
                  (swift-mode . swift-ts-mode)
                  (typescript-mode . typescript-ts-mode)
                  ;; (rust-mode . rust-ts-mode)  ; Commented out - conflicts with rustic-mode
                  (yaml-mode . yaml-ts-mode))
                major-mode-remap-alist))

  ;; Install language grammars automatically
  ;; Note: Rust grammar is handled by Doom's rust module, don't define it here
  (when (treesit-available-p)
    ;; Define language sources for automatic installation
    (dolist (lang-source '((bash "https://github.com/tree-sitter/tree-sitter-bash")
                           (c "https://github.com/tree-sitter/tree-sitter-c")
                           (cpp "https://github.com/tree-sitter/tree-sitter-cpp")
                           (cmake "https://github.com/uyha/tree-sitter-cmake")
                           (css "https://github.com/tree-sitter/tree-sitter-css")
                           (javascript "https://github.com/tree-sitter/tree-sitter-javascript")
                           (json "https://github.com/tree-sitter/tree-sitter-json")
                           (python "https://github.com/tree-sitter/tree-sitter-python")
                           ;; (rust "https://github.com/tree-sitter/tree-sitter-rust")  ; Managed by Doom's rust module
                           (toml "https://github.com/tree-sitter/tree-sitter-toml")
                           (typescript "https://github.com/tree-sitter/tree-sitter-typescript" "master" "typescript/src")
                           (tsx "https://github.com/tree-sitter/tree-sitter-typescript" "master" "tsx/src")
                           (yaml "https://github.com/ikatyang/tree-sitter-yaml")))
      (add-to-list 'treesit-language-source-alist lang-source))))

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
               (not (memq major-mode my/tree-sitter-disabled-modes)))
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

(use-package! treesit-fold
  :config
  (defun my/safe-treesit-fold-mode ()
    "Enable treesit-fold mode only for safe tree-sitter modes."
    (when (and (treesit-available-p)
               (not (memq major-mode my/tree-sitter-disabled-modes))
               (treesit-language-at (point)))
      (treesit-fold-mode +1)))

  (defun my/safe-treesit-fold-indicators-mode ()
    "Enable treesit-fold-indicators mode only for safe tree-sitter modes."
    (when (and (treesit-available-p)
               (not (memq major-mode my/tree-sitter-disabled-modes))
               (treesit-language-at (point)))
      (treesit-fold-indicators-mode +1)))

  (add-hook! 'prog-mode-hook #'my/safe-treesit-fold-mode)
  (add-hook! 'prog-mode-hook #'my/safe-treesit-fold-indicators-mode)
  (map! :after ts-fold
        :leader
        (:prefix ("t" . "toggle")
                 (:prefix ("z" . "fold")
                  :desc "Toggle fold at point" "t" #'treesit-fold-toggle
                  :desc "Close fold at point" "c" #'treesit-fold-close
                  :desc "Open fold at point" "o" #'treesit-fold-open
                  :desc "Open fold recursively" "O" #'treesit-fold-open-recursively
                  :desc "Close all folds" "C" #'treesit-fold-close-all
                  :desc "Open all folds" "a" #'treesit-fold-open-all))))

;; Configure ts-fold integration with line-reminder safely
(with-eval-after-load 'line-reminder
  ;; Safe integration functions
  (when (fboundp 'line-reminder--get-face)
    (setq treesit-fold-indicators-face-function
          (lambda (pos &rest _)
            ;; Return the face of it's function.
            (condition-case nil
                (when (and (integerp pos)
                           (> pos 0)
                           (<= pos (point-max)))
                  (line-reminder--get-face (line-number-at-pos pos t)))
              (error 'default)))))

  (when (fboundp 'treesit-fold--overlays-in)
    (setq line-reminder-add-line-function
          (lambda (&rest _)
            (condition-case nil
                (and (not (buffer-narrowed-p))
                     (null (treesit-fold--overlays-in 'treesit-fold-indicators-window (selected-window)
                                                 (line-beginning-position) (line-end-position))))
              (error t))))))

(use-package combobulate
  :config
  (defun my/safe-combobulate-mode ()
    "Enable combobulate-mode only for safe tree-sitter modes."
    (when (and (treesit-available-p)
               (not (memq major-mode my/tree-sitter-disabled-modes))
               (treesit-language-at (point)))
      (combobulate-mode +1)))
  :custom
  ;; You can customize Combobulate's key prefix here.
  ;; Note that you may have to restart Emacs for this to take effect!
  (combobulate-key-prefix "C-c o")
  :hook ((prog-mode . #'my/safe-combobulate-mode)))

(provide 'my-tree-sitter-config)
