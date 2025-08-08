;;; my-clojure-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

(defvar my/clojure-features-initialized nil
  "Track which Clojure features have been initialized.")

;;;###autoload

(defun my/clojure-setup-basic ()
  "Setup basic Clojure environment without loading heavy dependencies."
  (setq clojure-align-forms-automatically t
        clojure-indent-style 'always-align)
  
  ;; Basic modes that should be enabled immediately
  (smartparens-strict-mode 1)
  (rainbow-delimiters-mode 1)
  (subword-mode 1))

;;;###autoload

(defun my/clojure-setup-cider ()
  "Setup CIDER with lazy loading of features."
  (interactive)
  (unless (plist-get my/clojure-features-initialized :cider)
    (require 'cider)
    
    (with-eval-after-load 'cider
      (setq cider-show-error-buffer t
            cider-font-lock-dynamically '(macro core function var)
            cider-repl-use-content-types t
            cider-prompt-for-symbol nil
            cider-repl-display-help-banner nil
            cider-print-fn 'fipp
            cider-preferred-build-tool 'clojure-cli
            cider-default-cljs-repl 'shadow)
      
      ;; CIDER hooks
      (add-hook 'cider-repl-mode-hook #'smartparens-strict-mode)
      (add-hook 'cider-repl-mode-hook #'rainbow-delimiters-mode)
      (add-hook 'cider-repl-mode-hook #'subword-mode)
      (add-hook 'cider-repl-mode-hook #'company-mode)
      
      ;; Only setup refactoring when needed
      (with-eval-after-load 'clj-refactor
        (setq cljr-warn-on-eval nil
              cljr-magic-require-namespaces
              '(("s"   . "clojure.string")
                ("set" . "clojure.set")
                ("d"   . "clojure.data")
                ("w"   . "clojure.walk")))))
    
    (setq my/clojure-features-initialized 
          (plist-put my/clojure-features-initialized :cider t))))

;;;###autoload

(defun my/clojure-setup-lsp ()
  "Setup LSP for Clojure development."
  (interactive)
  (unless (plist-get my/clojure-features-initialized :lsp)
    (require 'lsp-mode)

    (require 'lsp-clojure)

    (setq lsp-clojure-custom-server-command '("bash" "-c" "clojure-lsp")
          lsp-completion-enable t)
    (setq my/clojure-features-initialized 
          (plist-put my/clojure-features-initialized :lsp t))))

;;;###autoload

(defun my/clojure-setup-refactor ()
  "Setup clj-refactor for Clojure development."
  (interactive)
  (unless (plist-get my/clojure-features-initialized :refactor)
    (require 'clj-refactor)

    (clj-refactor-mode 1)
    (yas-minor-mode 1)
    (setq my/clojure-features-initialized
          (plist-put my/clojure-features-initialized :refactor t))))

;;;###autoload

(defun load-rebl-on-shadow-cljs-node-repl ()
  "Load REBL with Shadow-CLJS."
  (interactive)
  (my/clojure-setup-cider)
  (cider-interactive-eval
   "(require '[cognitect.rebl :as rebl])
(require '[shadow.cljs.devtools.api :as shadow])

(shadow/nrepl-select :app)
(cider.piggieback/cljs-repl (shadow.cljs.devtools.api/repl :app))"))

;; Mode hooks with lazy loading
(add-hook 'clojure-mode-hook #'my/clojure-setup-basic)

;; Command to setup full environment
;;;###autoload

(defun my/clojure-setup-full-env ()
  "Setup complete Clojure development environment."
  (interactive)
  (my/clojure-setup-basic)
  (my/clojure-setup-cider)
  (my/clojure-setup-lsp)
  (my/clojure-setup-refactor)
  (message "Clojure environment fully configured"))

;; Key bindings
(map! :after clojure-mode
      :map clojure-mode-map
      :localleader
      (:prefix ("j" . "clojure")
       :desc "Setup CIDER" "c" #'my/clojure-setup-cider
       :desc "Setup LSP" "l" #'my/clojure-setup-lsp
       :desc "Setup refactor" "r" #'my/clojure-setup-refactor
       :desc "Setup full env" "f" #'my/clojure-setup-full-env
       :desc "Load REBL" "b" #'load-rebl-on-shadow-cljs-node-repl))

(provide 'my-clojure-config)

;;; my-clojure-config.el ends here
