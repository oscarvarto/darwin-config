;;; my-paths.el --- Path utilities for Doom Emacs config -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres
;; Version: 1.0
;; Package-Requires: ((emacs "27.1"))
;; Keywords: convenience, files
;; URL: https://github.com/oscarvarto/doom-emacs-config

;;; Commentary:
;; This file provides path utility functions for Doom Emacs configuration
;; to make configuration portable across different operating systems and users.
;; It handles cross-platform path normalization and expansion.

;;; Code:

;; Required libraries
(require 'cl-lib)  ; For cl-some and other Common Lisp functions

(defvar my/platform
  (cond
   ((eq system-type 'windows-nt) 'windows)
   ((eq system-type 'darwin) 'macos)
   ((eq system-type 'gnu/linux) 'linux)
   (t 'other))
  "Symbol representing the current platform.")

(defvar my/path-separator
  (if (eq my/platform 'windows) "\\" "/")
  "Path separator for the current platform.")

(defvar my/default-paths
  (let ((home (getenv "HOME")))
    `((:env . ,(expand-file-name ".emacs.d/.local/env" home))
      (:dropbox . ,(expand-file-name 
                    (cond 
                     ((eq my/platform 'macos) "Library/CloudStorage/Dropbox")
                     ((eq my/platform 'windows) "Dropbox")
                     (t "Dropbox"))
                    home))
      (:onedrive . ,(expand-file-name 
                     (cond 
                      ((eq my/platform 'macos) "Library/CloudStorage/OneDrive-Personal")
                      ((eq my/platform 'windows) "OneDrive")
                      (t "OneDrive"))
                     home))
      (:mmdc . ,(cond 
                 ((eq my/platform 'macos) 
                  (or (executable-find "mmdc") 
                      (expand-file-name ".volta/bin/mmdc" home)))
                 ((eq my/platform 'windows)
                  (or (executable-find "mmdc.cmd") 
                      (executable-find "mmdc")))
                 (t (executable-find "mmdc"))))
      (:jdks . 
             ,(cond 
               ((eq my/platform 'macos) 
                 "/Library/Java/JavaVirtualMachines")
               ((eq my/platform 'windows) 
                (expand-file-name "AppData/Local/Coursier/Cache/arc" home))
               ((eq my/platform 'linux)
                (expand-file-name ".cache/coursier/arc" home))
               (t (expand-file-name ".cache/coursier/arc" home))))
      (:org . ,(expand-file-name "org" home))
      (:mobileorg . ,(cond 
                      ((eq my/platform 'macos)
                       (expand-file-name "Library/CloudStorage/Dropbox/Apps/MobileOrg" home))
                      (t
                       (expand-file-name "Dropbox/Apps/MobileOrg" home))))
      ;; Path for manually cloned EAF repo
      (:eaf . ,(expand-file-name "git-repos/site-lisp/emacs-application-framework" home))))
  "Association list of default paths used in configuration.")

;; Get the Doom private directory if available, otherwise use a fallback

(defvar my/doom-private-dir
  (if (boundp 'doom-private-dir)
      doom-private-dir
    (or (file-name-directory (or load-file-name buffer-file-name))
        (expand-file-name ".doom.d" (getenv "HOME"))))
  "Path to Doom's private configuration directory or fallback if not in Doom.")

;; Try to load user-specific path overrides if they exist
(let ((custom-paths-file (expand-file-name "my-paths-custom.el" my/doom-private-dir)))
  (when (file-exists-p custom-paths-file)
    (load-file custom-paths-file)))

;;;###autoload

(defun my/expand-home-path (path)
  "Expand PATH relative to user's home directory.
Returns an absolute path with proper directory separators for the current platform."
  (expand-file-name path (getenv "HOME")))

;;;###autoload

(defun my/get-path (path-key)
  "Get path by PATH-KEY from configured paths.
PATH-KEY should be a keyword symbol like :dropbox or :org."
  (or (cdr (assoc path-key my/default-paths))
      (error "Path %s not found in configuration" path-key)))

;;;###autoload

(defun my/join-path (&rest parts)
  "Join path PARTS with appropriate separator for current platform."
  (mapconcat #'identity (delq nil (mapcar #'string-trim parts)) my/path-separator))

;;;###autoload

(defun my/locate-dominating-path (file name)
  "Look up directory hierarchy from FILE for directory containing NAME.
Similar to `locate-dominating-file' but returns the full path to NAME in the
parent directory, not just the parent directory."
  (let ((parent (locate-dominating-file file name)))
    (when parent
      (expand-file-name name parent))))

;;;###autoload

(defun my/normalize-path (path)
  "Normalize PATH based on current platform conventions.
Ensures consistent path separator usage."
  (if (eq my/platform 'windows)
      (replace-regexp-in-string "/" "\\\\" path)
    (replace-regexp-in-string "\\\\" "/" path)))

;;;###autoload

(defun my/find-executable (names)
  "Find the first executable from NAMES that exists in PATH.
NAMES can be a string or a list of strings."
  (let ((name-list (if (listp names) names (list names))))
    (cl-some #'executable-find name-list)))

;;;###autoload

(defmacro with-normalized-path (path &rest body)
  "Evaluate BODY with PATH normalized for the current platform."
  (declare (indent 1))
  `(let ((normalized-path (my/normalize-path ,path)))
     ,@body))

(provide 'my-paths)

;;; my-paths.el ends here

