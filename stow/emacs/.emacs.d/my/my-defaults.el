;; -*- lexical-binding: t; no-byte-compile: t; -*-

(setq make-backup-files nil) ; stop creating ~ files
(use-package indent-bars
  :ensure t
  :demand t
  :custom
  (indent-bars-no-descend-lists 'skip) ; no extra bars in continued func arg lists
  (indent-bars-treesit-support t)
  (indent-bars-treesit-ignore-blank-lines-types '("module"))
  (setq
    indent-bars-pattern "."
    indent-bars-width-frac 0.5
    indent-bars-pad-frac 0.25
    indent-bars-color-by-depth nil
    indent-bars-highlight-current-depth '(:face default :blend 0.4))
  :hook (prog-mode . indent-bars-mode))

(use-package projectile
  :ensure t
  :demand t
  :config
  (projectile-mode +1)
  (define-key projectile-mode-map (kbd "s-p") 'projectile-command-map)
  ;; Projectile settings
  (setq projectile-require-project-root t)  ; Require actual project root markers
  (setq projectile-globally-ignored-directories
        (list (getenv "HOME")))
  ; Set garbage collection threshold higher (e.g., 100MB) for potentially smoother performance
  (setq gc-cons-threshold (* 100 1024 1024))
  ; Disable projectile caching (can help if stale or slow)
  (setq projectile-enable-caching nil)
  ; Explicitly use default completion for projectile
  (setq projectile-completion-system 'default))

;; Automatic tree-sitter grammar installation and mode activation
(use-package treesit-auto
  :ensure t
  :demand t
  :config
  (global-treesit-auto-mode))

;; Use built-in tree-sitter modes (Emacs 29+)
;; Remap existing modes to their tree-sitter equivalents
(setq major-mode-remap-alist
      '((python-mode . python-ts-mode)
        (c-mode . c-ts-mode)
        (c++-mode . c++-ts-mode)
        (c-or-c++-mode . c-or-c++-ts-mode)
        (javascript-mode . js-ts-mode)
        (js-mode . js-ts-mode)
        (js-json-mode . json-ts-mode)
        (typescript-mode . typescript-ts-mode)
        (java-mode . java-ts-mode)
        (rust-mode . rust-ts-mode)
        (css-mode . css-ts-mode)
        (bash-mode . bash-ts-mode)
        (sh-mode . bash-ts-mode)
        (kotlin-mode . kotlin-ts-mode)
        (csharp-mode . csharp-ts-mode)
        (nix-mode . nix-ts-mode)))

;; Auto-mode associations for json-ts-mode
(setq auto-mode-alist
      (append '(("\\.jsonc\\'" . json-ts-mode)
                ("\\.jsonl\\'" . json-ts-mode)
                ("\\.json5\\'" . json-ts-mode)
                ("\\.babelrc\\'" . json-ts-mode)
                ("\\.eslintrc\\'" . json-ts-mode)
                ("\\.prettierrc\\'" . json-ts-mode)
                ("\\.jshintrc\\'" . json-ts-mode)
                ("\\.swcrc\\'" . json-ts-mode)
                ("\\.hintrc\\'" . json-ts-mode)
                ("\\.babelrc\\.json\\'" . json-ts-mode)
                ("\\.eslintrc\\.json\\'" . json-ts-mode)
                ("\\.prettierrc\\.json\\'" . json-ts-mode)
                ("tsconfig\\.json\\'" . json-ts-mode)
                ("jsconfig\\.json\\'" . json-ts-mode))
              auto-mode-alist))

;; Auto-mode associations for additional languages
(setq auto-mode-alist
      (append '(;; Kotlin
                ("\\.kt\\'" . kotlin-ts-mode)
                ("\\.kts\\'" . kotlin-ts-mode)
                ;; C#
                ("\\.cs\\'" . csharp-ts-mode)
                ("\\.csx\\'" . csharp-ts-mode)
                ;; Nix
                ("\\.nix\\'" . nix-ts-mode)
                ;; Fish
                ("\\.fish\\'" . fish-mode)
                ;; Zsh (uses bash-ts-mode)
                ("\\.zsh\\'" . bash-ts-mode)
                ("\\.zshrc\\'" . bash-ts-mode)
                ("\\.zshenv\\'" . bash-ts-mode)
                ("\\.zprofile\\'" . bash-ts-mode))
              auto-mode-alist))

(setq-default buffer-file-coding-system 'utf-8-unix) ; Default file encoding

;; Enable line numbers only for specific modes
(global-display-line-numbers-mode 0)  ;; Turn off global line numbers

;; Define a hook to enable line numbers for desired modes

(defun enable-line-numbers-for-desired-modes ()
  "Enable line numbers for programming and text editing modes."
  (display-line-numbers-mode 1))

;; Add the hook to programming modes
(add-hook 'prog-mode-hook 'enable-line-numbers-for-desired-modes)

;; Add the hook to specific text modes
(add-hook 'org-mode-hook 'enable-line-numbers-for-desired-modes)
(add-hook 'markdown-mode-hook 'enable-line-numbers-for-desired-modes)
(add-hook 'text-mode-hook 'enable-line-numbers-for-desired-modes)
(add-hook 'conf-mode-hook 'enable-line-numbers-for-desired-modes)

;; Explicitly disable line numbers for specific modes where they're not wanted
(dolist (mode '(treemacs-mode-hook
                vterm-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(menu-bar-mode t)
(tool-bar-mode -1) ; Disable the graphical toolbar
(winner-mode 1) ; Enable window configuration history (undo/redo window changes)

;; Keep frame titles in sync with the current buffer and avoid fixed titles.
(defvar my/frame-title-format '("%b")
  "Default frame title format for dynamic buffer-based titles.")

(setq frame-title-format my/frame-title-format)
(setq icon-title-format frame-title-format)
(when (boundp 'window-title-format)
  (setq window-title-format frame-title-format))

(defun my/apply-dynamic-frame-title (&optional frame)
  "Ensure FRAME uses dynamic buffer-based titles."
  (let ((frame (or frame (selected-frame))))
    (modify-frame-parameters frame '((title . nil) (name . nil)))
    ;; Re-assert global formats in case something fixed them elsewhere.
    (setq frame-title-format my/frame-title-format)
    (setq icon-title-format frame-title-format)
    (when (boundp 'window-title-format)
      (setq window-title-format frame-title-format))))

(defun my/refresh-frame-title-on-display-change (frame)
  "Reapply dynamic titles when FRAME moves between monitors."
  (let* ((attrs (frame-monitor-attributes frame))
         (monitor (alist-get 'name attrs))
         (prev (frame-parameter frame 'my/last-monitor)))
    (unless (equal monitor prev)
      (set-frame-parameter frame 'my/last-monitor monitor)
      (my/apply-dynamic-frame-title frame))))

(my/apply-dynamic-frame-title (selected-frame))
(add-hook 'after-make-frame-functions #'my/apply-dynamic-frame-title)
(when (boundp 'window-size-change-functions)
  (add-hook 'window-size-change-functions #'my/refresh-frame-title-on-display-change))
(dolist (frame (frame-list))
  (my/refresh-frame-title-on-display-change frame))

(use-package doom-modeline
  :ensure t
  :demand t
  :init (doom-modeline-mode 1))

;; Magit configuration (dependencies are loaded in my-elpaca.el)
(use-package magit
  :ensure t
  :demand t
  :bind (("C-x g" . magit-status)
         ("C-x M-g" . magit-dispatch))
  :init
  (setq magit-display-buffer-function #'magit-display-buffer-same-window-except-diff-v1))

(use-package eglot-booster
	:ensure (:host github :repo "jdtsmith/eglot-booster" :depth 1)
	:after eglot
	:config (eglot-booster-mode))

(use-package eldoc-box
  :ensure t
  :demand t
  :preface
  (defun my/eldoc-ui--buffer-wants-popup-p ()
    "Return non-nil when the current buffer should use eldoc popups."
    (or (bound-and-true-p lsp-mode)
        (bound-and-true-p eglot-managed-mode)
        (bound-and-true-p cider-mode)))

  (defun my/eldoc-ui--apply (&optional frame)
    "Enable a GUI popup or a terminal-friendly eldoc fallback."
    (let ((gui (display-graphic-p (or frame (selected-frame)))))
      (if (and gui (my/eldoc-ui--buffer-wants-popup-p))
          (eldoc-box-mouse-mode 1)
        (when (bound-and-true-p eldoc-box-mouse-mode)
          (eldoc-box-mouse-mode -1))
        (unless gui
          (when (boundp 'eldoc-echo-area-use-multiline-p)
            (setq-local eldoc-echo-area-use-multiline-p t))))))

  (defun my/eldoc-ui--sync-window (window &rest _)
    "Sync eldoc UI for WINDOW's buffer based on frame type."
    (when (window-live-p window)
      (with-current-buffer (window-buffer window)
        (my/eldoc-ui--apply (window-frame window)))))
  :hook ((eglot-managed-mode . my/eldoc-ui--apply)
         (cider-mode . my/eldoc-ui--apply)
         (lsp-mode . my/eldoc-ui--apply))
  :init
  (when (boundp 'window-buffer-change-functions)
    (add-hook 'window-buffer-change-functions #'my/eldoc-ui--sync-window))
  :config
  (ignore-errors
    (set-face-attribute 'eldoc-box-body nil :family "PragmataPro Mono Liga")))

(use-package dape
  :ensure t
  :demand t
  :preface
  ;; By default dape shares the same keybinding prefix as `gud'
  ;; If you do not want to use any prefix, set it to nil.
  ;; (setq dape-key-prefix "\C-x\C-a")

  :hook
  ;; Save breakpoints on quit
  (kill-emacs . dape-breakpoint-save)
  ;; Load breakpoints on startup
  (after-init . dape-breakpoint-load)

  :custom
  ;; Turn on global bindings for setting breakpoints with mouse
  (dape-breakpoint-global-mode +1)

  ;; Info buffers to the right
  (dape-buffer-window-arrangement 'right)
  ;; Info buffers like gud (gdb-mi)
  ;; (dape-buffer-window-arrangement 'gud)
  ;; (dape-info-hide-mode-line nil)

  ;; Projectile users
  (dape-cwd-function #'projectile-project-root)

  :config
  ;; Pulse source line (performance hit)
  (add-hook 'dape-display-source-hook #'pulse-momentary-highlight-one-line)

  ;; Save buffers on startup, useful for interpreted languages
  (add-hook 'dape-start-hook (lambda () (save-some-buffers t t)))

  ;; Kill compile buffer on build success
  (add-hook 'dape-compile-hook #'kill-buffer))

;; For a more ergonomic Emacs and `dape' experience
(use-package repeat-help
  :ensure t
  :demand t
  :hook (repeat-mode . repeat-help-mode))

;; Left and right side windows occupy full frame height
(use-package emacs
  :custom
  (window-sides-vertical t))

(use-package mise
  :ensure t
  :demand t
  :hook (after-init . global-mise-mode))

(use-package direnv
  :ensure t
  :demand t
  :config
  (direnv-mode))

(use-package envrc
  :ensure t
  :demand t
  :config
  (envrc-global-mode))

(use-package markdown-mode
  :after elpaca
  :mode (("\\.md\\'" . markdown-mode)
         ("\\.markdown\\'" . markdown-mode))
  :custom
  (markdown-fontify-code-blocks-natively t)
  :config
  ;; Explicitly map code block languages to non-tree-sitter modes
  ;; Tree-sitter modes don't work with markdown's embedded fontification
  (setq markdown-code-lang-modes
        '(("elisp" . emacs-lisp-mode)
          ("emacs-lisp" . emacs-lisp-mode)
          ("java" . java-mode)
          ("kotlin" . kotlin-mode)
          ("python" . python-mode)
          ("py" . python-mode)
          ("typescript" . typescript-mode)
          ("ts" . typescript-mode)
          ("javascript" . javascript-mode)
          ("js" . javascript-mode)
          ("csharp" . csharp-mode)
          ("cs" . csharp-mode)
          ("clojure" . clojure-mode)
          ("clj" . clojure-mode)
          ("nix" . nix-mode)
          ("bash" . sh-mode)
          ("sh" . sh-mode)
          ("zsh" . sh-mode)
          ("fish" . fish-mode)
          ("nushell" . nushell-mode)
          ("nu" . nushell-mode)
          ("json" . js-mode)
          ("rust" . rust-mode)
          ("rs" . rust-mode)
          ("c" . c-mode)
          ("cpp" . c++-mode)
          ("c++" . c++-mode))))

(use-package markdown-xwidget
  :after markdown-mode
  :ensure (markdown-xwidget
           :host github
           :repo "cfclrk/markdown-xwidget"
           :files (:defaults "resources"))
  :bind (:map markdown-mode-command-map
              ("x" . markdown-xwidget-preview-mode)))

(provide 'my-defaults)
