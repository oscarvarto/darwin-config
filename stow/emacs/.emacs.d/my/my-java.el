;;; my-java.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Java development with lsp-mode and lsp-java

(require 'subr-x)
(require 'use-package)

;; Configure lsp-java (already installed via elpaca in my-elpaca.el)
(use-package lsp-java
  :ensure nil
  :init
  ;; Set download URL before lsp-java loads (used by lsp-install-server)
  (setq lsp-java-jdt-download-url
        "https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz")
  :after lsp-mode)

;; Project detection for Java projects (project.el)
(with-eval-after-load 'project
  (defun my/project-try-maven (dir)
    "Find Maven project root by looking for pom.xml."
    (when-let* ((root (locate-dominating-file dir "pom.xml")))
      (cons 'transient root)))

  (defun my/project-try-gradle (dir)
    "Find Gradle project root by looking for build.gradle or build.gradle.kts."
    (when-let* ((root (or (locate-dominating-file dir "build.gradle")
                          (locate-dominating-file dir "build.gradle.kts"))))
      (cons 'transient root)))

  ;; Add Maven and Gradle project detection before VC
  (add-hook 'project-find-functions #'my/project-try-maven 10)
  (add-hook 'project-find-functions #'my/project-try-gradle 10))

;; Projectile integration for Java projects
(with-eval-after-load 'projectile
  (defun my/projectile-maven-root (dir)
    "Return Maven project root for DIR or nil.
Only operates in Maven projects (checks for pom.xml)."
    (when-let* ((root (locate-dominating-file dir "pom.xml")))
      (file-truename root)))

  (defun my/projectile-gradle-root (dir)
    "Return Gradle project root for DIR or nil.
Only operates in Gradle projects (checks for build.gradle*)."
    (when-let* ((root (or (locate-dominating-file dir "build.gradle")
                          (locate-dominating-file dir "build.gradle.kts"))))
      (file-truename root)))

  ;; Add Maven project root detection (prepend to list like Rust does)
  (setq projectile-project-root-functions
        (cons #'my/projectile-maven-root
              (cl-remove #'my/projectile-maven-root
                         projectile-project-root-functions)))

  ;; Add Gradle project root detection (prepend to list)
  (setq projectile-project-root-functions
        (cons #'my/projectile-gradle-root
              (cl-remove #'my/projectile-gradle-root
                         projectile-project-root-functions))))

;; Debug helper for Java JDK configuration
(defun my/java-debug-jdk-config ()
  "Display JDK configuration information."
  (interactive)
  (with-current-buffer (get-buffer-create "*Java JDK Config*")
    (let ((inhibit-read-only t))
      (erase-buffer)
      (insert "=== Java JDK Configuration Debug ===\n\n")
      (insert (format "Default JDK Path: %s\n" my/jdk-default-path))
      (insert (format "JAVA_HOME: %s\n\n" (getenv "JAVA_HOME")))
      (insert "Configured Runtimes:\n")
      (dolist (jdk my/jdk-paths)
        (insert (format "  - %s (v%s) %s\n    Path: %s\n"
                        (plist-get jdk :name)
                        (plist-get jdk :version)
                        (if (plist-get jdk :default) "[DEFAULT]" "")
                        (plist-get jdk :path))))
      (insert "\nlsp-java-configuration-runtimes:\n")
      (when (boundp 'lsp-java-configuration-runtimes)
        (seq-do (lambda (rt)
                  (insert (format "  - %s: %s %s\n"
                                  (plist-get rt :name)
                                  (plist-get rt :path)
                                  (if (plist-get rt :default) "[DEFAULT]" ""))))
                lsp-java-configuration-runtimes)))
    (special-mode)
    (display-buffer (current-buffer))))

;; Clear all project detection caches
(defun my/clear-all-project-caches ()
  "Clear all project-related caches (Projectile, Rust workspace, etc.)."
  (interactive)
  (let ((cleared '()))
    ;; Clear Projectile cache
    (when (and (boundp 'projectile-project-root-cache)
               (hash-table-p projectile-project-root-cache))
      (clrhash projectile-project-root-cache)
      (push "Projectile" cleared))
    
    ;; Clear Rust workspace cache
    (when (and (boundp 'my/rust--workspace-cache)
               (hash-table-p my/rust--workspace-cache))
      (clrhash my/rust--workspace-cache)
      (push "Rust workspace" cleared))
    
    (if cleared
        (message "Cleared caches: %s" (string-join cleared ", "))
      (message "No caches to clear"))))

;; Test all projectile root functions
(defun my/test-all-projectile-functions ()
  "Test all projectile root functions for current directory."
  (interactive)
  (require 'projectile)
  (let* ((dir (or (and buffer-file-name
                       (file-name-directory buffer-file-name))
                  default-directory))
         (truename-dir (file-truename dir)))
    (with-current-buffer (get-buffer-create "*Projectile Function Test*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert (format "Testing from: %s\n" dir))
        (insert (format "Truename: %s\n\n" truename-dir))
        (dolist (func projectile-project-root-functions)
          (let* ((result (condition-case err
                             (funcall func truename-dir)
                           (error (format "ERROR: %S" err)))))
            (insert (format "%-40s => %s\n" func (or result "nil"))))))
      (special-mode)
      (display-buffer (current-buffer)))))

;; Debug helper for Java projects
(defun my/java-debug-project-root ()
  "Display comprehensive project root detection information for current buffer."
  (interactive)
  (require 'projectile)
  (let* ((current-dir (or (and buffer-file-name
                               (file-name-directory buffer-file-name))
                          default-directory))
         (maven-root (locate-dominating-file current-dir "pom.xml"))
         (gradle-root (or (locate-dominating-file current-dir "build.gradle")
                          (locate-dominating-file current-dir "build.gradle.kts")))
         (git-root (locate-dominating-file current-dir ".git"))
         (projectile-root (condition-case err
                              (projectile-project-root)
                            (error (format "Error: %S" err))))
         (project-root (when (fboundp 'project-current)
                         (when-let* ((proj (project-current)))
                           (if (fboundp 'project-root)
                               (project-root proj)
                             (car (project-roots proj)))))))
    (with-current-buffer (get-buffer-create "*Java Project Debug*")
      (let ((inhibit-read-only t))
        (erase-buffer)
        (insert "=== Java Project Root Detection Debug ===\n\n")
        (insert (format "Current directory: %s\n\n" current-dir))
        (insert (format "Buffer-local projectile-project-root variable: %s\n\n" 
                        (if (local-variable-p 'projectile-project-root)
                            projectile-project-root
                          "NOT SET")))
        (insert (format "Maven root (pom.xml): %s\n" (or maven-root "NOT FOUND")))
        (insert (format "Gradle root (build.gradle*): %s\n" (or gradle-root "NOT FOUND")))
        (insert (format "Git root (.git): %s\n\n" (or git-root "NOT FOUND")))
        (insert (format "Projectile root: %s\n" projectile-root))
        (insert (format "Project.el root: %s\n\n" (or project-root "NOT FOUND")))
        (insert (format "projectile-project-root-functions:\n"))
        (dolist (func projectile-project-root-functions)
          (insert (format "  - %S\n" func))))
      (special-mode)
      (display-buffer (current-buffer)))))

;; JDK configuration
(defvar my/jdk-paths
  `((:name "JavaSE-17"
     :path ,(string-trim (shell-command-to-string "mise where java@corretto-17"))
     :version "17"
     :default nil)
    (:name "JavaSE-21"
     :path ,(string-trim (shell-command-to-string "mise where java@corretto-21"))
     :version "21"
     :default nil)
    (:name "JavaSE-25"
     :path ,(string-trim (shell-command-to-string "mise where java@corretto-25"))
     :version "25"
     :default t))
  "List of JDK installations available for use by LSP servers.")

(defun my/jdk-get-default-path ()
  "Get the path of the default JDK installation."
  (let ((default-jdk (seq-find (lambda (jdk) (plist-get jdk :default)) my/jdk-paths)))
    (when default-jdk
      (plist-get default-jdk :path))))

(defun my/jdk-get-lsp-java-runtimes ()
  "Get JDK runtime configuration for lsp-java."
  (let ((runtimes (mapcar (lambda (jdk)
                           `(:name ,(plist-get jdk :name)
                             :path ,(plist-get jdk :path)
                             :default ,(plist-get jdk :default)))
                         my/jdk-paths)))
    (vconcat runtimes)))

;; LSP Java configuration
(with-eval-after-load 'lsp-java
  ;; Set JAVA_HOME for lsp-java
  (setenv "JAVA_HOME" (my/jdk-get-default-path))

  ;; Download Lombok jar if needed
  (defvar my/lombok-jar-path
    (expand-file-name "config/jvm/bundles/lombok.jar" user-emacs-directory)
    "Path to Lombok jar file.")

  (unless (file-exists-p my/lombok-jar-path)
    (let ((lombok-dir (file-name-directory my/lombok-jar-path)))
      (unless (file-directory-p lombok-dir)
        (make-directory lombok-dir t))
      (message "Downloading Lombok jar...")
      (url-copy-file "https://projectlombok.org/downloads/lombok.jar"
                     my/lombok-jar-path)))

  ;; Configure lsp-java VM arguments
  ;; Optimized for Java 21+ (using Corretto 25 with G1GC and modern JVM features)
  (setq lsp-java-vmargs
        (list "-XX:+UseG1GC"                    ; G1GC is default and better for modern Java
              "-XX:+UseStringDeduplication"     ; Java 8+: Reduce memory for duplicate strings
              "-XX:GCTimeRatio=4"
              "-XX:AdaptiveSizePolicyWeight=90"
              "-Dsun.zip.disableMemoryMapping=true"
              "-Xmx16G"
              "-Xms512m"                        ; Higher min heap for better startup performance
              "--add-modules=ALL-SYSTEM"        ; Modern Java: enable all system modules
              (concat "-javaagent:" (expand-file-name my/lombok-jar-path))))

  ;; Configure lsp-java settings
  (setq lsp-java-java-path (expand-file-name "bin/java" (my/jdk-get-default-path)))
  (setq lsp-java-configuration-runtimes (my/jdk-get-lsp-java-runtimes))

  ;; Additional lsp-java settings
  (setq lsp-java-import-gradle-enabled t
        lsp-java-import-maven-enabled t
        lsp-java-maven-download-sources t
        lsp-java-references-code-lens-enabled t
        lsp-java-signature-help-enabled t
        lsp-java-implementations-code-lens-enabled t
        lsp-java-format-enabled nil
        lsp-java-save-actions-organize-imports nil
        lsp-java-content-provider-preferred "fernflower"
        lsp-java-autobuild-enabled t
        lsp-java-max-concurrent-builds 16
        lsp-java-completion-enabled t
        lsp-java-completion-overwrite t
        lsp-java-completion-guess-method-arguments t
        lsp-java-folding-range-enabled nil
        lsp-java-progress-reports-enabled t
        lsp-java-code-generation-hash-code-equals-use-java7objects t
        lsp-java-code-generation-hash-code-equals-use-instanceof t
        lsp-java-code-generation-use-blocks nil
        lsp-java-code-generation-generate-comments t
        lsp-java-code-generation-to-string-skip-null-values t
        lsp-java-code-generation-to-string-list-array-contents t
        lsp-java-code-generation-to-string-limit-elements 0
        lsp-java-inhibit-message nil))

;; Format settings (optional - Google Style)
(defvar my/java-format-settings-file
  (expand-file-name "config/jvm/eclipse-java-google-style.xml" user-emacs-directory)
  "Path to Eclipse formatter settings file.")

(when (file-exists-p my/java-format-settings-file)
  (with-eval-after-load 'lsp-java
    (setq lsp-java-format-settings-url my/java-format-settings-file
          lsp-java-format-settings-profile "GoogleStyle")))

;; Enable lsp-mode for Java buffers
;; These hooks will autoload lsp-mode when a Java buffer is opened
(defun my/java-lsp-setup ()
  "Setup lsp-mode for Java buffers, ensuring lsp-java is loaded."
  (require 'lsp-java)
  (lsp-deferred))

(add-hook 'java-mode-hook #'my/java-lsp-setup)
(add-hook 'java-ts-mode-hook #'my/java-lsp-setup)

;; DAP (Debug Adapter Protocol) configuration for Java
(with-eval-after-load 'dap-mode
  (require 'dap-java nil t))

(provide 'my-java)
