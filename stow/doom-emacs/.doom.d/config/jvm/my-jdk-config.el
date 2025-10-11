;;; my-jdk-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

;;; Commentary:
;; Centralized JDK configuration for multiple LSP servers and build systems

;;; Code:

(after! (:any java-mode groovy-mode clojure-mode)
  ;; Load path utilities
  (require 'my-paths)

  (require 'subr-x) ; For version<

  ;; Define JDK paths

  (defvar my-jdk-paths
    (let ((jdk-base (my/get-path :jdks)))
      `((:name "JavaSE-17"
         :path ,(string-trim (shell-command-to-string "mise where java@corretto-17"))
         :version "17"
         :default nil)  ;; Default for LSP servers and most builds
        (:name "JavaSE-21"
         :path ,(string-trim (shell-command-to-string "mise where java@corretto-21"))
         :version "21"
         :default nil)  ;; Default for LSP servers and most builds
        (:name "JavaSE-25"
         :path ,(string-trim (shell-command-to-string "mise where java@corretto-25"))
         :version "25"
         :default t)))
    "List of JDK installations available for use by LSP servers and build tools.")

  ;; Function to get default JDK path

  (defun my-jdk-get-default-path ()
    "Get the path of the default JDK installation."
    (let ((default-jdk (seq-find (lambda (jdk) (plist-get jdk :default)) my-jdk-paths)))
      (when default-jdk
        (plist-get default-jdk :path))))

  ;; Function to get a specific JDK by version

  (defun my-jdk-get-path-by-version (version)
    "Get the path of a JDK installation by its VERSION."
    (let ((matching-jdk (seq-find
                         (lambda (jdk)
                           (string= (plist-get jdk :version) version))
                         my-jdk-paths)))
      (when matching-jdk
        (plist-get matching-jdk :path))))

  ;; Function to get JDK configuration for lsp-java

  (defun my-jdk-get-lsp-java-runtimes ()
    "Get JDK runtime configuration for lsp-java."
    (let ((runtimes (mapcar (lambda (jdk)
                             `(:name ,(plist-get jdk :name)
                               :path ,(plist-get jdk :path)
                               :default ,(plist-get jdk :default)))
                           my-jdk-paths)))
      (vconcat runtimes)))

  ;; Function to get JDK path from environment or configuration

  (defun my-jdk-get-project-java-home (&optional project-dir)
    "Get appropriate Java home path for PROJECT-DIR.
  Prioritizes:
  1. JAVA_HOME set by direnv via .envrc
  2. JDK version specified in .java-version file
  3. Default JDK from configuration

  If PROJECT-DIR is nil, use the current project root detected by Projectile."
    (let* ((project-dir (or project-dir (projectile-project-root)))
           (direnv-java-home (getenv "JAVA_HOME"))
           (has-envrc (and direnv-java-home
                           (fboundp 'envrc-mode)
                           (bound-and-true-p envrc-mode)
                           (not (string= direnv-java-home (my-jdk-get-default-path)))))
           (env-file (when (and project-dir (not has-envrc))
                       (expand-file-name ".java-version" project-dir)))
           (java-version (when (and env-file (file-exists-p env-file))
                           (with-temp-buffer
                             (insert-file-contents env-file)
                             (string-trim (buffer-string))))))
      (cond
       ;; Direnv already set JAVA_HOME
       (has-envrc
        (cons direnv-java-home "direnv"))

       ;; .java-version file exists
       (java-version
        (let ((java-path (my-jdk-get-path-by-version java-version)))
          (if java-path
              (cons java-path java-version)
            (message "JDK version %s specified in .java-version not found" java-version)
            nil)))

       ;; Default JDK from configuration
       (t
        (let ((default-path (my-jdk-get-default-path)))
          (when default-path
            (cons default-path "default")))))))

  ;; Function to set environment variables for a specific project

  (defun my-jdk-set-project-java-home (&optional project-dir)
    "Set JAVA_HOME based on project requirements in PROJECT-DIR.
  If PROJECT-DIR is nil, use the current project root detected by Projectile."
    (interactive)
    (let* ((project-dir (or project-dir (projectile-project-root)))
           (java-home-info (my-jdk-get-project-java-home project-dir)))
      (when java-home-info
        (let ((path (car java-home-info))
              (source (cdr java-home-info)))
          (setenv "JAVA_HOME" path)
          (message "Set JAVA_HOME to JDK %s for project %s" source project-dir)))))

  ;; Function to detect and handle build system JDK requirements

  (defun my-jdk-detect-build-requirement (project-dir)
    "Detect JDK requirements for the build system in PROJECT-DIR.
  Returns appropriate JDK version for the build or nil if default should be used.

  Note: This is only used when no direnv or .java-version configuration exists."
    (let* ((has-pom (file-exists-p (expand-file-name "pom.xml" project-dir)))
           (has-gradle (or (file-exists-p (expand-file-name "build.gradle" project-dir)) ; Use project-dir
                           (file-exists-p (expand-file-name "build.gradle.kts" project-dir)))) ; Use project-dir
           ;; Mill detection removed
           (gradle-properties (expand-file-name "gradle.properties" project-dir))
           (gradle-wrapper-properties (expand-file-name "gradle/wrapper/gradle-wrapper.properties" project-dir)))

      (cond
       ;; Check Gradle version to determine compatibility with JDK 21 (previously JDK 24 mentioned)
       ((and has-gradle (file-exists-p gradle-wrapper-properties))
        (with-temp-buffer
          (insert-file-contents gradle-wrapper-properties)
          ;; Regex to find gradle version like "gradle-X.Y.Z" or "gradle-X.Y"
          (if (re-search-forward "gradle-\([0-9]+\.[0-9]+\(\.[0-9]+\)?\)" nil t)
              (let ((gradle-version (match-string 1)))
                (if (fboundp 'version<)
                    (if (not (version< gradle-version "8.5")) ; If Gradle version >= 8.5
                        "21" ; Mandate JDK 21
                      nil)) ; Close inner if (not version<)
                  ;; Else: version< is not available
                (progn
                  (message "Warning: version< function not available for Gradle JDK check.")
                  nil)))) ; Close progn and outer if (fboundp 'version<)
               ; Close let
            ;; Else: regex failed
        nil))) ; Close if (re-search...)
           ; Close with-temp-buffer
          ; Close cond clause body
       ;; No specific requirement detected for Maven or other cases
    (t nil)) ; Close cond and outer let*
  ;; Add hook for project switching to update JAVA_HOME
  (add-hook 'projectile-after-switch-project-hook #'my-jdk-set-project-java-home))

;; Instructions for project-specific JDK configuration:
;; Option 1: Add JAVA_HOME to your project's .envrc file for direnv (preferred)
;;   Example: export JAVA_HOME=/path/to/your/jdk
;;
;; Option 2: Create a .java-version file in the project root with just the version number
;;   Example: echo "21" > .java-version
;;   Note: This approach requires the JDK to be listed in my-jdk-paths

(provide 'my-jdk-config)

;;; my-jdk-config.el ends here
