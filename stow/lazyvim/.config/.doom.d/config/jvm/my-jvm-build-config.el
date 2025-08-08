;;; my-jvm-build-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'my-jdk-config)

(require 'projectile) ; Required by mill-module-name

(defvar my/jvm-build-features-initialized nil
  "Track which build tool features have been initialized.")

(defvar my/jvm-build-tool-cache (make-hash-table :test 'equal)
  "Cache for build tool configurations.")

;;;###autoload

(defun my/detect-build-tool ()
  "Detect the build tool used in the current project."
  (let* ((project-dir (projectile-project-root))
         (cache-key (format "build-tool-%s" project-dir))
         (cached-value (gethash cache-key my/jvm-build-tool-cache)))
    (or cached-value
        (let ((build-tool
               (cond
                ((file-exists-p (expand-file-name "build.mill" project-dir))
                 'mill)
                ((file-exists-p (expand-file-name "build.gradle" project-dir))
                 'gradle)
                ((file-exists-p (expand-file-name "build.gradle.kts" project-dir))
                 'gradle-kts)
                ((file-exists-p (expand-file-name "pom.xml" project-dir))
                 'maven)
                ((file-exists-p (expand-file-name "build.sbt" project-dir))
                 'sbt)
                ((file-exists-p (expand-file-name "deps.edn" project-dir))
                 'clojure-deps)
                ((file-exists-p (expand-file-name "project.clj" project-dir))
                 'lein))))
          (puthash cache-key build-tool my/jvm-build-tool-cache)
          build-tool))))

;;;###autoload

(defun my/setup-mill ()
  "Setup Mill build tool integration."
  (interactive)
  (unless (plist-get my/jvm-build-features-initialized :mill)
    ;; Basic Mill configuration
    (setq compilation-command "mill compile")

    ;; Mill REPL setup for Scala
    (with-eval-after-load 'scala-mode
      (require 'my-scala-config)

      (setq scala-compile-command "mill compile"))

    ;; Mill REPL setup for Clojure
    (with-eval-after-load 'clojure-mode
      (require 'my-clojure-config))

    (setq my/jvm-build-features-initialized
          (plist-put my/jvm-build-features-initialized :mill t))))

;;;###autoload

(defvar my/mill-nrepl-port-regex "^nREPL server started on port \\([0-9]+\\)$"
  "Regex to capture the nREPL port from Mill output.")

(defun my/mill-nrepl-filter (proc string)
  "Process filter for Mill nREPL process.
Looks for the port number and connects CIDER."
  (let ((buffer (process-buffer proc))
        (port-found nil)
        (project-dir (process-get proc :project-dir))
        (module-name (process-get proc :module-name)))
    (when buffer
      (with-current-buffer buffer
        (save-excursion
          (goto-char (point-max))
          (insert string) ; Append new output
          ;; Check buffer content for the port
          (goto-char (point-min))
          (when (re-search-forward my/mill-nrepl-port-regex nil t)
            (setq port-found (string-to-number (match-string 1)))
            (message "Detected Mill nREPL port %d for module %s" port-found module-name))))

      ;; If port found, connect CIDER and remove filter
      (when port-found
        (message "Connecting CIDER to Mill nREPL for module %s on port %d..." module-name port-found)
        (require 'cider)

        (cider-connect-clj
         `(:host "localhost"
           :port ,port-found
           :project-dir ,project-dir
           :repl-context ,(format "Mill %s nREPL" module-name)))
        ;; Remove this filter after connection attempt
        (set-process-filter proc nil)))))

(defun my/mill-nrepl-sentinel (proc event)
  "Process sentinel for Mill nREPL process."
  (let ((module-name (process-get proc :module-name))
        (exit-status (process-status proc)))
    (cond
     ((memq exit-status '(signal exit))
      (message "Mill nREPL process for module %s %s: %s"
               module-name
               (if (eq exit-status 'signal) "killed" "exited")
               (replace-regexp-in-string "\n" "" event))
      ;; Ensure filter is removed if process dies before connection
      (set-process-filter proc nil))
     ((eq exit-status 'run)))))
      ;; Process is running, do nothing specific here unless needed


;;;###autoload

(defun my/mill-start-clojure-repl (module-name)
  "Start a Clojure REPL for a Mill module and connect CIDER.
Dynamically detects the nREPL port.
MODULE-NAME is the name of the Mill module to start the REPL for."
  (interactive "sEnter Mill module name (default: main): ")
  (let ((module-name (if (string-empty-p module-name) "main" module-name))
        (project-dir (projectile-project-root)))
    (when project-dir
      ;; Ensure correct JDK is used
      (let ((java-home-info (my-jdk-get-project-java-home project-dir)))
        (when java-home-info
          (setenv "JAVA_HOME" (car java-home-info))))

      ;; Start Mill nREPL using make-process
      (let* (;; -- Binding List --
             (proc-name (format "mill-%s-nrepl" module-name))
             (proc-buffer (format "*%s*" proc-name))
             (default-directory project-dir) ; Used by make-process below
             (process-connection-type nil) ; Use a pipe
             (nrepl-proc
              (make-process :name proc-name
                            :buffer (get-buffer-create proc-buffer)
                            :command (list "mill" (format "%s.nrepl" module-name))
                            :connection-type process-connection-type
                            :sentinel #'my/mill-nrepl-sentinel
                            :filter #'my/mill-nrepl-filter)))
        ;; -- Body --
        ;; Store context for filter/sentinel using process-put
        (process-put nrepl-proc :project-dir project-dir)
        (process-put nrepl-proc :module-name module-name)

        ;; Set process query on exit flag to nil
        (set-process-query-on-exit-flag nrepl-proc nil)

        (message "Starting Mill nREPL for module %s... Output in %s"
                 module-name proc-buffer)
        ;; Display the buffer
        (display-buffer proc-buffer))))) ; End Body
      ; End let*
       ; End when block
   ; End defun

;;;###autoload

(defun mill-module-name ()
  "Get the Mill module name for the current project.
Prompts the user with a reasonable default."
  (let* ((project-dir (projectile-project-root))
         (project-name (when project-dir (file-name-nondirectory (directory-file-name project-dir))))
         (default-module (if project-name project-name "main")))
    (read-string (format "Mill module name (default: %s): " default-module) nil nil default-module)))

;; TODO: This was copy pasted manually. Not sure if works
;;;###autoload

(defun my/setup-mill ()
  "Setup mill build tool integration."
  (interactive)
  (unless (plist-get my/jvm-build-features-initialized :mill)
    (setq compilation-command "./gradlew build")
    (setq my/jvm-build-features-initialized
          (plist-put my/jvm-build-features-initialized :mill t))))

;;;###autoload

(defun my/setup-gradle ()
  "Setup Gradle build tool integration."
  (interactive)
  (unless (plist-get my/jvm-build-features-initialized :gradle)
    (setq compilation-command "./gradlew build")
    (setq my/jvm-build-features-initialized
          (plist-put my/jvm-build-features-initialized :gradle t))))

;;;###autoload

(defun my/setup-maven ()
  "Setup Maven build tool integration."
  (interactive)
  (unless (plist-get my/jvm-build-features-initialized :maven)
    (setq compilation-command "mvn compile")
    (setq my/jvm-build-features-initialized
          (plist-put my/jvm-build-features-initialized :maven t))))

;;;###autoload

(defun my/setup-build-tool ()
  "Setup the appropriate build tool for the current project."
  (interactive)
  (let ((build-tool (my/detect-build-tool)))
    (pcase build-tool
      ('mill (my/setup-mill))
      ('gradle (my/setup-gradle))
      ('gradle-kts (my/setup-gradle))
      ('maven (my/setup-maven))
      (_ (message "No recognized build tool found")))))

;; Key bindings for build tool management
(map! :leader
      (:prefix ("<f9>" . "build")
       :desc "Setup build tool" "s" #'my/setup-build-tool
       :desc "Start Clojure REPL" "r" #'my/mill-start-clojure-repl))

;; Auto-setup build tool when entering project
(add-hook 'projectile-after-switch-project-hook #'my/setup-build-tool)

(provide 'my-jvm-build-config)
