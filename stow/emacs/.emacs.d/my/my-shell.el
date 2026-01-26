;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; Set shell to use Nix-managed zsh from ~/.nix-profile
;; This ensures subprocesses have access to git and other Nix-installed tools
(let ((nix-zsh (expand-file-name "~/.nix-profile/bin/zsh")))
  (when (file-executable-p nix-zsh)
    (setq shell-file-name nix-zsh)
    (setq explicit-shell-file-name nix-zsh)))

;; Helper function to add directory to PATH and exec-path
(defun my/add-to-path (dir)
  "Add DIR to exec-path and PATH environment variable if it exists."
  (let ((expanded-dir (expand-file-name dir)))
    (when (file-directory-p expanded-dir)
      (add-to-list 'exec-path expanded-dir)
      (setenv "PATH" (concat expanded-dir ":" (getenv "PATH"))))))

;; Add essential paths for development tools
;; Order matters: later additions take precedence (added to front of PATH)
(my/add-to-path "/opt/homebrew/bin")           ; Homebrew binaries (emacs, etc.)
(my/add-to-path "~/.cargo/bin")                ; Rust tools
(my/add-to-path "~/.volta/bin")                ; Volta-managed Node.js tools (copilot-language-server)
(my/add-to-path "~/.local/share/mise/shims")   ; mise shims
(my/add-to-path "~/.nix-profile/bin")          ; Nix profile bins

(provide 'my-shell)
