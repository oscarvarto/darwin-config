;;; -- lexical-binding: t; no-byte-compile: t; --
(use-package! tabnine
  :commands (tabnine-start-process)
  :diminish "⌬"
  :custom
  (tabnine-wait 1)
  (tabnine-minimum-prefix-length 0)
  :init
  :hook ((prog-mode . tabnine-mode)
         (kill-emacs . tabnine-kill-process))
  :config
  (add-to-list 'completion-at-point-functions #'tabnine-completion-at-point)
  (tabnine-start-process)
  :bind
  (:map tabnine-completion-map
     ("<tab>" . tabnine-accept-completion)
     ("TAB" . tabnine-accept-completion)
     ("M-f" . tabnine-accept-completion-by-word)
     ("M-<return>" . tabnine-accept-completion-by-line)
     ("C-g" . tabnine-clear-overlay)
     ("M-[" . tabnine-previous-completion)
     ("M-]" . tabnine-next-completion)))

(provide 'my-tabnine-config)
