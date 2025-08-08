;;; my-scala-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

(require 'my-jvm-build-config)

;; Configuration for Scala development environment with LSP Metals integration.
;; Provides lazy loading of features and proper resource management.

(defgroup my-scala nil
  "Customization group for Scala development environment."
  :group 'languages)

(defvar my/scala-features-initialized nil
  "Track which Scala features have been initialized.")

(defvar my/scala-repl-processes (make-hash-table :test 'equal)
  "Hash table of active Scala REPL processes keyed by project directory.")

(defvar my/metals-initialized-projects (make-hash-table :test 'equal)
  "Track which projects have had Metals initialized.")

(defvar my/scala-repl-history (make-hash-table :test 'equal)
  "Cache of REPL command history per project.")

(defvar my/scala-project-settings (make-hash-table :test 'equal)
  "Store project-specific Scala settings.")

(defconst my/scala-settings-version "1.0"
  "Version of the Scala settings format.
Used to ensure compatibility when loading saved settings.")

(defun my/scala-save-project-settings ()
  "Save current Scala settings for the project."
  (interactive)
  (when-let ((project-dir (projectile-project-root)))
    (when (and (bound-and-true-p lsp-mode)
               (boundp 'lsp-metals-show-implicit-conversions))
      (let ((settings
             `(:implicit-conversions ,lsp-metals-show-implicit-conversions
               :implicit-parameters ,lsp-metals-show-implicit-arguments
               :inferred-types ,lsp-metals-show-inferred-type
               :super-method-lenses ,lsp-metals-super-method-lenses-enabled)))
        (puthash project-dir settings my/scala-project-settings)
        (message "Saved Scala settings for project %s" project-dir)))))

(defun my/scala-restore-project-settings ()
  "Restore saved Scala settings for the project."
  (interactive)
  (when-let* ((project-dir (projectile-project-root))
              (settings (gethash project-dir my/scala-project-settings)))
    (when (and (bound-and-true-p lsp-mode)
               (boundp 'lsp-metals-show-implicit-conversions))
      (condition-case err
          (progn
            (setq lsp-metals-show-implicit-conversions
                  (plist-get settings :implicit-conversions)
                  lsp-metals-show-implicit-arguments
                  (plist-get settings :implicit-parameters)
                  lsp-metals-show-inferred-type
                  (plist-get settings :inferred-types)
                  lsp-metals-super-method-lenses-enabled
                  (plist-get settings :super-method-lenses))
            (message "Restored Scala settings for project %s" project-dir))
        (error
         (message "Failed to restore settings: %s" (error-message-string err)))))))

;;;###autoload
(defun my/scala-setup-basic ()
  "Setup basic Scala environment without loading heavy dependencies."
  (setq scala-indent:align-forms t
        scala-indent:align-parameters t
        ;; Add compiler settings
        compilation-ask-about-save nil
        compilation-skip-threshold 2)

  ;; Basic modes that should be enabled immediately
  (subword-mode 1)
  (electric-pair-mode 1)
  (rainbow-delimiters-mode 1))

;;;###autoload
(defun my/scala-update-metals-java-home ()
  "Update Metals' Java Home based on project configuration."
  (when-let* ((project-dir (projectile-project-root))
              (java-home-info (my-jdk-get-project-java-home project-dir)))
    (let ((java-home (car java-home-info))
          (source (cdr java-home-info)))
      (setq-local lsp-metals-java-home java-home)
      (message "Set Metals Java Home from %s for project %s" source project-dir))))

;;;###autoload
(defun my/scala-setup-metals ()
  "Setup Metals with lazy loading of features."
  (interactive)
  (let ((project-dir (projectile-project-root)))
    (unless (gethash project-dir my/metals-initialized-projects)
      ;; Load paths and JDK configuration
      (require 'my-jdk-config)

      ;; Ensure Metals is available
      (my/scala-ensure-metals)

      ;; Basic Metals configuration with build tool integration
      (let* ((build-tool (my/detect-build-tool))
             (metals-args (cond
                           ((eq build-tool 'mill) '("-J-Xss4m" "-J-Xms100m" "-J-Xmx1200m"))
                           ((eq build-tool 'sbt) '("-J-Xss4m" "-J-Xms100m" "-J-Xmx2048m"))
                           (t '("-J-Xss4m" "-J-Xms100m" "-J-Xmx1200m")))))

        (require 'lsp-metals)

        ;; Set initial JDK configuration
        (my/scala-update-metals-java-home)

        (setq lsp-metals-server-args metals-args
              lsp-metals-server-command "metals-vim")

        (after! lsp-metals
          (setq lsp-metals-scalafmt-config-path ".scalafmt.conf"
                lsp-metals-sbt-script "sbt"
                lsp-metals-mill-script "mill"
                lsp-metals-super-method-lenses-enabled t
                lsp-metals-show-implicit-arguments nil
                lsp-metals-show-implicit-conversions nil
                lsp-metals-show-inferred-type t))

        ;; Setup specific build tool integration
        (pcase build-tool
          ('mill
           (setq lsp-metals-mill-script "mill"))
          ('sbt
           (setq lsp-metals-sbt-script "sbt"))
          ('gradle
           (setq lsp-metals-gradle-script "./gradlew")))

        (puthash project-dir t my/metals-initialized-projects)
        (setq my/scala-features-initialized
              (plist-put my/scala-features-initialized :metals t))))))

;;;###autoload
(defun my/scala-setup-sbt ()
  "Setup SBT integration."
  (interactive)
  (unless (plist-get my/scala-features-initialized :sbt)
    (require 'sbt-mode)

    (setq sbt:program-name "sbt"
          sbt:default-command "compile"
          sbt:save-some-buffers t)

    ;; Configure console
    (setq sbt:sbt-history-file (expand-file-name ".sbt-history" user-emacs-directory)
          sbt:console-history-file (expand-file-name ".scala-console-history" user-emacs-directory))

    (setq my/scala-features-initialized
          (plist-put my/scala-features-initialized :sbt t))))

;;;###autoload
(defun my/scala-setup-debug ()
  "Setup debugging support for Scala."
  (interactive)
  (unless (plist-get my/scala-features-initialized :debug)
    (require 'dap-mode)

    (require 'dap-scala)

    ;; Configure DAP for different build tools
    (let ((build-tool (my/detect-build-tool)))
      (pcase build-tool
        ('mill
         (dap-register-debug-template
          "Scala Mill Debug"
          (list :type "scala"
                :request "launch"
                :name "Mill Debug"
                :metals (list :name "Mill Debug"))))
        ('sbt
         (dap-register-debug-template
          "Scala SBT Debug"
          (list :type "scala"
                :request "launch"
                :name "SBT Debug"
                :metals (list :name "SBT Debug"))))
        ('gradle
         (dap-register-debug-template
          "Scala Gradle Debug"
          (list :type "scala"
                :request "launch"
                :name "Gradle Debug"
                :metals (list :name "Gradle Debug"))))))

    (setq my/scala-features-initialized
          (plist-put my/scala-features-initialized :debug t))))

;;;###autoload
(defun my/scala-repl-cleanup ()
  "Clean up Scala REPL processes when closing Emacs or killing buffers."
  (maphash (lambda (project-dir process)
             (when (process-live-p process)
               (kill-process process)))
           my/scala-repl-processes)
  (clrhash my/scala-repl-processes))

;;;###autoload
(defun my/scala-repl-restart ()
  "Restart the Scala REPL for the current project."
  (interactive)
  (let ((project-dir (projectile-project-root)))
    (when-let ((proc (gethash project-dir my/scala-repl-processes)))
      (when (process-live-p proc)
        (kill-process proc))
      (remhash project-dir my/scala-repl-processes))
    (my/scala-start-repl)))

;;;###autoload
(defun my/scala-save-repl-history-before-cleanup ()
  "Save REPL history before cleaning up resources."
  (when (hash-table-count my/scala-repl-history)
    (my/scala-persist-repl-history)))

;;;###autoload
(defun my/scala-persist-repl-history ()
  "Save REPL history for all projects."
  (interactive)
  (maphash
   (lambda (project-dir history)
     (let ((history-file (expand-file-name
                          (format ".scala-repl-history-%s"
                                  (file-name-base (directory-file-name project-dir)))
                          doom-cache-dir)))
       (condition-case err
           (progn
             (make-directory (file-name-directory history-file) t)
             (with-temp-file history-file
               (insert (string-join history "\n"))))
         (error
          (message "Failed to save REPL history for %s: %s"
                   project-dir (error-message-string err))))))
   my/scala-repl-history))

;;;###autoload
(defun my/scala-start-repl ()
  "Start a Scala REPL based on the project's build tool."
  (interactive)
  (let* ((project-dir (projectile-project-root))
         (build-tool (my/detect-build-tool))
         (java-home-info (my-jdk-get-project-java-home project-dir))
         (history-file (expand-file-name
                        (format ".scala-repl-history-%s"
                                (file-name-base (directory-file-name project-dir)))
                        doom-cache-dir)))

    ;; Load history if available
    (when (file-exists-p history-file)
      (puthash project-dir
               (with-temp-buffer
                 (insert-file-contents history-file)
                 (split-string (buffer-string) "\n" t))
               my/scala-repl-history))

    (if (not project-dir)
        (message "Not in a project directory")
      (when java-home-info
        (setenv "JAVA_HOME" (car java-home-info)))

      (pcase build-tool
        ('mill
         (let* ((module-name (read-string "Enter Mill module name (default: main): " "main"))
                (proc-name (format "mill-%s-repl" module-name))
                (proc-buffer (format "*%s*" proc-name)))
           (condition-case err
               (let ((proc (start-process proc-name proc-buffer
                                          "mill" (format "%s.repl" module-name))))
                 ;; Store the process for cleanup
                 (puthash project-dir proc my/scala-repl-processes)
                 (set-process-sentinel proc
                                       (lambda (process event)
                                         (when (string-match-p "finished\\|exited abnormally" event)
                                           (message "Mill REPL process %s" event)
                                           (remhash project-dir my/scala-repl-processes))))
                 (pop-to-buffer proc-buffer))
             (file-error
              (user-error "Failed to start Mill REPL: executable not found"))
             (error
              (message "Failed to start Mill REPL: %s" (error-message-string err))))))

        ('sbt
         (require 'sbt-mode)

         (let ((project-dir (projectile-project-root)))
           (sbt:run-sbt)
           ;; Store the SBT process for cleanup
           (when-let ((proc (get-buffer-process (sbt:buffer-name))))
             (puthash project-dir proc my/scala-repl-processes)
             (set-process-sentinel
              proc
              (lambda (process event)
                (when (string-match-p "finished\\|exited abnormally" event)
                  (message "SBT REPL process %s" event)
                  (remhash project-dir my/scala-repl-processes)))))
           (sbt-command "console")))

        ('gradle
         (let* ((proc-name "gradle-scala-repl")
                (proc-buffer (format "*%s*" proc-name)))
           (condition-case err
               (let ((proc (start-process proc-name proc-buffer
                                          "./gradlew" "scalaConsole")))
                 ;; Store the process for cleanup
                 (puthash project-dir proc my/scala-repl-processes)
                 (set-process-sentinel proc
                                       (lambda (process event)
                                         (when (string-match-p "finished\\|exited abnormally" event)
                                           (message "Gradle Scala REPL process %s" event)
                                           (remhash project-dir my/scala-repl-processes))))
                 (pop-to-buffer proc-buffer))
             (file-error
              (user-error "Failed to start Gradle REPL: executable not found"))
             (error
              (message "Failed to start Gradle REPL: %s" (error-message-string err))))))

        (_ (message "No supported build tool found for Scala REPL"))))))

;; Mode hooks with lazy loading
(add-hook 'scala-mode-hook #'my/scala-setup-basic)

;; Add hooks for JDK configuration
(add-hook 'scala-mode-hook #'my/scala-update-metals-java-home)
(add-hook 'scala-ts-mode-hook #'my/scala-update-metals-java-home)

;; Add REPL cleanup to kill-emacs-hook
(add-hook 'kill-emacs-hook #'my/scala-repl-cleanup)

;;;###autoload
(defun my/scala-setup-full-env ()
  "Setup complete Scala development environment."
  (interactive)
  (my/scala-setup-basic)
  (my/scala-setup-metals)

  ;; Setup build tool based on project
  (let ((build-tool (my/detect-build-tool)))
    (pcase build-tool
      ('sbt (my/scala-setup-sbt))
      ('mill (message "Using Mill build tool"))
      ('gradle (message "Using Gradle build tool"))
      (_ (message "No specific build tool configuration needed"))))

  ;; Check for missing dependencies
  (my/scala-check-build-dependencies)

  (message "Scala environment fully configured"))

;;;###autoload
(defun my/scala-check-build-dependencies ()
  "Check if all required build tool dependencies are available."
  (interactive)
  (let* ((build-tool (my/detect-build-tool))
         (missing-deps '()))
    (pcase build-tool
      ('mill
       (unless (executable-find "mill")
         (push "mill" missing-deps)))
      ('sbt
       (unless (executable-find "sbt")
         (push "sbt" missing-deps)))
      ('gradle
       (unless (or (executable-find "gradle")
                   (file-exists-p "gradlew"))
         (push "gradle" missing-deps))))
    (when missing-deps
      (message "Missing build tools: %s" (string-join missing-deps ", ")))))

;;;###autoload
(defun my/scala-run-test-at-point ()
  "Run test at point using the appropriate build tool."
  (interactive)
  (let ((build-tool (my/detect-build-tool)))
    (pcase build-tool
      ('mill
       (let* ((module-name (read-string "Enter Mill module name (default: main): " "main")))
         (compile (format "mill %s.test" module-name))))
      ('sbt
       (require 'sbt-mode)

       (sbt-command "testOnly *"))
      ('gradle
       (compile "./gradlew test"))
      (_ (message "No supported build tool found for running tests")))))

;;;###autoload
(defun my/scala-run-all-tests ()
  "Run all tests using the appropriate build tool."
  (interactive)
  (let ((build-tool (my/detect-build-tool)))
    (pcase build-tool
      ('mill
       (compile "mill __.test"))
      ('sbt
       (require 'sbt-mode)

       (sbt-command "test"))
      ('gradle
       (compile "./gradlew test"))
      (_ (message "No supported build tool found for running tests")))))

;;;###autoload
(defun my/scala-metals-rebuild-workspace ()
  "Rebuild the Metals workspace."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-build-import)
    (message "Rebuilding Metals workspace...")))

;;;###autoload
(defun my/scala-metals-doctor ()
  "Run Metals doctor to diagnose workspace issues."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-doctor-run)))

;;;###autoload
(defun my/scala-organize-imports ()
  "Organize imports in current buffer."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-organize-imports)))

;;;###autoload
(defun my/scala-metals-compile-cascade ()
  "Compile all projects that depend on the current project."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-compile-cascade)))

;;;###autoload
(defun my/scala-metals-toggle-implicit-conversions ()
  "Toggle showing implicit conversions and classes."
  (interactive)
  (when (and (bound-and-true-p lsp-mode)
             (boundp 'lsp-metals-show-implicit-conversions))
    (setq lsp-metals-show-implicit-conversions
          (not lsp-metals-show-implicit-conversions))
    (message "Implicit conversions %s"
             (if lsp-metals-show-implicit-conversions "enabled" "disabled"))))

;;;###autoload
(defun my/scala-metals-toggle-implicit-parameters ()
  "Toggle showing implicit parameters."
  (interactive)
  (when (and (bound-and-true-p lsp-mode)
             (boundp 'lsp-metals-show-implicit-arguments))
    (setq lsp-metals-show-implicit-arguments
          (not lsp-metals-show-implicit-arguments))
    (message "Implicit parameters %s"
             (if lsp-metals-show-implicit-arguments "enabled" "disabled"))))

;;;###autoload
(defun my/scala-metals-toggle-show-inferred-type ()
  "Toggle showing inferred types."
  (interactive)
  (when (and (bound-and-true-p lsp-mode)
             (boundp 'lsp-metals-show-inferred-type))
    (setq lsp-metals-show-inferred-type
          (not lsp-metals-show-inferred-type))
    (message "Show inferred types %s"
             (if lsp-metals-show-inferred-type "enabled" "disabled"))))

;;;###autoload
(defun my/scala-metals-extract-value ()
  "Extract the expression under cursor into a val definition."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-extract-value)))

;;;###autoload
(defun my/scala-metals-extract-method ()
  "Extract the expression under cursor into a method definition."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-extract-method)))

;;;###autoload
(defun my/scala-metals-insert-type-annotation ()
  "Insert type annotation for the definition under cursor."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-insert-type-annotation)))

;;;###autoload
(defun my/scala-metals-toggle-tree-view ()
  "Toggle the Metals tree view."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-toggle-tree-view)))

;;;###autoload
(defun my/scala-metals-reveal-in-tree ()
  "Reveal the current file in Metals tree view."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-reveal-in-tree)))

;;;###autoload
(defun my/scala-metals-toggle-super-method-lenses ()
  "Toggle the display of super method lenses."
  (interactive)
  (when (and (bound-and-true-p lsp-mode)
             (boundp 'lsp-metals-super-method-lenses-enabled))
    (setq lsp-metals-super-method-lenses-enabled
          (not lsp-metals-super-method-lenses-enabled))
    (message "Super method lenses %s"
             (if lsp-metals-super-method-lenses-enabled "enabled" "disabled"))))

;;;###autoload
(defun my/scala-metals-toggle-file-decorations ()
  "Toggle Metals file decorations."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-toggle-file-decorations)))

;;;###autoload
(defun my/scala-metals-switch-bsp ()
  "Switch build server."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-switch-bsp)))

;;;###autoload
(defun my/scala-metals-reset-choice ()
  "Reset build tool choice."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-metals-reset-choice)))

;;;###autoload
(defun my/scala-cleanup-project ()
  "Clean up project-specific Metals configuration."
  (interactive)
  (when-let ((project-dir (projectile-project-root)))
    (remhash project-dir my/metals-initialized-projects)
    (message "Cleaned up Metals configuration for project %s" project-dir)))

;;;###autoload
(defun my/scala-cleanup-resources ()
  "Clean up all Scala-related resources."
  (interactive)
  (my/scala-repl-cleanup)
  (clrhash my/metals-initialized-projects)
  (clrhash my/scala-project-settings)
  (setq my/scala-features-initialized nil)
  (message "Cleaned up all Scala resources"))

;;;###autoload
(defun my/scala-persist-metals-settings ()
  "Save current Metals settings to disk.
Settings are saved to 'scala-metals-settings.el' in `doom-cache-dir'.
This includes project-specific settings and initialization state."
  (interactive)
  (let ((settings-file (expand-file-name "scala-metals-settings.el" doom-cache-dir))
        (settings (list :version my/scala-settings-version
                        :project-settings my/scala-project-settings
                        :initialized-projects my/metals-initialized-projects)))
    (condition-case err
        (progn
          (make-directory (file-name-directory settings-file) t)
          (with-temp-file settings-file
            (prin1 settings (current-buffer)))
          (message "Saved Metals settings to %s" settings-file))
      (error
       (message "Failed to save Metals settings: %s" (error-message-string err))))))

;;;###autoload
(defun my/scala-load-metals-settings ()
  "Load Metals settings from disk."
  (interactive)
  (let ((settings-file (expand-file-name "scala-metals-settings.el" doom-cache-dir)))
    (when (file-exists-p settings-file)
      (when-let* ((settings (with-temp-buffer
                              (insert-file-contents settings-file)
                              (read (current-buffer))))
                  (version (plist-get settings :version))
                  ;; Only load if versions match
                  ((string= version my/scala-settings-version)))
        (setq my/scala-project-settings (plist-get settings :project-settings)
              my/metals-initialized-projects (plist-get settings :initialized-projects))
        (message "Loaded Metals settings from %s" settings-file)))))

;; Project hooks - order matters for proper cleanup and save/restore
(add-hook 'projectile-before-switch-project-hook #'my/scala-save-project-settings)
(add-hook 'projectile-before-switch-project-hook #'my/scala-cleanup-project)
(add-hook 'projectile-after-switch-project-hook #'my/scala-restore-project-settings)

;; Cleanup hooks - order matters
(add-hook 'kill-emacs-hook #'my/scala-save-repl-history-before-cleanup 'append)
(add-hook 'kill-emacs-hook #'my/scala-persist-metals-settings 'append)
(add-hook 'kill-emacs-hook #'my/scala-repl-cleanup 'append)
(add-hook 'kill-emacs-hook #'my/scala-cleanup-resources 'append)

;; Initialization hooks
(add-hook 'after-init-hook #'my/scala-load-metals-settings)

;;;###autoload
(defun my/scala-reset-metals ()
  "Reset Metals state and configuration."
  (interactive)
  (when (bound-and-true-p lsp-mode)
    (lsp-workspace-restart)
    (my/scala-cleanup-project)
    (my/scala-setup-metals)
    (message "Reset Metals configuration")))

;;;###autoload
(defun my/scala-ensure-metals ()
  "Ensure Metals is installed and available."
  (interactive)
  (unless (executable-find "metals")
    (if (yes-or-no-p "Metals is not installed. Install it using Coursier?")
        (let ((install-cmd "install-metals-emacs.sh"))
          (async-shell-command install-cmd "*metals-installation*"))
      (user-error "Metals is required for Scala development"))))

;; Key bindings
(map! :after scala-mode
      :map scala-mode-map
      :localleader
      ;; Basic Scala operations
      (:prefix ("s" . "scala")
       :desc "Setup Metals" "m" #'my/scala-setup-metals
       :desc "Setup SBT" "s" #'my/scala-setup-sbt
       :desc "Start REPL" "r" #'my/scala-start-repl
       :desc "Restart REPL" "R" #'my/scala-repl-restart
       :desc "Setup debug" "d" #'my/scala-setup-debug
       :desc "Setup full env" "f" #'my/scala-setup-full-env)

      ;; Testing operations
      (:prefix ("t" . "test")
       :desc "Test at point" "t" #'my/scala-run-test-at-point
       :desc "Test all" "a" #'my/scala-run-all-tests)

      ;; Workspace management
      (:prefix ("w" . "workspace")
       :desc "Rebuild workspace" "r" #'my/scala-metals-rebuild-workspace
       :desc "Run doctor" "d" #'my/scala-metals-doctor
       :desc "Organize imports" "o" #'my/scala-organize-imports
       :desc "Compile cascade" "c" #'my/scala-metals-compile-cascade
       :desc "Toggle tree view" "t" #'my/scala-metals-toggle-tree-view
       :desc "Reveal in tree" "f" #'my/scala-metals-reveal-in-tree
       :desc "Switch BSP" "s" #'my/scala-metals-switch-bsp
       :desc "Save project settings" "S" #'my/scala-save-project-settings
       :desc "Restore project settings" "R" #'my/scala-restore-project-settings
       :desc "Save Metals settings" "M" #'my/scala-persist-metals-settings
       :desc "Load Metals settings" "L" #'my/scala-load-metals-settings
       :desc "Reset Metals" "X" #'my/scala-reset-metals
       :desc "Reset choice" "x" #'my/scala-metals-reset-choice)

      ;; View controls
      (:prefix ("v" . "view")
       :desc "Toggle file decorations" "d" #'my/scala-metals-toggle-file-decorations
       :desc "Toggle super method lenses" "s" #'my/scala-metals-toggle-super-method-lenses)

      ;; Implicit handling
      (:prefix ("i" . "implicits")
       :desc "Toggle conversions" "c" #'my/scala-metals-toggle-implicit-conversions
       :desc "Toggle parameters" "p" #'my/scala-metals-toggle-implicit-parameters
       :desc "Toggle inferred types" "t" #'my/scala-metals-toggle-show-inferred-type)

      ;; Refactoring operations
      (:prefix ("r" . "refactor")
       :desc "Extract value" "v" #'my/scala-metals-extract-value
       :desc "Extract method" "m" #'my/scala-metals-extract-method
       :desc "Insert type annotation" "t" #'my/scala-metals-insert-type-annotation))

(provide 'my-scala-config)

;;; my-scala-config.el ends here
