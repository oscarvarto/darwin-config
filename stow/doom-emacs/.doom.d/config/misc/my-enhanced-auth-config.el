;;; my-enhanced-auth-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Commentary:
;; Enhanced authentication configuration for Doom Emacs
;; Provides secure credential management with multiple backends

;;; Code:

(require 'auth-source)
(require 'my-auth-helpers)

;; Enhanced auth-source configuration
(setq auth-sources '("~/.authinfo.gpg"
                     "~/.authinfo"
                     "~/.netrc"))

;; Configure auth-source to be more secure by default
(setq auth-source-save-behavior nil)  ; Don't auto-save credentials
(setq auth-source-cache-expiry 3600)  ; Cache for 1 hour only

;; ========== Git credential integration ==========

;;;###autoload
(defun my/get-git-credentials (&optional work-profile)
  "Get git credentials using secure backends.
If WORK-PROFILE is non-nil, get work credentials, otherwise personal."
  (let* ((profile (if work-profile "work" "personal"))
         (name (my/get-secret :op-item (format "%s-git" profile)
                             :op-field "name"
                             :op-vault (if work-profile "Work" "Personal")))
         (email (my/get-secret :op-item (format "%s-git" profile)
                              :op-field "email"  
                              :op-vault (if work-profile "Work" "Personal"))))
    (list :name (or name (user-login-name))
          :email (or email (format "%s@users.noreply.github.com" (user-login-name))))))

;;;###autoload  
(defun my/setup-git-credentials ()
  "Set up git credentials dynamically."
  (interactive)
  (let* ((is-work-dir (and (boundp 'my/work-directories)
                          (cl-some (lambda (dir)
                                     (string-prefix-p (expand-file-name dir "~") 
                                                     default-directory))
                                   my/work-directories)))
         (creds (my/get-git-credentials is-work-dir))
         (name (plist-get creds :name))
         (email (plist-get creds :email)))
    (message "Using git credentials: %s <%s>" name email)
    (list :name name :email email)))

;; ========== Enhanced secret retrieval functions ==========

;;;###autoload
(defun my/get-api-key (service &optional vault)
  "Get API key for SERVICE from secure storage.
Tries both 1Password and auth-source."
  (or (my/get-secret :op-item service :op-field "api-key" :op-vault vault)
      (my/get-secret :host service :user "api" :type 'password)))

;;;###autoload  
(defun my/get-database-url (db-name &optional vault)
  "Get database URL for DB-NAME from secure storage."
  (or (my/get-secret :op-item db-name :op-field "url" :op-vault vault)
      (my/get-secret :host db-name :user "database" :type 'password)))

;; ========== Work directory detection ==========

(defvar my/work-directories '("ir" "work" "company")
  "List of directory names that indicate work projects.")

;;;###autoload
(defun my/is-work-directory-p (&optional dir)
  "Check if DIR (or current directory) is a work directory."
  (let ((check-dir (or dir default-directory)))
    (cl-some (lambda (work-dir)
               (string-match-p (format "/%s/" work-dir) check-dir))
             my/work-directories)))

;; ========== Security enhancements ==========

;; Enhanced GPG configuration
(setq epa-pinentry-mode 'loopback)
(setq epg-gpg-program "gpg")

;; Ensure GPG agent is properly configured
(setenv "GPG_TTY" (shell-command-to-string "tty | tr -d '\n'"))

;; Auto-refresh credentials periodically
(defvar my/credential-refresh-timer nil
  "Timer for refreshing credentials.")

;;;###autoload
(defun my/refresh-credentials ()
  "Refresh cached credentials."
  (interactive)
  (clrhash my/op-credentials-cache)
  (setq my/op-session-verified nil)
  (auth-source-forget-all-cached)
  (message "🔄 Credential cache cleared"))

;; Refresh credentials every hour
(when my/credential-refresh-timer
  (cancel-timer my/credential-refresh-timer))

(setq my/credential-refresh-timer
      (run-at-time "1 hour" 3600 #'my/refresh-credentials))

;; ========== Magit integration ==========

(with-eval-after-load 'magit
  (defun my/magit-set-secure-credentials ()
    "Set up secure git credentials for magit operations."
    (let* ((creds (my/setup-git-credentials))
           (name (plist-get creds :name))
           (email (plist-get creds :email)))
      ;; Set local git config for this repository
      (when (and name email)
        (magit-git "config" "user.name" name)
        (magit-git "config" "user.email" email))))
  
  ;; Hook to set credentials when entering magit
  (add-hook 'magit-status-mode-hook #'my/magit-set-secure-credentials))

;; ========== Security warnings ==========

(defun my/check-hardcoded-credentials ()
  "Check current buffer for potential hardcoded credentials."
  (interactive)
  (let ((patterns '("password.*=" "api.*key.*=" "@.*\\.com" "token.*=")))
    (save-excursion
      (goto-char (point-min))
      (catch 'found
        (dolist (pattern patterns)
          (when (re-search-forward pattern nil t)
            (message "⚠️  Potential hardcoded credential found: %s" 
                    (buffer-substring-no-properties 
                     (line-beginning-position) (line-end-position)))
            (throw 'found t)))
        (message "✅ No obvious hardcoded credentials found")))))

;; Auto-check for hardcoded credentials in certain file types
(add-hook 'prog-mode-hook
          (lambda ()
            (when (and buffer-file-name
                      (string-match-p "\\.(el\\|nix\\|sh\\|py\\|js\\|ts\\)$" buffer-file-name))
              (run-with-idle-timer 2 nil #'my/check-hardcoded-credentials))))

(provide 'my-enhanced-auth-config)
