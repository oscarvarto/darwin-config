;;; my-large-files-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Configuration for handling large files efficiently
;; Disables TreeSitter and other heavy features for large files

;; Threshold for considering a file "large" (in bytes)
;; Default: 512KB (512 * 1024 bytes)
(defvar my/large-file-threshold (* 512 1024)
  "File size threshold in bytes above which files are considered large.
Large files will have TreeSitter and other heavy features disabled.")

;; Alternative thresholds you can uncomment:
;; (setq my/large-file-threshold (* 1024 1024))   ; 1MB
;; (setq my/large-file-threshold (* 2 1024 1024)) ; 2MB
;; (setq my/large-file-threshold (* 5 1024 1024)) ; 5MB

;; Features to disable for large files
(defvar my/large-file-disabled-features
  '(tree-sitter-mode
    tree-sitter-hl-mode
    line-reminder-mode
    ts-fold-mode
    ts-fold-indicators-mode
    combobulate-mode
    lsp-mode
    company-mode
    corfu-mode
    flycheck-mode
    syntax-highlighting
    font-lock-mode
    hl-line-mode)
  "List of features to disable for large files.")

;; Track which buffers have been processed to avoid repeated processing
(defvar my/large-file-processed-buffers (make-hash-table :test 'eq)
  "Hash table to track buffers that have been processed for large file optimization.")

;; Function to check if current buffer contains a large file
(defun my/large-file-p ()
  "Return t if current buffer is visiting a large file."
  (when buffer-file-name
    (condition-case err
        (let* ((attrs (file-attributes buffer-file-name))
               (file-size (and attrs (nth 7 attrs))))
          (and file-size
               (numberp file-size)
               (> file-size my/large-file-threshold)))
      (error
       (message "Error checking file size for %s: %s" buffer-file-name (error-message-string err))
       nil))))
;; Function to safely disable a mode if it exists and is enabled
(defun my/safe-disable-mode (mode)
  "Safely disable MODE if it exists and is currently enabled."
  (condition-case err
      (when (and (fboundp mode)
                 (boundp mode)
                 (symbol-value mode))
        (funcall mode -1))
    (error
     (message "Warning: Could not disable %s: %s" mode (error-message-string err)))))

;; Function to disable heavy features for large files
(defun my/disable-features-for-large-file ()
  "Disable heavy features when opening large files."
  (when (and buffer-file-name
             (not (gethash (current-buffer) my/large-file-processed-buffers))
             (my/large-file-p))
    ;; Mark this buffer as processed
    (puthash (current-buffer) t my/large-file-processed-buffers)
    
    (let* ((attrs (file-attributes buffer-file-name))
           (file-size (and attrs (nth 7 attrs))))
      (when file-size
        (message "Large file detected (%s). Disabling heavy features for better performance."
                 (file-size-human-readable file-size))))

    ;; Safely disable features
    (dolist (feature my/large-file-disabled-features)
      (my/safe-disable-mode feature))
    
    ;; Additional cleanup for specific modes that might cause issues
    (condition-case nil
        (progn
          ;; Clean up line-reminder overlays
          (when (fboundp 'line-reminder--clear-all-ovs)
            (line-reminder--clear-all-ovs))
          ;; Cancel any active timers
          (when (and (boundp 'line-reminder--timer)
                     line-reminder--timer)
            (cancel-timer line-reminder--timer)
            (setq line-reminder--timer nil)))
      (error nil))

    ;; Set buffer-local performance optimizations
    (condition-case nil
        (progn
          (setq-local bidi-display-reordering nil)
          (setq-local bidi-paragraph-direction 'left-to-right)
          (setq-local buffer-read-only nil))
      (error nil))

    ;; Display final message
    (let* ((attrs (file-attributes buffer-file-name))
           (file-size (and attrs (nth 7 attrs))))
      (when file-size
        (message "Heavy features disabled for large file. File size: %s"
                 (file-size-human-readable file-size))))))

;; Enhanced version of the TreeSitter check that considers file size
(defun my/should-enable-tree-sitter-p-with-size-check ()
  "Check if tree-sitter should be enabled, considering file size."
  (condition-case nil
      (and (not (my/large-file-p))
           ;; Only check these if the functions exist
           (or (not (fboundp 'my/tree-sitter-disabled-modes))
               (not (and (boundp 'my/tree-sitter-disabled-modes)
                         (memq major-mode my/tree-sitter-disabled-modes))))
           (or (not (fboundp 'my/tree-sitter-language-available-p))
               (my/tree-sitter-language-available-p major-mode)))
    (error nil)))

;; Hook to check file size when opening files
(defun my/check-file-size-on-find-file ()
  "Check file size and disable features if necessary when opening files."
  (condition-case err
      (run-with-idle-timer 0.1 nil #'my/disable-features-for-large-file)
    (error
     (message "Error in large file check: %s" (error-message-string err)))))

;; Clean up processed buffers when they're killed
(defun my/cleanup-large-file-buffer ()
  "Clean up tracking for killed buffers."
  (condition-case nil
      (remhash (current-buffer) my/large-file-processed-buffers)
    (error nil)))

;; User command to manually toggle large file mode
(defun my/toggle-large-file-mode ()
  "Manually toggle large file optimizations for current buffer."
  (interactive)
  (if (get 'my/large-file-mode 'state)
      (progn
        (put 'my/large-file-mode 'state nil)
        (message "Large file mode disabled. Heavy features may be re-enabled."))
    (progn
      (my/disable-features-for-large-file)
      (put 'my/large-file-mode 'state t)
      (message "Large file mode enabled. Heavy features disabled."))))

;; User command to set custom threshold
(defun my/set-large-file-threshold (size)
  "Set custom threshold for large files.
SIZE should be in bytes."
  (interactive "nEnter file size threshold in bytes: ")
  (setq my/large-file-threshold size)
  (message "Large file threshold set to %s (%s)"
           size
           (file-size-human-readable size)))

;; Add hooks safely
(add-hook 'find-file-hook #'my/check-file-size-on-find-file)
(add-hook 'kill-buffer-hook #'my/cleanup-large-file-buffer)

;; Alternative approach: check on mode changes instead of buffer switches
(add-hook 'after-change-major-mode-hook #'my/check-file-size-on-find-file)

;; Integration with existing TreeSitter configuration
;; Override the existing function to include size check
(eval-after-load 'my-tree-sitter-config
  '(progn
     (fset 'my/should-enable-tree-sitter-p 'my/should-enable-tree-sitter-p-with-size-check)
     (message "Large file support integrated with TreeSitter configuration")))

;; Key bindings
(map! :leader
      (:prefix ("t" . "toggle")
       :desc "Toggle large file mode" "L" #'my/toggle-large-file-mode))

(provide 'my-large-files-config)
