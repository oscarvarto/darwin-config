;;; my-jvm-compile-config.el --- Compile for JVM langs -*- lexical-binding: t; no-byte-compile: t; -*-

;;; Code:

(require 'my-jdk-config nil t) ;; Load JDK config if available

(require 'my-jvm-build-config) ;; Load build tool detection

;;;###autoload

(defun jvm-compile ()
  "Apply Spotless formatter and compile the current JVM project (Maven, Gradle, or Mill).
Enhanced to detect and handle Clojure projects using Mill.
Automatically configures the appropriate JDK for the project's build system.
Prioritizes JDK selection using:
1. direnv-set JAVA_HOME via .envrc (if present)
2. .java-version file in project root
3. Build-system specific requirements
4. Default JDK from configuration"
  (interactive)
  (when (buffer-file-name)
    (save-buffer)
    (let* ((file (buffer-file-name))
           (project-root (projectile-project-root)))
      (if project-root
          (let* ((default-directory project-root)
                 ;; Save the original JAVA_HOME to restore later
                 (original-java-home (getenv "JAVA_HOME"))
                 ;; Get Java Home for this project using the enhanced detection
                 (java-home-info (when (fboundp 'my-jdk-get-project-java-home)
                                   (my-jdk-get-project-java-home project-root)))
                 ;; If no specific Java home found, check build requirements
                 (java-home-info (or java-home-info
                                    (when (fboundp 'my-jdk-detect-build-requirement)
                                      (let ((build-req (my-jdk-detect-build-requirement project-root)))
                                        (when build-req
                                          (let ((java-path (my-jdk-get-path-by-version build-req)))
                                            (when java-path
                                              (cons java-path build-req))))))))
                 ;; Set JAVA_HOME for this compilation if needed
                 (_ (when java-home-info
                      (let ((java-path (car java-home-info))
                            (source (cdr java-home-info)))
                        (setenv "JAVA_HOME" java-path)
                        (message "Using JDK from %s for compilation" source))))
                 ;; Detect build tool using helper function
                 (build-tool (my/detect-build-tool))
                 ;; Determine command based on build tool
                 (cmd (cond
                       ((eq build-tool 'maven)
                        (progn
                          (message "Maven project detected, running Maven build...")
                          "mvn -f pom.xml -T 2.5C spotless:apply compile test-compile"))
                       ((memq build-tool '(gradle gradle-kts)) ; Handle both gradle types
                        (progn
                          (message "Gradle project detected, running Gradle build...")
                          "./gradlew spotlessApply build"))
                       ((eq build-tool 'mill)
                        (progn
                          (message "Mill project detected, running Mill build...")
                          "mill __.compile")) ; Generic compile command for Mill
                       ;; Add other build tools here if needed (sbt, lein, etc.)
                       ;; ((eq build-tool 'sbt) "sbt compile")
                       (t
                        (message "Cannot determine build command for %S project." build-tool)
                        nil))))
            (unwind-protect
                (when cmd
                  (shell-command cmd)
                  (revert-buffer t t t)
                  (message "Build completed."))
              ;; Restore the original JAVA_HOME
              (when original-java-home
                (setenv "JAVA_HOME" original-java-home))))
        (message "Could not find project root. Is Projectile installed and configured?")))))

;; Add key binding for enhanced JVM compilation
;; (global-set-key (kbd "C-c C-b") 'jvm-compile)
(map! :leader
      (:prefix ("<f9>" . "build")
       :desc "JVM Compile" "c" 'jvm-compile))

(provide 'my-jvm-compile-config)

;;; my-jvm-compile-config.el ends here
