;;; my-rust-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; IMPORTANT: This config ONLY sets up rust-analyzer command detection.
;; All mode setup is handled by Doom's rust module with +lsp +tree-sitter flags.

(require 'cl-lib)
(require 'subr-x)  ;; string-trim, string-empty-p

;; Configure clangd (separate from rust, but kept in this file for convenience)
(after! lsp-clangd
  (setq lsp-clients-clangd-args
        '("-j=8"
          "--background-index"
          "--clang-tidy"
          "--completion-style=detailed"
          "--header-insertion=never"
          "--header-insertion-decorators=0"))
  (set-lsp-priority! 'clangd 2))

;; Rustic customization (these don't affect mode setup)
(custom-set-faces
 '(rustic-compilation-column ((t (:inherit compilation-column-number))))
 '(rustic-compilation-line ((t (:foreground "fuchsia")))))

(setq rust-mode-treesitter-derive t)
(setq rustic-rustfmt-args "+nightly")
(setq rustic-rustfmt-config-alist '((hard_tabs . t) (skip_children . nil)))

(defun my/direnv-project-root ()
  "Return the nearest directory containing a .envrc file, or nil."
  (when-let ((root (locate-dominating-file default-directory ".envrc")))
    (expand-file-name root)))

(defun my/find-executable-in-env (program &optional prefer)
  "Return absolute path to PROGRAM found via PATH in `process-environment'.
When PREFER is non-nil, it should be a predicate receiving a candidate path
and returning non-nil for the preferred match."
  (let* ((path (getenv "PATH"))
         (dirs (and path (split-string path path-separator t)))
         (candidates '()))
    (dolist (dir dirs)
      (let ((candidate (and dir (expand-file-name program dir))))
        (when (and candidate (file-executable-p candidate))
          (push candidate candidates))))
    (setq candidates (nreverse candidates))
    (cond
     ((and prefer candidates)
      (or (cl-find-if prefer candidates)
          (car candidates)))
     (candidates
      (car candidates))
     (t nil))))

;; Detect if we're in a Nix environment
(defun my/in-nix-environment-p ()
  "Check if we're running in a Nix environment."
  (or (getenv "IN_NIX_SHELL")
      (getenv "NIX_PATH")
      ;; Check if rustc is from nix store
      (let ((rustc-path (my/find-executable-in-env
                         "rustc"
                         (lambda (path)
                           (string-match-p "/nix/store/" path)))))
        (and rustc-path (string-match-p "/nix/store/" rustc-path)))))

;; Safe toolchain detection that works in daemon mode and supports Nix
(defun my/get-rust-toolchain ()
  "Get rust toolchain safely, handling both Nix and rustup environments."
  (condition-case err
      (let* ((default-directory (expand-file-name "~/"))
             (process-environment (append '("PATH=/usr/local/bin:/opt/homebrew/bin:$PATH") process-environment))
             (toolchain-output (shell-command-to-string "rustup default 2>/dev/null | cut -d'-' -f1")))
        (if (and toolchain-output (not (string-empty-p (string-trim toolchain-output))))
            (string-trim toolchain-output)
          (or (getenv "RUST_TOOLCHAIN") "nightly")))
    (error
     (message "Warning: Could not detect rust toolchain, using fallback: %s" err)
     (or (getenv "RUST_TOOLCHAIN") "nightly"))))

;; Set rust-analyzer command based on environment
(defun my/setup-rust-analyzer ()
  "Configure rust-analyzer command based on the active environment.
Sets the command globally, as LSP initialization reads the global value."
  (let* ((ra-path (my/find-executable-in-env
                   "rust-analyzer"
                   (lambda (path)
                     (string-match-p "/nix/store/" path))))
         (nix-env (my/in-nix-environment-p))
         (envrc-root (my/direnv-project-root))
         (direnv-available (and envrc-root (executable-find "direnv")))
         command)
    (cond
     (direnv-available
      (let ((exec-root (directory-file-name envrc-root)))
        (setq command `("direnv" "exec" ,exec-root "rust-analyzer"))
        (message "Using direnv exec for rust-analyzer (env: %s)" exec-root)))
     (ra-path
      (setq command (list ra-path))
      (message "Using rust-analyzer from %s%s"
               ra-path
               (if (and nix-env (string-match-p "/nix/store/" ra-path))
                   " (Nix)"
                 "")))
     (t
      (let ((toolchain (my/get-rust-toolchain)))
        (setq command `("rustup" "run" ,toolchain "rust-analyzer"))
        (message "rust-analyzer not found in PATH; falling back to rustup toolchain %s" toolchain))))
    (when command
      (setq rustic-analyzer-command command
            lsp-rust-analyzer-server-command command))))

(my/setup-rust-analyzer)

;; Interactive command to verify Rust environment
(defun my/rust-show-environment ()
  "Display information about the current Rust environment."
  (interactive)
  (let* ((in-nix (my/in-nix-environment-p))
         (envrc-root (my/direnv-project-root))
         (direnv-available (and envrc-root (executable-find "direnv")))
         (rustc-path (my/find-executable-in-env
                      "rustc"
                      (lambda (path)
                        (string-match-p "/nix/store/" path))))
         (ra-path (my/find-executable-in-env
                   "rust-analyzer"
                   (lambda (path)
                     (string-match-p "/nix/store/" path))))
         (rustc-version (when rustc-path
                          (string-trim (shell-command-to-string "rustc --version"))))
         (ra-version (when ra-path
                      (string-trim (shell-command-to-string "rust-analyzer --version"))))
         (analyzer-cmd (bound-and-true-p rustic-analyzer-command)))
    (with-current-buffer (get-buffer-create "*Rust Environment*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "=== Rust Environment Information ===\n\n"))
        (insert (format "Nix environment detected: %s\n\n" (if in-nix "YES" "NO")))
        (insert (format ".envrc root: %s\n" (or envrc-root "NOT FOUND")))
        (insert (format "direnv exec available: %s\n\n" (if direnv-available "YES" "NO")))
        (insert (format "rustc path: %s\n" (or rustc-path "NOT FOUND")))
        (insert (format "rustc version: %s\n\n" (or rustc-version "N/A")))
        (insert (format "rust-analyzer path: %s\n" (or ra-path "NOT FOUND")))
        (insert (format "rust-analyzer version: %s\n\n" (or ra-version "N/A")))
        (insert (format "LSP rust-analyzer command: %S\n\n" analyzer-cmd))
        (insert (format "Environment variables:\n"))
        (insert (format "  IN_NIX_SHELL: %s\n" (or (getenv "IN_NIX_SHELL") "not set")))
        (insert (format "  NIX_PATH: %s\n" (or (getenv "NIX_PATH") "not set")))
        (insert (format "  PATH: %s\n" (getenv "PATH"))))
      (special-mode)
      (display-buffer (current-buffer)))))

;; Configure rustic ONLY after it's fully loaded
(after! rustic
  (setq rustic-format-on-save nil)
  (setq rustic-cargo-use-last-stored-arguments t)

  ;; Configure file watching for rustic projects
  (setq lsp-file-watch-threshold 50000)
  (setq lsp-enable-file-watchers t)

  ;; Auto-save hook
  (defun rustic-mode-auto-save-hook ()
    "Enable auto-saving in rustic-mode buffers."
    (when buffer-file-name
      (setq-local compilation-ask-about-save nil)))

  (add-hook 'rustic-mode-hook 'rustic-mode-auto-save-hook)

  ;; Setup rust-analyzer by advising rustic-lsp-mode-setup
  ;; This ensures we set rustic-analyzer-command RIGHT before it's copied to lsp-rust-analyzer-server-command
  (defun my/rustic-setup-analyzer-advice (&rest _)
    "Advice to set rustic-analyzer-command before LSP setup."
    (my/setup-rust-analyzer))

  (advice-add 'rustic-lsp-mode-setup :before #'my/rustic-setup-analyzer-advice)

  ;; File watching configuration per-buffer
  (add-hook 'rustic-mode-hook
            (lambda ()
              (setq-local lsp-file-watch-threshold 50000)
              (setq-local lsp-enable-file-watchers t))))

;; LSP rust-analyzer configuration (set globally, not per-mode)
(after! lsp-rust
  (setq lsp-rust-analyzer-cargo-watch-command "clippy")
  (setq lsp-rust-analyzer-display-lifetime-elision-hints-enable "skip_trivial")
  (setq lsp-rust-analyzer-display-chaining-hints t)
  (setq lsp-rust-analyzer-display-lifetime-elision-hints-use-parameter-names nil)
  (setq lsp-rust-analyzer-display-closure-return-type-hints t)
  (setq lsp-rust-analyzer-display-parameter-hints nil))

(defun my/rustic--direnv-updated (&rest _)
  "Refresh rust-analyzer command after direnv updates."
  (my/setup-rust-analyzer))

(with-eval-after-load 'direnv
  (when (boundp 'direnv-after-update-environment-hook)
    (add-hook 'direnv-after-update-environment-hook #'my/rustic--direnv-updated)))

(with-eval-after-load 'envrc
  (when (boundp 'envrc-after-update-hook)
    (add-hook 'envrc-after-update-hook #'my/rustic--direnv-updated)))
