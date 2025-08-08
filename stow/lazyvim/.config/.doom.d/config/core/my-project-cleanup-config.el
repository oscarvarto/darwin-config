;;; my-project-cleanup-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

;; Protect against deleted project issues by automatically cleaning up invalid references

(defun my/clean-invalid-projects ()
  "Clean up invalid project references from various Emacs caches."
  (interactive)
  
  ;; Clean up recentf - remove non-existent files
  (when (bound-and-true-p recentf-list)
    (setq recentf-list (cl-remove-if-not #'file-exists-p recentf-list))
    (recentf-save-list)
    (message "Cleaned up invalid files from recentf"))
  
  ;; Clean up projectile known projects
  (when (and (bound-and-true-p projectile-known-projects)
             (fboundp 'projectile-cleanup-known-projects))
    (projectile-cleanup-known-projects)
    (message "Cleaned up invalid projects from projectile"))
  
  ;; Clean up savehist
  (when (bound-and-true-p savehist-mode)
    (savehist-save)
    (message "Saved current savehist"))
  
  (message "Project cleanup completed!"))

(defun my/auto-cleanup-on-startup ()
  "Automatically clean up invalid projects on Emacs startup."
  (when (display-graphic-p) ; Only run in GUI mode to avoid startup delays
    (run-with-idle-timer 5 nil #'my/clean-invalid-projects)))

;; Hook to clean up after killing buffers
(defun my/cleanup-after-kill-buffer ()
  "Clean up project references when killing buffers from deleted projects."
  (when (and buffer-file-name
             (not (file-exists-p buffer-file-name)))
    (run-with-idle-timer 1 nil #'my/clean-invalid-projects)))

;; Enhanced recentf configuration to avoid issues
(after! recentf
  (setq recentf-max-menu-items 50
        recentf-max-saved-items 200
        recentf-auto-cleanup 'mode) ; Clean up when recentf-mode is enabled
  
  ;; Add more patterns to exclude
  (add-to-list 'recentf-exclude "/.git/")
  (add-to-list 'recentf-exclude "/tmp/")
  (add-to-list 'recentf-exclude "/var/")
  (add-to-list 'recentf-exclude "\\.tmp$")
  (add-to-list 'recentf-exclude "\\.log$")
  
  ;; Automatically clean up non-existent files every 10 minutes
  (run-with-timer 600 600 
                  (lambda ()
                    (setq recentf-list (cl-remove-if-not #'file-exists-p recentf-list)))))

;; Enhanced projectile configuration
(after! projectile
  ;; Automatically clean up known projects periodically
  (run-with-timer 1800 1800 #'projectile-cleanup-known-projects) ; Every 30 minutes
  
  ;; Remove invalid projects when switching
  (advice-add 'projectile-switch-project :before
              (lambda (&rest _)
                (projectile-cleanup-known-projects))))

;; Enhanced treemacs configuration to handle deleted projects
(after! treemacs
  (setq treemacs-persist-file (expand-file-name "treemacs-persist" doom-cache-dir))
  
  ;; Clean up treemacs workspaces of non-existent projects
  (defun my/treemacs-cleanup-workspaces ()
    "Remove treemacs workspaces with non-existent paths."
    (interactive)
    (when (fboundp 'treemacs-workspaces)
      (dolist (workspace (treemacs-workspaces))
        (dolist (project (treemacs-workspace->projects workspace))
          (unless (file-exists-p (treemacs-project->path project))
            (treemacs-remove-project-from-workspace project))))))
  
  ;; Auto-cleanup treemacs workspaces
  (run-with-timer 1200 1200 #'my/treemacs-cleanup-workspaces)) ; Every 20 minutes

;; Add hooks
(add-hook 'doom-after-init-hook #'my/auto-cleanup-on-startup)
(add-hook 'kill-buffer-hook #'my/cleanup-after-kill-buffer)

;; Manual cleanup command
(map! :leader
      :desc "Clean up invalid projects" "p c" #'my/clean-invalid-projects)

;; Create a cleanup command you can run manually
;;;###autoload
(defun my/emergency-project-cleanup ()
  "Emergency cleanup of all project-related caches when things are broken."
  (interactive)
  (let ((cache-dir (expand-file-name ".local/cache" doom-emacs-dir)))
    
    ;; Backup current cache files before cleaning
    (let ((backup-dir (expand-file-name "backup" cache-dir)))
      (make-directory backup-dir t)
      (dolist (file '("recentf" "treemacs-persist" "savehist" "projectile"))
        (let ((source (expand-file-name file cache-dir))
              (backup (expand-file-name (concat file ".bak") backup-dir)))
          (when (file-exists-p source)
            (copy-file source backup t)))))
    
    ;; Clean up recentf
    (when (file-exists-p (expand-file-name "recentf" cache-dir))
      (with-temp-buffer
        (insert-file-contents (expand-file-name "recentf" cache-dir))
        (goto-char (point-min))
        (while (re-search-forward "\"\\([^\"]+\\)\"" nil t)
          (let ((file (match-string 1)))
            (when (and (string-prefix-p "~/" file)
                       (not (file-exists-p (expand-file-name (substring file 2) "~"))))
              (delete-region (line-beginning-position) (1+ (line-end-position))))))
        (write-file (expand-file-name "recentf" cache-dir))))
    
    ;; Reset projectile cache
    (when (file-exists-p (expand-file-name "projectile" cache-dir))
      (delete-directory (expand-file-name "projectile" cache-dir) t))
    
    (message "Emergency cleanup completed! Restart Emacs for full effect.")
    (when (y-or-n-p "Restart Emacs now? ")
      (restart-emacs))))

(provide 'my-project-cleanup-config)

;;; my-project-cleanup-config.el ends here
