;;; my-obsidian-config -*- lexical-binding: t; no-byte-compiling: t; -*-

(use-package obsidian
  :custom
  ;; location of obsidian vault
  (obsidian-directory "~/obsidian")
  ;; Default location for new notes from `obsidian-capture'
  (obsidian-inbox-directory "Inbox")
  ;; Useful if you're going to be using wiki links
  (markdown-enable-wiki-links t)
  :config
  (global-obsidian-mode t)
  ;;(obsidian-backlinks-mode t)
  
  ;; These bindings are only suggestions; it's okay to use other bindings
  ;; Key bindings for obsidian-mode-map
  (define-key obsidian-mode-map (kbd "C-c C-n") 'obsidian-capture)
  (define-key obsidian-mode-map (kbd "C-c C-l") 'obsidian-insert-link)
  (define-key obsidian-mode-map (kbd "C-c C-o") 'obsidian-follow-link-at-point)
  (define-key obsidian-mode-map (kbd "C-c C-p") 'obsidian-jump)
  (define-key obsidian-mode-map (kbd "C-c C-b") 'obsidian-backlink-jump)
  (define-key obsidian-mode-map (kbd "C-c M-o") 'obsidian-hydra/body))

(provide 'my-obsidian-config)
