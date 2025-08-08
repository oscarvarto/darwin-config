;;; my-paths-custom-template.el --- Custom path overrides for Doom Emacs config -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Your Name
;; Version: 1.0

;;; Commentary:
;; This is a template file for customizing paths in Doom Emacs.
;; To use this file:
;;  1. Copy it to `my-paths-custom.el` in your Doom private directory
;;  2. Uncomment and customize the paths you want to override
;;  3. Save the file and restart Emacs
;;
;; This file will be loaded by `my-paths.el` and will override the default paths.
;; Any paths not explicitly defined here will use the default values from `my-paths.el`.

;;; Code:

;; Override specific paths by modifying the my/default-paths variable
;; This example shows how to override the :org path - uncomment and customize as needed

;; (setq my/default-paths
;;       (let ((home (getenv "HOME")))
;;         ;; Begin with the existing paths
;;         (append
;;          ;; Add/override specific paths
;;          `(
;;            ;; Example: Override org directory
;;            (:org . ,(expand-file-name "Documents/org" home))
;;
;;            ;; Example: Override Dropbox path for a different location
;;            (:dropbox . ,(expand-file-name "Dropbox" home))
;;
;;            ;; Example: Override mmdc executable path
;;            (:mmdc . "/usr/local/bin/mmdc")
;;
;;            ;; Example: Override JDKs path for a custom location
;;            (:jdks . ,(expand-file-name ".local/share/jdks" home))
;;           )
;;          ;; Keep all other default paths
;;          (cl-remove-if (lambda (pair) (member (car pair) '(:org :dropbox :mmdc :jdks)))
;;                        my/default-paths))))

;; Add custom paths that don't exist in the default configuration
;; (setq my/custom-paths
;;       (let ((home (getenv "HOME")))
;;         `(
;;           ;; Example: Define a custom path for Maven repository
;;           (:maven-repo . ,(expand-file-name ".m2/repository" home))
;;
;;           ;; Example: Define a custom path for project templates
;;           (:templates . ,(expand-file-name "Templates" home))
;;          )))

;; Extend the my/get-path function to check custom paths if key not found in default paths
;; (defun my/get-path-with-custom (path-key)
;;   "Get path by PATH-KEY from configured paths, including custom paths.
;; PATH-KEY should be a keyword symbol like :dropbox or :org."
;;   (or (cdr (assoc path-key my/default-paths))
;;       (and (boundp 'my/custom-paths) (cdr (assoc path-key my/custom-paths)))
;;       (error "Path %s not found in configuration" path-key)))
;;
;; ;; Override the original function
;; (advice-add 'my/get-path :override #'my/get-path-with-custom)

;; Platform-specific customizations
;; Example for Windows users
;; (when (eq my/platform 'windows)
;;   (setq my/default-paths
;;         (append
;;          `(
;;            ;; Override OneDrive path for Windows
;;            (:onedrive . ,(expand-file-name "OneDrive" (getenv "USERPROFILE")))
;;           )
;;          (cl-remove-if (lambda (pair) (eq (car pair) :onedrive))
;;                        my/default-paths))))

;; Linux-specific customizations
;; (when (eq my/platform 'linux)
;;   (setq my/default-paths
;;         (append
;;          `(
;;            ;; Override Dropbox path for Linux
;;            (:dropbox . ,(expand-file-name ".dropbox" (getenv "HOME")))
;;           )
;;          (cl-remove-if (lambda (pair) (eq (car pair) :dropbox))
;;                        my/default-paths))))

(provide 'my-paths-custom)

;;; my-paths-custom-template.el ends here

