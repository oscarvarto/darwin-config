;;; my-auth-helpers.el -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:
;; This file provides secure credential retrieval functions using both
;; auth-source (Emacs' built-in credential manager with .authinfo.gpg)
;; and 1Password CLI (op command).
;;
;; Usage:
;; - For retrieving any credential:
;;   (my/get-secret :host "example.com" :user "username" :type 'password)
;;
;; - For database credentials specifically:
;;   (my/get-db-credentials "database-name" "username")

;;; Code:
(require 'auth-source)

(require 'my-paths) ; For path utilities

;; ========== Auth-source functions ==========

;;;###autoload

(defun my/auth-source-get-secret (host user &optional port)
  "Get secret from auth-source for HOST, USER and optional PORT.
Returns nil if credentials are not found."
  (let* ((auth-source-creation-prompts
          '((secret . "Password for %h:%p: ")))
         (matches (auth-source-search :host host
                                      :user user
                                      :port (or port "any")
                                      :require '(:secret)
                                      :create nil))
         (entry (car matches)))
    (when entry
      (let ((secret (plist-get entry :secret)))
        (if (functionp secret)
            (funcall secret)
          secret)))))

;; ========== 1Password CLI functions ==========

(defvar my/op-session-verified nil
  "Flag indicating if 1Password session has been verified.")

(defvar my/op-credentials-cache (make-hash-table :test 'equal)
  "Cache for 1Password credentials to avoid multiple authentication prompts.")

;;;###autoload

(defun my/ensure-op-session ()
  "Ensure 1Password session is active.
Returns t if session is valid, nil otherwise.
Displays a message prompting for 'op signin' if needed."
  (unless my/op-session-verified
    (let ((temp-file (make-temp-file "op-check-")))
      (unwind-protect
          (progn
            (call-process-shell-command "op account list > /dev/null 2>&1" nil nil)
            (if (= 0 (call-process-shell-command "op account list > /dev/null 2>&1"))
                (setq my/op-session-verified t)
              (message "1Password session required. Please run 'op signin' in terminal first.")
              nil))
        (when (file-exists-p temp-file)
          (delete-file temp-file)))))
  my/op-session-verified)


;;;###autoload

(defun my/op-get-credentials (item &optional vault)
  "Get both username and password from 1Password CLI for ITEM.
Returns (username . password) cons cell or nil if retrieval fails.
Optionally specify VAULT name."
  (let ((cache-key (format "%s:%s" item (or vault ""))))
    (or (gethash cache-key my/op-credentials-cache)
        (when (or my/op-session-verified (my/ensure-op-session))
          (let* ((vault-arg (if vault (format "--vault=%s" vault) ""))
                 (temp-file (make-temp-file "op-output-"))
                 (command (format "op item get %s --fields username,password %s > %s 2>/dev/null"
                                item vault-arg temp-file))
                 result)
            (unwind-protect
                (progn
                  (call-process-shell-command command nil nil)
                  (when (file-exists-p temp-file)
                    (with-temp-buffer
                      (insert-file-contents temp-file)
                      (goto-char (point-min))
                      (when (re-search-forward "^\\([^\n]+\\)\n\\([^\n]+\\)$" nil t)
                        (let ((creds (cons (match-string 1) (match-string 2))))
                          (puthash cache-key creds my/op-credentials-cache)
                          creds)))))
              (when (file-exists-p temp-file)
                (delete-file temp-file))))))))

;;;###autoload

(defun my/op-get-secret (item field &optional vault)
  "Get secret from 1Password CLI for ITEM and FIELD.
Optionally specify VAULT name. Returns nil if retrieval fails.
Will prompt for 1Password authentication if needed."
  (if (member field '("username" "password"))
      (let ((creds (my/op-get-credentials item vault)))
        (if (string= field "username")
            (car creds)
          (cdr creds)))
    ;; For non-username/password fields, use direct retrieval with caching
    (let* ((cache-key (format "%s:%s:%s" item field (or vault "")))
           (cached-value (gethash cache-key my/op-credentials-cache)))
      (or cached-value
          (when (or my/op-session-verified (my/ensure-op-session))
            (let* ((vault-arg (if vault (format "--vault=%s" vault) ""))
                   (temp-file (make-temp-file "op-output-"))
                   (command (format "op item get %s --fields %s %s > %s 2>/dev/null" 
                                  item field vault-arg temp-file))
                   result)
              (unwind-protect
                  (progn
                    (call-process-shell-command command nil nil)
                    (when (file-exists-p temp-file)
                      (with-temp-buffer
                        (insert-file-contents temp-file)
                        (setq result (string-trim (buffer-string)))
                        (puthash cache-key result my/op-credentials-cache)
                        result)))
                (when (file-exists-p temp-file)
                  (delete-file temp-file)))))))))

;;;###autoload

(defun my/op-get-password (item &optional vault)
  "Get password from 1Password CLI for ITEM.
Optionally specify VAULT name."
  (my/op-get-secret item "password" vault))

;;;###autoload

(defun my/op-get-username (item &optional vault)
  "Get username from 1Password CLI for ITEM.
Optionally specify VAULT name."
  (my/op-get-secret item "username" vault))

;; ========== Combined credential retrieval ==========

;;;###autoload

(defun my/get-secret (&rest args)
  "Get secret using available credential sources.
Arguments are provided as key-value pairs:
  :host    - Host/server name (required for auth-source)
  :user    - Username (required for auth-source)
  :port    - Port or service (optional for auth-source)
  :op-item - 1Password item name
  :op-field - 1Password field name (defaults to 'password')
  :op-vault - 1Password vault name (optional)
  :type    - Type of secret: 'password, 'username, etc.

Example: (my/get-secret :host \"mysql.example.com\" :user \"admin\" 
                       :op-item \"mysql-prod\" :type 'password)"
  (let* ((host (plist-get args :host))
         (user (plist-get args :user))
         (port (plist-get args :port))
         (op-item (plist-get args :op-item))
         (op-field (or (plist-get args :op-field)
                       (if (eq (plist-get args :type) 'username) "username" "password")))
         (op-vault (plist-get args :op-vault))
         (auth-source-result (when (and host user)
                               (my/auth-source-get-secret host user port)))
         (op-result (when op-item
                      (my/op-get-secret op-item op-field op-vault))))
    ;; Return the first available result
    (or auth-source-result op-result)))

;; ========== Database-specific helper functions ==========

;;;###autoload

(defun my/get-db-credentials (db-name username &optional password-only)
  "Get database credentials for DB-NAME and USERNAME.
If PASSWORD-ONLY is non-nil, returns only the password.
Otherwise, returns (username . password) pair."
  (let* ((db-host (format "%s-db" db-name))
         (password (my/get-secret) 
                   :host db-host
                   :user username
                   :op-item db-name
                   :type 'password))
    (if password-only
        password
      (cons username password))))

;;;###autoload

(defun my/ejc-create-connection-with-auth (connection-name &rest args)
  "Create an ejc-sql connection for CONNECTION-NAME with secure authentication.
ARGS are the standard ejc-create-connection parameters except :user and :password,
which will be retrieved securely.

Example:
  (my/ejc-create-connection-with-auth
   \"mysql-prod\"
   :classpath \"/path/to/jdbc-driver.jar\"
   :subprotocol \"mysql\"
   :subname \"//localhost:3306/mydatabase\"
   :auth-source-user \"mysql-user\"
   :op-item \"mysql-production-db\")"
  (let* ((auth-user (plist-get args :auth-source-user))
         (op-item (plist-get args :op-item))
         (op-vault (plist-get args :op-vault))
         (db-name (or op-item connection-name))
         (credentials (when op-item 
                       (my/op-get-credentials op-item op-vault)))
         (username (or (car credentials)
                      (when auth-user
                        (my/get-secret :host (format "%s-db" db-name)
                                     :user auth-user
                                     :type 'username))))
         (password (or (cdr credentials)
                      (when username
                        (my/get-secret :host (format "%s-db" db-name)
                                     :user username
                                     :type 'password))))
         ;; Remove the auth-related args
         (connection-args (cl-loop for (key val) on args by #'cddr
                                  unless (member key '(:auth-source-user :op-item :op-vault))
                                  collect key
                                  and collect val)))
    ;; Add the securely retrieved credentials
    (when username
      (setq connection-args (plist-put connection-args :user username)))
    (when password
      (setq connection-args (plist-put connection-args :password password)))
    
    ;; Call the original connection function with the modified arguments
    (apply #'ejc-create-connection connection-name connection-args)))

(provide 'my-auth-helpers)

;;; my-auth-helpers.el ends here

