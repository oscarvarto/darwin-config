;;; my-clojure.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Clojure development with cider and lsp-mode

(require 'project)
(require 'subr-x)
(require 'use-package)

;; === Modes

(defun my/clojure--ui-setup ()
  "Tune UI helpers for Clojure buffers."
  ;; Avoid competing childframes: Corfu popupinfo uses a childframe too.
  ;; Keep it available via manual `corfu-popupinfo-*` commands, but disable
  ;; the automatic popup in Clojure buffers.
  (when (boundp 'corfu-popupinfo-delay)
    (setq-local corfu-popupinfo-delay nil)))

(defun my/clojure--maybe-require-ts-mode ()
  "Ensure clojure-ts-mode is loaded if available, returning non-nil on success."
  (require 'clojure-ts-mode nil 'noerror))

(defun my/clojure-auto-mode ()
  "Select clojure-ts-mode when available, otherwise clojure-mode."
  (interactive)
  (if (my/clojure--maybe-require-ts-mode)
      (clojure-ts-mode)
    (clojure-mode)))

(defun my/clojurec-auto-mode ()
  "Select clojure-ts-clojurec-mode when available, otherwise clojurec-mode."
  (interactive)
  (if (my/clojure--maybe-require-ts-mode)
      (clojure-ts-clojurec-mode)
    (clojurec-mode)))

(defun my/clojurescript-auto-mode ()
  "Select clojure-ts-clojurescript-mode when available, otherwise clojurescript-mode."
  (interactive)
  (if (my/clojure--maybe-require-ts-mode)
      (clojure-ts-clojurescript-mode)
    (clojurescript-mode)))

(setq auto-mode-alist
      (append '(("\\.clj\\'" . my/clojure-auto-mode)
                ("\\.cljc\\'" . my/clojurec-auto-mode)
                ("\\.cljs\\'" . my/clojurescript-auto-mode)
                ("\\.edn\\'" . my/clojure-auto-mode)
                ("deps\\.edn\\'" . my/clojure-auto-mode))
              auto-mode-alist))

(use-package clojure-mode
  :ensure t
  :commands (clojure-mode clojurec-mode clojurescript-mode)
  :init
  (setq clojure-align-forms-automatically t
        clojure-indent-style 'always-align)
  :hook ((clojure-mode . my/clojure--ui-setup)
         (clojure-ts-mode . my/clojure--ui-setup)
         (clojure-ts-clojurec-mode . my/clojure--ui-setup)
         (clojure-ts-clojurescript-mode . my/clojure--ui-setup)
         (clojurec-mode . my/clojure--ui-setup)
         (clojurescript-mode . my/clojure--ui-setup)
         (clojure-mode . lsp-deferred)
         (clojure-ts-mode . lsp-deferred)
         (clojure-ts-clojurec-mode . lsp-deferred)
         (clojure-ts-clojurescript-mode . lsp-deferred)
         (clojurec-mode . lsp-deferred)
         (clojurescript-mode . lsp-deferred)))

(use-package parseedn
  :ensure t
  :defer t)

;; === CIDER

(defun my/clojure--project-root ()
  "Return the project root for the current buffer, or nil."
  (or (when-let* ((project (project-current nil)))
        (car (project-roots project)))
      (when (and (require 'projectile nil 'noerror)
                 (projectile-project-p))
        (projectile-project-root))))

(defun my/clojure--deps-ns-default (deps-file)
  "Return the :ns-default configured in DEPS-FILE (:aliases :run-x), or nil."
  (when (and deps-file (file-exists-p deps-file))
    (when (require 'parseedn nil 'noerror)
      (with-temp-buffer
        (insert-file-contents deps-file)
        (goto-char (point-min))
        (let* ((deps-data (parseedn-read-str (buffer-string)))
               (aliases (and deps-data (gethash :aliases deps-data)))
               (run-x (and aliases (gethash :run-x aliases))))
          (and run-x (gethash :ns-default run-x)))))))

(defun my/clojure--cider-repl-init-code ()
  "Return per-project init code for CIDER.
The generated code is defensive and won't error if optional deps are missing."
  (let* ((root (or (bound-and-true-p nrepl-project-dir)
                   (my/clojure--project-root)
                   default-directory))
         (deps-file (and root (expand-file-name "deps.edn" root)))
         (ns (my/clojure--deps-ns-default deps-file)))
    (string-join
     (delq nil
           (list
            "(try (require 'clj-reload.core) (catch Throwable _ nil))"
            (string-join
             '("(when (find-ns 'clj-reload.core)"
               "  (alias 'reload 'clj-reload.core)"
               "  (when-let [init (resolve 'reload/init)]"
               "    (init {:dirs [\"src\" \"dev\" \"test\"]})))")
             "\n")
            (when ns
              (format (string-join
                       '("(try (require '%s) (catch Throwable _ nil))"
                         "(when (find-ns '%s) (alias 'mm '%s))")
                       "\n")
                      ns ns ns))))
     "\n")))

(defun my/cider-repl--set-init-code ()
  "Set `cider-repl-init-code' buffer-locally for the current REPL."
  (when (boundp 'cider-repl-init-code)
    (setq-local cider-repl-init-code
                (append (copy-sequence (default-value 'cider-repl-init-code))
                        (list (my/clojure--cider-repl-init-code))))))

(defun my/clojure--cider-repl-setup ()
  "Enable yasnippet and define a couple of CIDER REPL snippets."
  (my/cider-repl--set-init-code)
  (when (require 'yasnippet nil 'noerror)
    (yas-minor-mode-on)
    (yas-define-snippets 'cider-repl-mode
                         '(("doc" "(clojure.repl/doc $0)" nil nil nil nil nil)
                           ("r" "(when-let [reload-fn (resolve 'reload/reload)] (reload-fn))$0"
                            nil nil nil nil nil)))))

(use-package cider
  :ensure t
  :after clojure-mode
  :hook ((clojure-mode . cider-mode)
         (clojure-ts-mode . cider-mode)
         (clojure-ts-clojurec-mode . cider-mode)
         (clojure-ts-clojurescript-mode . cider-mode)
         (clojurec-mode . cider-mode)
         (clojurescript-mode . cider-mode)
         (cider-repl-mode . my/clojure--cider-repl-setup))
  :init
  (setq cider-overlays-use-font-lock t)
  (setq cider-repl-use-content-types t)
  (setq cider-show-error-buffer t)
  (setq cider-font-lock-dynamically '(macro core function var))
  (setq cider-prompt-for-symbol nil)
  (setq cider-repl-display-help-banner nil)
  (setq cider-print-fn 'puget)
  (setq cider-preferred-build-tool 'clojure-cli)
  (setq cider-default-cljs-repl 'shadow)
  (setq cider-enable-nrepl-jvmti-agent t)
  (setq cider-ns-code-reload-tool 'clj-reload)
  :config
  (cider-add-to-alist 'cider-jack-in-dependencies "mvxcvi/puget" "1.3.4")
  ;; Puget depends on fipp; pin a newer fipp explicitly to override transitive.
  (cider-add-to-alist 'cider-jack-in-dependencies "fipp/fipp" "0.6.29")
  (cider-add-to-alist 'cider-jack-in-dependencies "io.github.tonsky/clj-reload" "1.0.0"))

;; === LSP
(with-eval-after-load 'lsp-mode
  ;; Configure clojure-lsp
  (setq lsp-clojure-custom-server-command '("bash" "-c" "clojure-lsp"))
  (setq lsp-completion-enable t)

  ;; Optionally enable semantic tokens for better syntax highlighting
  (setq lsp-semantic-tokens-enable t))

(provide 'my-clojure)
