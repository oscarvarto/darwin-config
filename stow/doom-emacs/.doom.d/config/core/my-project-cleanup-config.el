;;; my-project-cleanup-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

;; Protect against deleted project issues by automatically cleaning up invalid references
;; This configuration handles both projectile and treemacs-projectile integration

(defvar my/project-cleanup--running nil
  "Prevent recursive calls to project cleanup.")

(defun my/clean-invalid-projects ()
  "Clean up invalid project references from various Emacs caches."
  (interactive)
  (when (not my/project-cleanup--running)
    (setq my/project-cleanup--running t)
    (unwind-protect
        (progn
          ;; Clean up recentf - remove non-existent files
          (when (bound-and-true-p recentf-list)
            (let ((original-count (length recentf-list)))
              (setq recentf-list (cl-remove-if-not #'file-exists-p recentf-list))
              (when (and (fboundp 'recentf-save-list) recentf-mode)
                (recentf-save-list))
              (message "Cleaned up %d invalid files from recentf" (- original-count (length recentf-list)))))
          
          ;; Clean up projectile known projects
          (when (and (bound-and-true-p projectile-known-projects)
                     (fboundp 'projectile-cleanup-known-projects))
            (let ((original-count (length projectile-known-projects)))
              (projectile-cleanup-known-projects)
              (message "Cleaned up %d invalid projects from projectile" (- original-count (length projectile-known-projects)))))
          
          ;; Clean up treemacs workspaces (if treemacs is loaded)
          (when (and (featurep 'treemacs) (fboundp 'treemacs-current-workspace))
            (my/treemacs-cleanup-workspaces))
          
          ;; Clean up savehist
          (when (bound-and-true-p savehist-mode)
            (savehist-save)
            (message "Saved current savehist"))
          
          (message "Project cleanup completed!"))
      (setq my/project-cleanup--running nil))))

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
;; This needs to handle both treemacs and treemacs-projectile
(after! treemacs
  (setq treemacs-persist-file (expand-file-name "treemacs-persist" doom-cache-dir))
  
  ;; Define the cleanup function but wait for treemacs to be fully loaded
  (defun my/treemacs-cleanup-workspaces ()
    "Remove treemacs workspaces with non-existent paths."
    (interactive)
    (condition-case err
        (when (and (fboundp 'treemacs-workspaces)
                   (fboundp 'treemacs-workspace->projects)
                   (fboundp 'treemacs-project->path)
                   (fboundp 'treemacs-remove-project-from-workspace))
          (let ((cleaned-count 0))
            (dolist (workspace (treemacs-workspaces))
              (dolist (project (treemacs-workspace->projects workspace))
                (let ((project-path (treemacs-project->path project)))
                  (when (and project-path
                             (not (file-exists-p project-path)))
                    (treemacs-remove-project-from-workspace project)
                    (setq cleaned-count (1+ cleaned-count))))))
            (when (> cleaned-count 0)
              (message "Cleaned up %d invalid projects from treemacs" cleaned-count))
            ;; Also handle treemacs-projectile sync if available
            (when (fboundp 'treemacs-projectile--cleanup-known-projects)
              (treemacs-projectile--cleanup-known-projects))))
      (error (message "Error during treemacs cleanup: %s" err))))
  
  ;; Auto-cleanup treemacs workspaces, but delay until treemacs is ready
  (run-with-idle-timer 30 nil
                       (lambda ()
                         (run-with-timer 1200 1200 #'my/treemacs-cleanup-workspaces))))

;; Handle treemacs-projectile integration specifically
(after! treemacs-projectile
  ;; Clean up treemacs-projectile when projectile cleans up
  (advice-add 'projectile-cleanup-known-projects :after
              (lambda ()
                ;; Use the correct function name - it may vary between versions
                (cond
                 ((fboundp 'treemacs-projectile--cleanup-known-projects)
                  (treemacs-projectile--cleanup-known-projects))
                 ((fboundp 'treemacs-projectile-cleanup-known-projects)
                  (treemacs-projectile-cleanup-known-projects))
                 ;; Fallback: manually sync projects
                 (t (my/treemacs-projectile-manual-sync)))))
  
  ;; Sync treemacs projects with projectile changes
  (defun my/treemacs-projectile-manual-sync ()
    "Manually sync treemacs projects with projectile known projects."
    (when (and (bound-and-true-p treemacs-override-workspace)
               (fboundp 'treemacs-workspace->projects)
               (fboundp 'treemacs-project->path)
               (bound-and-true-p projectile-known-projects))
      ;; Remove treemacs projects that are not in projectile
      (let* ((workspace (treemacs-current-workspace))
             (treemacs-projects (treemacs-workspace->projects workspace))
             (projectile-paths (mapcar #'directory-file-name projectile-known-projects)))
        (dolist (project treemacs-projects)
          (let ((project-path (directory-file-name (treemacs-project->path project))))
            (unless (member project-path projectile-paths)
              (treemacs-remove-project-from-workspace project))))))
  
  ;; Also sync treemacs projects with projectile periodically
  (run-with-timer 900 900 ; Every 15 minutes
                  (lambda ()
                    (when (not my/project-cleanup--running)
                      (condition-case nil
                          (cond
                           ((fboundp 'treemacs-projectile--cleanup-known-projects)
                            (treemacs-projectile--cleanup-known-projects))
                           ((fboundp 'treemacs-projectile-cleanup-known-projects)
                            (treemacs-projectile-cleanup-known-projects))
                           (t (my/treemacs-projectile-manual-sync)))
                        (error nil))))))

;; Add hooks
(add-hook 'doom-after-init-hook #'my/auto-cleanup-on-startup)
(add-hook 'kill-buffer-hook #'my/cleanup-after-kill-buffer)

;; Manual cleanup commands
(map! :leader
      :desc "Clean up invalid projects" "p c" #'my/clean-invalid-projects
      :desc "Clean up treemacs workspaces" "p C" #'my/treemacs-cleanup-workspaces
      :desc "Emergency project cleanup" "p x" #'my/emergency-project-cleanup
      :desc "Debug project state" "p d" #'my/debug-project-state)

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
        (while (re-search-forward "\"\([^\"]+\)\"" nil t)
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

;;;###autoload
(defun my/debug-project-state ()
  "Debug function to show the current state of project management systems."
  (interactive)
  (with-current-buffer (get-buffer-create "*Project Debug*")
    (erase-buffer)
    (insert "=== PROJECT MANAGEMENT DEBUG INFO ===\n\n")
    
    ;; Recentf info
    (insert "RECENTF:\n")
    (insert (format "  Mode enabled: %s\n" (bound-and-true-p recentf-mode)))
    (insert (format "  Total files: %d\n" (if (bound-and-true-p recentf-list) (length recentf-list) 0)))
    (when (bound-and-true-p recentf-list)
      (let ((invalid-files (cl-remove-if #'file-exists-p recentf-list)))
        (insert (format "  Invalid files: %d\n" (length invalid-files)))))
    (insert "\n")
    
    ;; Projectile info
    (insert "PROJECTILE:\n")
    (insert (format "  Mode enabled: %s\n" (bound-and-true-p projectile-mode)))
    (insert (format "  Known projects: %d\n" (if (bound-and-true-p projectile-known-projects) (length projectile-known-projects) 0)))
    (when (bound-and-true-p projectile-known-projects)
      (let ((invalid-projects (cl-remove-if #'file-exists-p projectile-known-projects)))
        (insert (format "  Invalid projects: %d\n" (length invalid-projects)))
        (when invalid-projects
          (insert "  Invalid project paths:\n")
          (dolist (project invalid-projects)
            (insert (format "    - %s\n" project))))))
    (insert "\n")
    
    ;; Treemacs info
    (insert "TREEMACS:\n")
    (insert (format "  Loaded: %s\n" (featurep 'treemacs)))
    (when (featurep 'treemacs)
      (insert (format "  Workspaces function available: %s\n" (fboundp 'treemacs-workspaces)))
      (when (fboundp 'treemacs-workspaces)
        (let ((workspaces (treemacs-workspaces)))
          (insert (format "  Total workspaces: %d\n" (length workspaces)))
          (dolist (workspace workspaces)
            (when (fboundp 'treemacs-workspace->projects)
              (let ((projects (treemacs-workspace->projects workspace)))
                (insert (format "    Workspace projects: %d\n" (length projects)))
                (when (fboundp 'treemacs-project->path)
                  (let ((invalid-projects (cl-remove-if (lambda (p) (file-exists-p (treemacs-project->path p))) projects)))
                    (insert (format "    Invalid projects: %d\n" (length invalid-projects))))))))))))
    (insert "\n")
    
    ;; Treemacs-projectile info
    (insert "TREEMACS-PROJECTILE:\n")
    (insert (format "  Loaded: %s\n" (featurep 'treemacs-projectile)))
    (insert (format "  Cleanup function available: %s\n" 
                    (or (fboundp 'treemacs-projectile--cleanup-known-projects)
                        (fboundp 'treemacs-projectile-cleanup-known-projects)
                        "none")))
    (insert "\n")
    
    (insert "=== END DEBUG INFO ===\n")
    (goto-char (point-min))
    (display-buffer (current-buffer))))

(provide 'my-project-cleanup-config)

;;; my-project-cleanup-config.el ends here
