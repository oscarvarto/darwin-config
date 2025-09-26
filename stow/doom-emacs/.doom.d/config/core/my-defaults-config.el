;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; Load path utilities
(require 'my-paths)

(add-to-list 'load-path (expand-file-name "config/ui" my/config-el-dir))

;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
;; Updated by update-doom-config.sh on Wed Aug 20 15:15:54 CST 2025
(setq user-full-name "Oscar Vargas Torres"
      user-mail-address "contact@oscarvarto.mx")

(doom-load-envvars-file (my/get-path :env))
(setq read-extended-command-predicate #'command-completion-default-include-p)
(setq parinfer-rust-auto-download t)

(map! :map evil-normal-state-map
      ";" #'evil-ex)
(setq-default evil-kill-on-visual-paste nil) ; Prevent yanking killed text after pasting in visual mode
(setq org-odt-soffice-executable "soffice") ; Specify soffice executable for ODT export
;; (setq debug-on-error t) ; Uncomment for debugging init errors
(require 'sinister)

(sinister-stillness-mode)

(defun dired-jump-with-zoxide (&optional other-window)
  (interactive "P")
  (zoxide-open-with nil (lambda (file) (dired-jump other-window file)) t))
(map! :leader
      :after zoxide
      (:prefix ("f" . "+file")
       :desc "zoxide find file" "=" #'zoxide-open-with
       :desc "zoxide cd" "-" #'zoxide-cd))

;; (defun force-debug (func &rest args)
;;   (condition-case e
;;       (apply func args)
;;     ((debug error) (signal (car e) (cdr e)))))
;;
;; (advice-add #'corfu--post-command :around #'force-debug)

(use-package emacs
  :custom
  ;; TAB cycle if there are only few candidates
  (completion-cycle-threshold 3)

  ;; Enable indentation+completion using the TAB key.
  ;; `completion-at-point' is often bound to M-TAB.
  (tab-always-indent 'complete)

  ;; Emacs 30 and newer: Disable Ispell completion function. As an alternative,
  ;; try `cape-dict'.
  (text-mode-ispell-word-completion nil)

  ;; Hide commands in M-x which do not apply to the current mode.  Corfu
  ;; commands are hidden, since they are not used via M-x. This setting is
  ;; useful beyond Corfu.
  (read-extended-command-predicate #'command-completion-default-include-p))

;; Enable auto completion and configure quitting
;; (setq org-special-ctrl-a/e t)
(setq corfu-auto nil ; Disable auto completion popup
      corfu-auto-delay 0.5 ; Delay before auto popup (if enabled)
      corfu-quit-no-match 'separator) ; Quit Corfu if there are no matches, but show separator
;; corfu-preview-current nil ; If set, prevents previewing current candidate

(setq confirm-kill-emacs nil) ; Do not ask for confirmation when closing Emacs
(setq-default buffer-file-coding-system 'utf-8-unix) ; Default file encoding
(setq-default fill-column 80) ; Set wrap margin at 80 columns
;; (setq auto-fill-function 'jiggle-region) ; Specify how auto-fill breaks lines
;; (setq fci-rule-color "#3B4252") ; Color for fill-column-indicator

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
                vterm-mode-hook
                mu4e-headers-mode-hook
                mu4e-view-mode-hook
                mu4e-compose-mode-hook
                mu4e-main-mode-hook))
  (add-hook mode (lambda () (display-line-numbers-mode 0))))

(setq scroll-margin 5) ; Keep 5 lines visible above/below cursor when scrolling

(global-set-key (kbd "<home>") 'move-beginning-of-line)
(global-set-key (kbd "<end>") 'move-end-of-line)
(global-set-key (kbd "<f13>") (lambda ()
                                (interactive)
                                (setq kill-ring nil)
                                (garbage-collect)))

(+global-word-wrap-mode -1)
(add-to-list '+word-wrap-disabled-modes 'org-mode)

(menu-bar-mode t)
(tool-bar-mode -1) ; Disable the graphical toolbar
(winner-mode 1) ; Enable window configuration history (undo/redo window changes)

(require 'saveplace-pdf-view)
(save-place-mode 1)

(require 'vterm)

;; Use zsh as default shell
(setq shell-file-name (executable-find "zsh"))
;; Updated by update-doom-config.sh on Wed Aug 20 15:15:54 CST 2025
(setq-default vterm-shell (executable-find "nu"))
(setq-default explicit-shell-file-name (executable-find "zsh"))

;; Workaround for debugging Java tests
;; When debugging, temporarily use bash to ensure proper environment variable handling
(defun my/use-bash-for-debug-commands ()
  "Temporarily set shell to bash for debug operations."
  (setq-local shell-file-name "/bin/bash")
  (setq-local explicit-shell-file-name "/bin/bash"))

;; Hook for dap-mode to use bash for debugging
;; (with-eval-after-load 'dap-mode
;;   (add-hook 'dap-mode-hook #'my/use-bash-for-debug-commands)
;;
;;   ;; Enhanced Java debugging setup for Nushell compatibility
;;   (defun my/setup-java-debug-env ()
;;     "Set up environment variables and configuration for Java debugging when using Nushell."
;;     (when (string-match-p "nu$" shell-file-name)
;;       ;; Temporarily use bash for this operation
;;       (let ((original-shell shell-file-name)
;;             (original-explicit-shell explicit-shell-file-name))
;;         (setenv "SHELL" "/bin/bash")
;;         (setq shell-file-name "/bin/bash")
;;         (setq explicit-shell-file-name "/bin/bash")
;;
;;         ;; Set up proper environment variables
;;         (setenv "JAVA_TOOL_OPTIONS" "-Djava.awt.headless=true")
;;
;;         ;; Build Maven classpath using standard Maven
;;         (let * ((project-root (or (projectile-project-root) default-directory))
;;                (pom-path (expand-file-name "pom.xml" project-root)))
;;           (when (file-exists-p pom-path)
;;             (let ((classpath-cmd
;;                    (format "cd %s && mvn dependency:build-classpath -Dmdep.outputFile=/dev/stdout -q"
;;                            (shell-quote-argument project-root))))
;;               (let ((classpath-output (shell-command-to-string classpath-cmd)))
;;                 (when (and classpath-output
;;                           (not (string-empty-p (string-trim classpath-output)))
;;                           (not (string-match-p "ERROR\\|WARN" classpath-output)))
;;                   (setenv "JUNIT_CLASS_PATH" (string-trim classpath-output))
;;                   (setenv "CLASSPATH" (string-trim classpath-output))
;;                   (message "Set JUNIT_CLASS_PATH and CLASSPATH for debugging: %s"
;;                            (substring (string-trim classpath-output) 0 (min 100 (length (string-trim classpath-output)))))))))))))
;;
;;         ;; Don't restore shell immediately - let the debug session use bash
;;         ;; (setq shell-file-name original-shell)
;;         ;; (setq explicit-shell-file-name original-explicit-shell)
;;
;;   ;; Override DAP Java configuration to ensure proper shell usage
;;   (defun my/dap-java-debug-test-method-advice (orig-fun &rest args)
;;     "Advice to ensure proper environment for Java test debugging."
;;     (let ((shell-file-name "/bin/bash")
;;           (explicit-shell-file-name "/bin/bash"))
;;       (my/setup-java-debug-env)
;;       (apply orig-fun args)))
;;
;;   (advice-add 'dap-java-debug-test-method :around #'my/dap-java-debug-test-method-advice)
;;   (advice-add 'dap-java-debug-test-class :around #'my/dap-java-debug-test-method-advice)
;;
;;   (add-hook 'dap-java-test-mode-hook #'my/setup-java-debug-env)
;;   (add-hook 'java-mode-hook (lambda ()
;;                               (when (and (bound-and-true-p dap-mode)
;;                                          (string-match-p "Test\\.java$" (buffer-file-name)))
;;                                 (my/setup-java-debug-env)))))  ;; Close with-eval-after-load block

(add-to-list 'auto-mode-alist '("\.json$" . json-mode)) ; Use json-mode for .json files
;; Mill build file association removed - Scala support disabled

;; which-key
(after! which-key
  (setq which-key-idle-delay 0.5) ; Delay before which-key popup appears
  (setq which-key-popup-type 'minibuffer)) ; Show which-key in minibuffer instead of popup

(require 'pinentry)

(setq epa-pinentry-mode 'loopback) ; Use loopback mode for GPG key passphrases
(pinentry-start) ; Start the pinentry server
(setq auth-sources '("~/.authinfo.gpg")) ; Specify auth info file, prefer gpg encrypted
(setq nsm-settings-file "~/.config/network-security.data") ; Network Security Manager settings file

;; Projectile settings
;;(setq projectile-indexing-method 'native) ; Use native indexing (requires external tools)
;; https://github.com/doomemacs/doomemacs/issues/733
;;(setq projectile-require-project-root nil)
(setq projectile-globally-ignored-directories
      (list (my/expand-home-path "")
            (my/expand-home-path "OneDrive/")
            (my/get-path :onedrive)))
(setq gc-cons-threshold (* 100 1024 1024)) ; Set garbage collection threshold higher (e.g., 100MB) for potentially smoother performance
(setq projectile-enable-caching nil) ; Disable projectile caching (can help if stale or slow)
(setq projectile-completion-system 'default) ; Explicitly use default completion for projectile

;; Popup rules (Doom specific) - control where certain buffers appear
(set-popup-rule! "^\*Ollama\*$" :actions '(display-buffer-in-side-window) :side 'right :width 0.4 :select t :quit nil) ; Ollama buffer on the right

(after! cider-mode
  (set-popup-rules!
    '(("^\*Ollama\*$"
       :actions (+popup-display-buffer-stacked-side-window-fn)
       :side right
       :slot 1
       :width 0.4
       :height 0.5
       :select t
       :quit nil
       :ttl nil)
      ("^\*cider-repl" ; Stack CIDER REPLs on the right
       :actions (+popup-display-buffer-stacked-side-window-fn)
       :side right
       :slot -1
       :width 0.4
       :height 0.5
       :select t
       :quit nil
       :ttl nil))))

(set-popup-rule!
  "^\*xwidget-webkit:.*(?:- Grip|\.html)\*$"
  :side 'right
  :width 0.5
  :select t
  :quit nil
  :ttl nil)

(set-popup-rule!
  "^\*tabnine-chat\*$"
  :side 'right
  :width 0.35
  :select t
  :quit nil
  :ttl nil)

(set-popup-rule! ; Show LSP documentation at the bottom
  "^\*lsp-bridge-doc\*$"
  :side 'bottom
  :height 0.20
  :select t
  :quit t
  :ttl nil)

(use-package envrc
  :hook (after-init . envrc-global-mode))
(with-eval-after-load 'envrc
  (define-key envrc-mode-map (kbd "C-c e") 'envrc-command-map))

(require 'mise)
(add-hook 'after-init-hook #'global-mise-mode)

(defun remove-dos-eol ()
  "Do not show ^M in files containing mixed UNIX and DOS line endings."
  (interactive)
  (setq buffer-display-table (make-display-table))
  (aset buffer-display-table ?\^M []))

(add-hook 'text-mode-hook 'remove-dos-eol)
(use-package rainbow-csv
  :hook ((csv-mode tsv-mode) . rainbow-csv-mode)) ; Enable rainbow highlighting for CSV/TSV
(setq image-use-external-converter t) ; Use ImageMagick 'convert' for image ops
;; (setq image-converter-program "/path/to/convert") ; Specify path if needed
(setq read-process-output-max (* 1024 1024)) ; Increase max output read from processes (e.g., 1MB for LSP)
(setq vertico-cycle t) ; Allow cycling through Vertico completion candidates

(setq +format-on-save-disabled-modes '(java-mode))

(add-hook
 'eglot-managed-mode-hook
 (lambda ()
   ;; we want eglot to setup callbacks from eldoc, but we don't want eldoc
   ;; running after every command. As a workaround, we disable it after we just
   ;; enabled it. Now calling `M-x eldoc` will put the help we want in the eldoc
   ;; buffer. Alternatively we could tell eglot to stay out of eldoc, and add
   ;; the hooks manually, but that seems fragile to updates in eglot.
   (eldoc-mode -1)))

(provide 'my-defaults-config)
