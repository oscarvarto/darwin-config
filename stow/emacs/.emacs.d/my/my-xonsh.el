;;; my-xonsh.el --- Xonsh shell script support -*- lexical-binding: t; no-byte-compile: t; -*-

;; Xonsh major mode derived from python-ts-mode (when available) or python-mode.
;; Provides syntax highlighting for xonsh-specific constructs:
;;   - Environment variables: $VAR, ${VAR}, $VAR.attr
;;   - Subprocess operators: $(), !(), @(), @$(), ![], $[]
;;   - Glob patterns: `pattern`, g`pattern`, r`pattern`
;;   - Path literals: p"path", pf"path"
;;   - Regex literals: re`pattern`
;;   - Keywords: xontrib, aliases

(require 'python)

;; Use python-ts-mode when available (Emacs 29+)
(defvar my/xonsh-use-treesitter
  (and (fboundp 'treesit-available-p)
       (treesit-available-p)
       (treesit-language-available-p 'python))
  "Non-nil if tree-sitter Python support is available.")

(when my/xonsh-use-treesitter
  (require 'python nil t))

(defgroup xonsh nil
  "Major mode for editing xonsh scripts."
  :group 'languages
  :prefix "xonsh-")

(defcustom xonsh-indent-offset 4
  "Default indentation offset for xonsh mode."
  :type 'integer
  :group 'xonsh)

(defface xonsh-env-variable-face
  '((t :inherit font-lock-type-face))
  "Face for xonsh environment variables ($VAR, ${VAR})."
  :group 'xonsh)

(defface xonsh-subprocess-operator-face
  '((t :inherit font-lock-preprocessor-face))
  "Face for xonsh subprocess operators ($(), !(), @(), etc.)."
  :group 'xonsh)

(defface xonsh-glob-face
  '((t :inherit font-lock-string-face))
  "Face for xonsh glob patterns."
  :group 'xonsh)

(defvar xonsh-font-lock-keywords
  `(;; Xonsh keywords
    (,(regexp-opt '("xontrib") 'symbols)
     . font-lock-keyword-face)

    ;; Built-in xonsh objects
    (,(regexp-opt '("aliases" "__xonsh__" "XSH") 'symbols)
     . font-lock-builtin-face)

    ;; Subprocess capture operators: $() and $[] - captures output
    (,(rx (group (any "$"))
          (group (any "(" "[")))
     (1 'xonsh-subprocess-operator-face)
     (2 'xonsh-subprocess-operator-face))

    ;; Subprocess uncaptured: !() and ![] - runs without capture
    (,(rx (group "!")
          (group (any "(" "[")))
     (1 'xonsh-subprocess-operator-face)
     (2 'xonsh-subprocess-operator-face))

    ;; Python evaluation in subprocess: @() and @$()
    (,(rx (group "@" (opt "$"))
          (group "("))
     (1 'xonsh-subprocess-operator-face)
     (2 'xonsh-subprocess-operator-face))

    ;; Environment variables with braces: ${VAR} or ${...}
    (,(rx (group "$" "{")
          (group (1+ (not (any "}"))))
          (group "}"))
     (1 'xonsh-subprocess-operator-face)
     (2 'xonsh-env-variable-face)
     (3 'xonsh-subprocess-operator-face))

    ;; Environment variables: $VAR, $VAR.attr, $VAR.attr.subattr
    ;; Must come after ${} pattern to avoid conflicts
    (,(rx (group "$")
          (group (1+ (or word "_"))
                 (* "." (1+ (or word "_")))))
     (1 'xonsh-subprocess-operator-face)
     (2 'xonsh-env-variable-face))

    ;; Glob literals: `pattern`, g`pattern`, r`pattern`, p`pattern`
    (,(rx (opt (any "g" "r" "p" "f"))
          (group "`")
          (group (*? anything))
          (group "`"))
     (1 'xonsh-glob-face)
     (2 'xonsh-glob-face)
     (3 'xonsh-glob-face))

    ;; Path string literals: p"...", pf"...", pr"..."
    (,(rx (group "p" (opt (any "f" "r")))
          (group (any "\"" "'")))
     (1 font-lock-string-face)
     (2 font-lock-string-face))

    ;; Regex string literals: re` ... `
    (,(rx (group "re")
          (group "`")
          (group (*? anything))
          (group "`"))
     (1 font-lock-keyword-face)
     (2 'xonsh-glob-face)
     (3 font-lock-string-face)
     (4 'xonsh-glob-face)))
  "Font lock keywords for xonsh-specific syntax.")

(defvar xonsh-mode-map
  (let ((map (make-sparse-keymap)))
    (set-keymap-parent map python-mode-map)
    map)
  "Keymap for `xonsh-mode'.")

;; Define xonsh-mode based on available Python mode
(if my/xonsh-use-treesitter
    ;; Tree-sitter version (Emacs 29+)
    (define-derived-mode xonsh-mode python-ts-mode "Xonsh"
      "Major mode for editing xonsh scripts.
Derived from `python-ts-mode' for tree-sitter based syntax highlighting.
Adds font-lock patterns for xonsh-specific syntax.

\\{xonsh-mode-map}"
      :group 'xonsh
      ;; Add xonsh keywords to existing font-lock
      (font-lock-add-keywords nil xonsh-font-lock-keywords 'append)
      (setq-local indent-tabs-mode nil)
      (setq-local tab-width xonsh-indent-offset)
      (setq-local python-indent-offset xonsh-indent-offset))

  ;; Fallback to python-mode (pre-Emacs 29 or no tree-sitter)
  (define-derived-mode xonsh-mode python-mode "Xonsh"
    "Major mode for editing xonsh scripts.
Derived from `python-mode' with xonsh-specific syntax highlighting.

\\{xonsh-mode-map}"
    :group 'xonsh
    ;; Prepend xonsh keywords to python's font-lock
    (setcar font-lock-defaults
            (append xonsh-font-lock-keywords
                    (if (boundp 'python-font-lock-keywords-maximum-decoration)
                        python-font-lock-keywords-maximum-decoration
                      python-font-lock-keywords)))
    (setq-local indent-tabs-mode nil)
    (setq-local tab-width xonsh-indent-offset)
    (setq-local python-indent-offset xonsh-indent-offset)))

;; File associations
(add-to-list 'auto-mode-alist '("\\.xsh\\'" . xonsh-mode))
(add-to-list 'auto-mode-alist '("\\.xonshrc\\'" . xonsh-mode))
(add-to-list 'auto-mode-alist '("xonshrc\\'" . xonsh-mode))

;; Interpreter association for scripts with #!/usr/bin/env xonsh
(add-to-list 'interpreter-mode-alist '("xonsh" . xonsh-mode))

(provide 'my-xonsh)
;;; my-xonsh.el ends here
