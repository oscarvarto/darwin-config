;;; my-vterm-config.el -*- lexical-binding: t; no-byte-compile: t; -*-
;; Configuration for vterm.

;;[INFO] Improve speed when using in terminal.
;;     Ref: https://www.reddit.com/r/emacs/comments/pjtm91/vterm_a_little_bit_slow/
(require 'vterm)

(after! vterm
  (setq! vterm-timer-delay 0.01))

(add-hook 'vterm-mode-hook
          (lambda ()
               (set (make-local-variable 'buffer-face-mode-face) '(:family "PragmataPro Liga"))
               (buffer-face-mode t)))

(setq vterm-module-cmake-args "-DCMAKE_BUILD_TYPE=Release -DUSE_SYSTEM_LIBVTERM=yes"
       vterm-enable-manipulate-selection-data-by-osc52 t
       vterm-term-environment-variable "eterm-color"
       vterm-always-compile-module t)

(add-hook 'term-mode-hook #'eterm-256color-mode)

(defun vterm--send-C-d ()
  "Send <C-d> to vterm."
  (interactive)
  (when vterm--term
    (vterm-send-key "d" nil nil 0)))

;; Map [kp-delete] to send <C-d>. Otherwise, the delete key does not work in
;; GUI.
(map! :after vterm
      :map vterm-mode-map
      [kp-delete] #'vterm--send-C-d)

;; Map [kp-delete] to send <C-d>. Otherwise, the delete key does not work in
;; terminal.
(map! :after vterm
      :map vterm-mode-map
      [deletechar] #'vterm--send-C-d)

(provide 'my-vterm-config)
