;;; -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package! tabnine
  :init
  ;; Only enable tabnine in GUI mode

  (defun my/maybe-enable-tabnine-mode ()
    "Enable tabnine-mode only in GUI Emacs."
    (when (display-graphic-p)
      (tabnine-mode 1)))

  :hook ((prog-mode . my/maybe-enable-tabnine-mode)
         (kill-emacs . tabnine-kill-process))

  :config
  ;; Only start tabnine process in GUI mode
  (when (display-graphic-p)
    (add-to-list 'completion-at-point-functions #'tabnine-completion-at-point)
    (tabnine-start-process))

  :bind
  (:map tabnine-completion-map
        ("<tab>" . tabnine-accept-completion)
        ("TAB" . tabnine-accept-completion)
        ("M-f" . tabnine-accept-completion-by-word)
        ("M-<return>" . tabnine-accept-completion-by-line)
        ("C-g" . tabnine-clear-overlay)
        ("M-[" . tabnine-previous-completion)
        ("M-]" . tabnine-next-completion)))

(provide 'my-tabnine-gui-config)
