;;; my-nix-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Set NIX_PATH for nixd to find nixpkgs (matching your system configuration)
(setenv "NIX_PATH" "nixpkgs=flake:nixpkgs:/nix/var/nix/profiles/per-user/root/channels")

(use-package nix-mode
  :after lsp-mode
  :hook
  (nix-mode . lsp-deferred) ;; So that envrc mode will work
  :custom
  (lsp-disabled-clients '((nix-mode . nix-nil))) ;; Disable nil so that nixd will be used as lsp-server
  :config
  (setq lsp-nix-nixd-server-path "nixd"
        ;; For flake users, use flake input nixpkgs
        lsp-nix-nixd-nixpkgs-expr "import (builtins.getFlake \"/Users/oscarvarto/nixos-config\").inputs.nixpkgs { }"
        ;; Alternative: use standard nixpkgs if the above doesn't work
        ;; lsp-nix-nixd-nixpkgs-expr "import <nixpkgs> { }"
        ;; Use your actual flake path and configuration name
        lsp-nix-nixd-nixos-options-expr "(builtins.getFlake \"/Users/oscarvarto/nixos-config\").darwinConfigurations.predator.options"
        ;; For home-manager integrated with nix-darwin
        lsp-nix-nixd-home-manager-options-expr "(builtins.getFlake \"/Users/oscarvarto/nixos-config\").darwinConfigurations.predator.options.home-manager.users.type.getSubOptions []"))


;; Configure corfu for nix-mode (avoid slow idle completion)
(add-hook! 'nix-mode-hook
  (defun +nix-setup-completion ()
    "Setup corfu for nix-mode with reasonable performance."
    ;; Increase idle delay to avoid slow completion
    (setq-local corfu-auto-delay 0.3)
    ;; Reduce completion prefix to avoid excessive queries
    (setq-local corfu-auto-prefix 2)
    ;; Enable manual completion
    (setq-local corfu-auto t)))

(setq-hook! 'nix-mode-hook +format-with-lsp nil)
(after! nix-mode
  (set-formatter! 'alejandra '("alejandra" "--quiet") :modes '(nix-mode)))

(provide 'my-nix-config)
