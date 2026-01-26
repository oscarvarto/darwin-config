;;; early-init.el -*- lexical-binding:t; no-byte-compile: t; -*-

(setq package-enable-at-startup nil)
(setenv "LSP_USE_PLISTS" "true")

;; Safety: If .el is newer than .elc, load the .el instead
;; Protects against stale byte-code without auto-recompilation
(setq load-prefer-newer t)

