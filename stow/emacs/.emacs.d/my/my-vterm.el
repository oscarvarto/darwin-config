;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; vterm - install via Elpaca and compile native module
(use-package vterm
  :ensure t
  :config
  (use-package eterm-256color
    :ensure t
    :demand t
    :config
    (setq vterm-term-environment-variable "eterm-color")
    (add-hook 'term-mode-hook #'eterm-256color-mode))
  (setq-default vterm-shell (executable-find "zsh"))
  (setq-default explicit-shell-file-name (executable-find "zsh"))
  (setq vterm-timer-delay 0.01)
  (setq vterm-enable-manipulate-selection-data-by-osc52 t)
  (defun vterm--send-C-d ()
    "Send <C-d> to vterm."
    (interactive)
    (when vterm--term
      (vterm-send-key "d" nil nil 0)))
  ;; Map [kp-delete] to send <C-d>. Otherwise, the delete key does not work in
  ;; GUI.
  (define-key vterm-mode-map [kp-delete] #'vterm--send-C-d)
  :hook (vterm-mode .
            (lambda ()
                 (set (make-local-variable 'buffer-face-mode-face) '(:family "PragmataPro Liga"))
                 (buffer-face-mode t))))

(provide 'my-vterm)
