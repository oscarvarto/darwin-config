;;; my-rust-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'lsp-clangd)

(setq lsp-clients-clangd-args
      '("-j=8"
        "--background-index"
        "--clang-tidy"
        "--completion-style=detailed"
        "--header-insertion=never"
        "--header-insertion-decorators=0"))
(set-lsp-priority! 'clangd 2)

(custom-set-faces
 '(rustic-compilation-column ((t (:inherit compilation-column-number))))
 '(rustic-compilation-line ((t (:foreground "fuchsia")))))

(defun rustic-mode-auto-save-hook ()
  "Enable auto-saving in rustic-mode buffers."
  (when buffer-file-name
    (setq-local compilation-ask-about-save nil)))
(add-hook 'rustic-mode-hook 'rustic-mode-auto-save-hook)

(setq rustic-rustfmt-args "+nightly")
(setq rustic-rustfmt-config-alist '((hard_tabs . t) (skip_children . nil)))

(use-package rust-mode
  :init
  (setq rust-mode-treesitter-derive t))

(use-package rustic
  :after lsp-mode
  :config
  (setq rustic-format-on-save nil)
  ;; Configure file watching for rustic projects
  (setq lsp-file-watch-threshold 50000)
  (setq lsp-enable-file-watchers t)  ; Keep watchers but with high threshold
  :custom
  (rustic-cargo-use-last-stored-arguments t)
  
  ;; Safe toolchain detection that works in daemon mode
  (defun my/get-rust-toolchain ()
    "Get rust toolchain safely, handling daemon mode issues."
    (condition-case err
        (let* ((default-directory (expand-file-name "~/"))  ; Ensure we have a valid directory
               (process-environment (append '("PATH=/usr/local/bin:/opt/homebrew/bin:$PATH") process-environment))
               (toolchain-output (shell-command-to-string "rustup default 2>/dev/null | cut -d'-' -f1")))
          (if (and toolchain-output (not (string-empty-p (string-trim toolchain-output))))
              (string-trim toolchain-output)
            (or (getenv "RUST_TOOLCHAIN") "nightly")))
      (error
       (message "Warning: Could not detect rust toolchain, using fallback: %s" err)
       (or (getenv "RUST_TOOLCHAIN") "nightly"))))
  
  ;; Set rust-analyzer command with safe toolchain detection
  (let ((toolchain (my/get-rust-toolchain)))
    (setq rustic-analyzer-command `("rustup" "run" ,toolchain "rust-analyzer")))
  
  ;; (setq rustic-analyzer-command `("rustup" "run" "nightly" "rust-analyzer"))
  (lsp-rust-analyzer-cargo-watch-command "clippy")
  ;; These are optional configurations. See https://emacs-lsp.github.io/lsp-mode/page/lsp-rust-analyzer/#lsp-rust-analyzer-display-chaining-hints for a full list
  (lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (lsp-rust-analyzer-display-chaining-hints t)
  (lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (lsp-rust-analyzer-display-closure-return-type-hints t)
  (lsp-rust-analyzer-display-parameter-hints nil))

(with-eval-after-load 'rustic-mode
  (add-hook! 'rustic-mode-hook #'lsp-ui-mode #'flymake-mode)
  (add-hook 'flycheck-mode-hook #'flycheck-rust-setup)
  
  ;; Hook to configure file watching when entering rustic projects
  (add-hook 'rustic-mode-hook
            (lambda ()
              (setq-local lsp-file-watch-threshold 50000)
              (setq-local lsp-enable-file-watchers t))))
