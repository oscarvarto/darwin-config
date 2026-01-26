;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; Simple fix: remove invalid projectile paths before treemacs loads
(defun my/simple-projectile-cleanup ()
  "Clean up invalid projectile projects before treemacs tries to use them."
  (when (and (boundp 'projectile-known-projects)
             projectile-known-projects)
    (let* ((valid-projects (cl-remove-if-not #'file-exists-p projectile-known-projects))
           (removed-count (- (length projectile-known-projects) (length valid-projects))))
      (when (> removed-count 0)
        (setq projectile-known-projects valid-projects)
        (message "Cleaned %d invalid projectile paths" removed-count)))))

;; Clean up before treemacs loads (only when treemacs actually loads)
(defun my/treemacs-setup-hook ()
  "Setup treemacs after it loads."
  (my/simple-projectile-cleanup))

(with-eval-after-load 'treemacs
  ;; Add setup hook for when treemacs actually loads
  (add-hook 'treemacs-mode-hook #'my/treemacs-setup-hook)
  (defun my/treemacs-custom-font ()
    "Apply PragmataPro font to treemacs buffer."
    (setq-local buffer-face-mode-face
                '(:family "PragmataPro" :height 0.6))
    (buffer-face-mode 1))

  (add-hook 'treemacs-mode-hook #'my/treemacs-custom-font)

  (setq treemacs-collapse-dirs 1)
  (define-key treemacs-mode-map (kbd "C-c C-j") #'treemacs-root-up)
  (define-key treemacs-mode-map (kbd "C-c C-k") #'treemacs-root-down)
  ;; (setq treemacs--icon-size 18)
  ;; Update icons to the new size
  ;; (treemacs-resize-icons treemacs--icon-size)
  (treemacs-follow-mode 1)

  (defun my/treemacs-toggle-multiple-roots ()
    "Toggle between single and multiple project root display."
    (interactive)
    (if (> (length (treemacs-workspace->projects (treemacs-current-workspace))) 1)
        ;; If multiple projects, clear and add current
        (progn
          (treemacs-remove-project-from-workspace)
          (treemacs-add-project-to-workspace (projectile-project-root)))
      ;; If single project, add common projects
      (my/treemacs-add-multiple-projects)))

  ;; Keybinding for toggling multiple roots (C-c t x)
  (define-key treemacs-mode-map (kbd "C-c t x") #'my/treemacs-toggle-multiple-roots))

(provide 'my-treemacs)
