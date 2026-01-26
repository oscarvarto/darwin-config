;; -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package evil
  :ensure (:host github
           :repo "emacs-evil/evil"
           :depth 1)
  :init
  (setq evil-undo-system 'undo-fu)
  (setq evil-want-integration t) ;; This is optional since it's already set to t by default.
  (setq evil-want-keybinding nil)
  :config
  (evil-mode 1))

(use-package evil-collection
  :after evil
  :ensure (:host github
           :repo "emacs-evil/evil-collection"
           :depth 1)
  :config
  ;; Configure Magit integration before enabling evil-collection
  (setq evil-collection-magit-state 'normal
        evil-collection-magit-use-y-for-yank nil)
  (evil-collection-init))

;; which-key for showing keybinding hints
(use-package which-key
  :ensure t
  :demand t
  :config
  (setq which-key-allow-evil-operators t
        which-key-show-operator-state-maps t)
  (which-key-mode))

;; general.el for leader key configuration
(use-package general
  :ensure t
  :demand t
  :config
  ;; Set up Space as the leader key
  (general-create-definer my/leader-keys
    :states '(normal insert visual emacs)
    :keymaps 'override
    :prefix "SPC"
    :global-prefix "C-SPC")

  ;; Basic leader key bindings
  (my/leader-keys
    "SPC" '(execute-extended-command :which-key "M-x")

    ;; File operations
    "f" '(:ignore t :which-key "files")
    "ff" '(find-file :which-key "find file")
    "fs" '(save-buffer :which-key "save file")
    "fS" '(write-file :which-key "save as")
    "fr" '(recentf-open-files :which-key "recent files")

    ;; Buffer operations
    "b" '(:ignore t :which-key "buffers")
    "bb" '(switch-to-buffer :which-key "switch buffer")
    "bk" '(kill-buffer :which-key "kill buffer")
    "bn" '(next-buffer :which-key "next buffer")
    "bp" '(previous-buffer :which-key "previous buffer")
    "bi" '(ibuffer :which-key "ibuffer")

    ;; Window operations
    "w" '(:ignore t :which-key "windows")
    "ww" '(other-window :which-key "other window")
    "wd" '(delete-window :which-key "delete window")
    "wD" '(delete-other-windows :which-key "delete other windows")
    "ws" '(split-window-below :which-key "split below")
    "wv" '(split-window-right :which-key "split right")
    "w=" '(balance-windows :which-key "balance windows")

    ;; Help
    "h" '(:ignore t :which-key "help")
    "hf" '(describe-function :which-key "describe function")
    "hv" '(describe-variable :which-key "describe variable")
    "hk" '(describe-key :which-key "describe key")
    "hm" '(describe-mode :which-key "describe mode")

    ;; Quit/Session
    "q" '(:ignore t :which-key "quit")
    "qq" '(save-buffers-kill-terminal :which-key "quit emacs")
    "qQ" '(kill-emacs :which-key "kill emacs (no save)")
    "qr" '(restart-emacs :which-key "restart emacs")))

(provide 'my-keys)
