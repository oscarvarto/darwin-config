;; -*- lexical-binding: t; no-byte-compile: t; -*-

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(custom-safe-themes
   '("7235b77f371f46cbfae9271dce65f5017b61ec1c8687a90ff30c6db281bfd6b7"
     "5e39e95c703e17a743fb05a132d727aa1d69d9d2c9cde9353f5350e545c793d4" default))
 '(safe-local-variable-values
   '((no-byte-compiling . t) (lsp-rust-analyzer-proc-macro-enable . t) (+format-with isort black)
     (org-todo-keywords (sequence "TODO" "TESTING" "|" "DONE")) (org-enforce-todo-dependencies . t)
     (org-confirm-babel-evaluate) (byte-no-compile . t))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(rustic-compilation-column ((t (:inherit compilation-column-number))))
 '(rustic-compilation-line ((t (:foreground "fuchsia"))))
 '(treemacs-directory-collapsed-face ((t (:height 0.8))))
 '(treemacs-directory-face ((t (:height 0.8))))
 '(treemacs-file-face ((t (:height 0.8))))
 '(treemacs-git-added-face ((t (:height 0.8))))
 '(treemacs-git-conflict-face ((t (:height 0.8))))
 '(treemacs-git-ignored-face ((t (:height 0.8))))
 '(treemacs-git-modified-face ((t (:height 0.8))))
 '(treemacs-git-renamed-face ((t (:height 0.8))))
 '(treemacs-git-unmodified-face ((t (:height 0.8))))
 '(treemacs-git-untracked-face ((t (:height 0.8))))
 '(treemacs-icon-face ((t (:height 0.8 :weight light))))
 '(treemacs-root-face ((t (:height 0.8))))
 '(treemacs-tags-face ((t (:height 0.8)))))
