;; -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package dap-mode
  :init
  (dap-mode 1)
  (dap-ui-mode 1)
  (dap-ui-controls-mode 1)
  (dap-auto-configure-mode)

  (require 'dap-netcore)

  (require 'dap-java)

  (setq dap-java-use-testng +1)

  (require 'dap-lldb)

  (require 'dap-gdb-lldb)

  ;; installs .extension/vscode
  (dap-gdb-lldb-setup)
  ;; (setq dap-gdb-lldb-path "/Users/oscarvarto/.emacs.d/.local/etc/dap-extension/vscode/webfreak.debug")

  ;;https://users.rust-lang.org/t/debugging-in-emacs-doom/99540/2
  (require 'dap-codelldb)

  (dap-codelldb-setup)
  ;; TODO: Find a way to change the :program argument without hardcoding it's value (learn to use dap-hydra)
  (dap-register-debug-template
   "Rust::LLDB Run Configuration"
   (list :type "lldb-mi"
         :request "launch"
         :name "LLDB::Run"
         ;; :gdbpath "rust-lldb"
         :gdbpath "lldb-mi"
         :target nil
         ;; :program "/Users/oscarvarto/git-repos/nushell/target/debug/nu"
         ;; :program "/Users/oscarvarto/rustCode/test_executor/target/debug/test_executor"
         :cwd nil))
  :config
  (setq dap-python-debugger 'debugpy)
  (unless (display-graphic-p)
    (set-face-background 'dap-ui-marker-face "HotPink4") ; An orange background for the line to execute
    (set-face-attribute 'dap-ui-marker-face nil :inherit nil) ; Do not inherit other styles
    (set-face-background 'dap-ui-pending-breakpoint-face "purple") ; Purple background for breakpoints line
    (set-face-attribute 'dap-ui-verified-breakpoint-face nil :inherit 'dap-ui-pending-breakpoint-face)))
  ;; :custom
  ;;(dap-netcore-install-dir "/Users/oscarvarto/.emacs.d/.local/cache/.cache/lsp/netcoredbg"))

(require 'editorconfig)

;; Exclude csharp-mode, csproj-mode, sharper-mode, sln-mode from editorconfig
;; (add-to-list 'editorconfig-exclude-modes '(csproj-mode sharper-mode sln-mode dap-mode))
(editorconfig-mode 1)


