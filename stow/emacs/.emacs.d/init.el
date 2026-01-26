;; -*- lexical-binding: t; no-byte-compile: t; -*-

(add-to-list 'load-path (expand-file-name "my" user-emacs-directory))

;; Load shell configuration early to ensure proper PATH for subprocesses
(load "my-shell")

(load "my-elpaca")
(load "my-theme")
(load "my-fonts")
(load "my-mac")
(load "my-keys")
(load "my-defaults")
(load "my-dashboard")
(load "my-treemacs")
(load "my-completion")
(load "my-vterm")
(load "my-lsp")  ; Load LSP configuration before language-specific configs
(load "my-java")
(load "my-clojure")
(load "my-rust")
(load "my-nix")
(load "my-nushell")
(load "my-xonsh")
(load "my-dap")  ; DAP debugging for Java/Clojure (Rust uses dape)
(load "my-org")
