;;; my-db-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;;--------------------------------------------------------------------
;; Emacs SQL client `ejc-sql'.
;;
(require 'ejc-sql)

(load! "my-auth-helpers") ;; For secure credential retrieval
(require 'my-auth-helpers) ;; For secure credential retrieval

;; SECURITY NOTE:
;; Credentials are no longer hardcoded in this file. Instead, they are retrieved from:
;; 1. ~/.authinfo.gpg - Emacs' built-in encrypted credential store
;;    Format: machine DATABASE-NAME-db login USERNAME password PASSWORD
;;    Example: machine sqlnovel-db login oscarvarto password your_secure_password
;;
;; 2. 1Password CLI - If credentials aren't found in authinfo
;;    Make sure to create entries in 1Password with the database name as the item name
;;    and standard username/password fields
;;
;; Use `op signin` in the terminal before using if 1Password session expires
;; Require completion frontend (autocomplete or company). One of them or both.
;;(require 'ejc-autocomplete)

(setq nrepl-sync-request-timeout 60)
(setq clomacs-httpd-default-port 8090) ; Use a port other than 8080.
;; Allow use any CIDER nREPL not only library dedicated nREPL
(setq clomacs-allow-other-repl t)

;; Show results of SQL snippets evaluation in `org-mode'
;; in same buffer.
(setq ejc-org-mode-show-results t)
;;(setq ejc-use-flx t)                          ; Enable `flx' fuzzy matching.
(setq ejc-completion-system 'standard)
(setq ejc-result-table-impl 'ejc-result-mode) ; Set major-mode for results.
;;(setq ejc-result-table-impl 'orgtbl-mode)  ; Default major-mode for results.

;; Since `winner-mode' is enabled and M-<arrow> keys are used for
;; windows navigation, so disable this keys for `orgtbl-mode-map'.
(define-key orgtbl-mode-map (kbd "<return>") nil)
(define-key orgtbl-mode-map (kbd "M-<left>") nil)
(define-key orgtbl-mode-map (kbd "M-<right>") nil)
(define-key orgtbl-mode-map (kbd "M-<down>") nil)
(define-key orgtbl-mode-map (kbd "M-<up>") nil)
;; Use C-M-<arrow> keys instead.
(define-key orgtbl-mode-map (kbd "C-M-<left>") 'org-table-move-column-left)
(define-key orgtbl-mode-map (kbd "C-M-<right>") 'org-table-move-column-right)
(define-key orgtbl-mode-map (kbd "C-M-<up>") 'org-table-move-row-up)
(define-key orgtbl-mode-map (kbd "C-M-<down>") 'org-table-move-row-down)
;; Add run SQL key familiar to users of PLSQL Developer.
(define-key ejc-sql-mode-keymap (kbd "<F8>") 'ejc-eval-user-sql-at-point)

(defun k/sql-mode-hook ()
  (ejc-sql-mode t))

(add-hook 'sql-mode-hook 'k/sql-mode-hook)

(defun k/ejc-result-mode-hook ()
  (display-line-numbers-mode))

(add-hook 'ejc-result-mode-hook 'k/ejc-result-mode-hook)

(defun k/ejc-sql-mode-hook ()
  ;; Enable one of the completion frontend by default but not both.
  (corfu-mode +1)
  (ejc-eldoc-setup)      ; Setup ElDoc.
  (rainbow-delimiters-mode t) ; https://github.com/Fanael/rainbow-delimiters
  ;;(idle-highlight-mode t)     ; https://github.com/nonsequitur/idle-highlight-mode
  ;;(paredit-everywhere-mode)   ; https://github.com/purcell/paredit-everywhere
  (electric-pair-mode))

(add-hook 'ejc-sql-minor-mode-hook 'k/ejc-sql-mode-hook)

(defun k/ejc-sql-connected-hook ()
  (ejc-set-fetch-size 99)         ; Limit for the number of records to output.
  (ejc-set-max-rows 99)           ; Limit for the number of records in ResultSet.
  (ejc-set-show-too-many-rows-message t) ; Set output 'Too many rows' message.
  (ejc-set-column-width-limit 25) ; Limit for outputting the number of chars per column.
  (ejc-set-use-unicode nil))         ; Use unicode symbols for grid borders.

(add-hook 'ejc-sql-connected-hook 'k/ejc-sql-connected-hook)

(global-set-key (kbd "C-c eb") 'ejc-get-temp-editor-buffer)

;; Load file with actual connections configurations
;; `ejc-create-connection' calls.
;;(require 'ejc-databases nil 'noerror)
;; mvn org.apache.maven.plugins:maven-dependency-plugin:get -Dartifact=com.mysql:mysql-connector-j:9.0.0

;; SQLNovel connection - using secure credential retrieval
;; SQLNovel connection - using secure credential retrieval
;; Use a lazy-loading approach to avoid authentication requests at startup

(defvar sql-novel-connection nil
  "Lazy-loaded SQLNovel database connection.")

(defun my/connect-sql-novel ()
  "Connect to SQLNovel database, creating connection if needed."
  (interactive)
  (unless sql-novel-connection
    (setq sql-novel-connection
          (my/ejc-create-connection-with-auth
           "SQLNovel"
           :classpath (concat "~/.m2/repository/com/mysql/mysql-connector-j/9.1.0/"
                            "mysql-connector-j-9.1.0.jar")
           :connection-uri "jdbc:mysql://localhost:3306/SQLNovel"
           :auth-source-user "oscarvarto"
           :op-item "SQLNovel")))
  sql-novel-connection)

;; usqa3 connection - using secure credential retrieval

(defvar usqa3-connection nil
  "Lazy-loaded usqa3 database connection.")

(defun my/connect-usqa3 ()
  "Connect to usqa3 database, creating connection if needed."
  (interactive)
  (unless usqa3-connection
    (setq usqa3-connection
          (my/ejc-create-connection-with-auth
           "usqa3"
           :classpath (concat "~/.m2/repository/com/mysql/mysql-connector-j/9.1.0/"
                            "mysql-connector-j-9.1.0.jar")
           :dbtype "mysql"
           :dbname "irhythmd"
           :host "localhost"
           :port "3306"
           :sslmode "false"
           :auth-source-user "sqa_automation"
           :op-item "irhythmd")))
  usqa3-connection)
(provide 'my-db-config)

;;; my-db-config.el ends here
