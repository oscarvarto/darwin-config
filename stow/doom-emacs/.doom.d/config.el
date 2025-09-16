;;; $DOOMDIR/config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!

;; Fix locale settings to prevent "LANG=en_MX.UTF-8 cannot be used" warning
;; This happens because macOS system locale is set to en_MX but that locale doesn't exist
(setenv "LANG" "en_US.UTF-8")
(setenv "LC_ALL" "en_US.UTF-8")

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;;; Load Path Setup
(defvar my/config-el-dir doom-user-dir)

;; Add path to core utilities and load them
(add-to-list 'load-path (expand-file-name "config/core" my/config-el-dir))
(require 'my-paths) ; Make my/doom-private-dir available

;; Load early cleanup configuration FIRST - this prevents startup errors
(require 'my-early-cleanup-config)

;; Load lazy loading optimizations EARLY to affect subsequent loads
(require 'my-lazy-loading-config)

;; Now load other core configs using require (they are in config/core/)
(require 'my-defaults-config)
(require 'my-banner-config)
(require 'my-gui-appearance-config)
;; (require 'my-startup-benchmark)

;; Helper function for loading
(defun my/load-config (feature group) ; Group is mandatory
  "Load a configuration file FEATURE from GROUP subdirectory."
  ;; Paths are relative to this file (config.el)
  (let ((path (format "config/%s/my-%s-config" group feature)))
    (load! path)))

(my/load-config 'tree-sitter 'misc)
(my/load-config 'large-files 'misc)
(my/load-config 'yasnippet 'misc)

(my/load-config 'treemacs 'ui)

(my/load-config 'lsp 'lsp)

(my/load-config 'jdk 'jvm)
(my/load-config 'jvm-build 'jvm)
(my/load-config 'jvm-compile 'jvm)
(my/load-config 'jvm-navigation 'jvm)
(my/load-config 'lsp-java 'jvm)
(my/load-config 'clojure 'jvm)

(my/load-config 'nix 'languages)
(my/load-config 'rust 'languages)
(my/load-config 'python 'languages)

;;; Tool-specific configurations
(my/load-config 'vterm 'misc)
(my/load-config 'eat 'misc)

(my/load-config 'tabnine-gui 'ai)
(my/load-config 'gptel 'ai)

(my/load-config 'db 'misc)
(my/load-config 'enhanced-auth 'misc)

(my/load-config 'dap 'lsp)

;;; Org mode configuration
(my/load-config 'obsidian 'writing)
(my/load-config 'org 'writing)

;;; Load project cleanup configuration after all other modules
;; This ensures that projectile, treemacs, and other modules are fully loaded
;; before we set up cleanup hooks and timers
(require 'my-project-cleanup-config)
