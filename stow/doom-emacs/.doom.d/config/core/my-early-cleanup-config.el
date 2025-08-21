;;; my-early-cleanup-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

;; Minimal early cleanup to prevent treemacs startup errors

(defun my/clean-projectile-cache ()
  "Clean projectile cache from invalid paths."
  (let ((cache-file (expand-file-name "projectile/projects.eld" (expand-file-name ".local/cache" (expand-file-name "~/.emacs.d")))))
    (when (file-exists-p cache-file)
      (condition-case err
          (let* ((projects (with-temp-buffer
                            (insert-file-contents cache-file)
                            (read (current-buffer))))
                 (valid-projects (seq-filter (lambda (path) (file-exists-p (expand-file-name path))) projects))
                 (removed-count (- (length projects) (length valid-projects))))
            (when (> removed-count 0)
              (with-temp-file cache-file
                (prin1 valid-projects (current-buffer)))
              (message "Cleaned %d invalid projects from cache" removed-count)))
        (error (message "Warning: Could not clean projectile cache: %s" err))))))

;; Run cleanup early in startup
(add-hook 'doom-before-init-hook #'my/clean-projectile-cache)

(provide 'my-early-cleanup-config)

;;; my-early-cleanup-config.el ends here
