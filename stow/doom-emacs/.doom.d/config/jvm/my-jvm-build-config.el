;;; my-jvm-build-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

(require 'my-jdk-config)

(require 'projectile)

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

;; Mill support removed

;; All Mill-specific functions removed

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
      ('gradle (my/setup-gradle))
      ('gradle-kts (my/setup-gradle))
      ('maven (my/setup-maven))
      (_ (message "No recognized build tool found")))))

;; Key bindings for build tool management
(map! :leader
      (:prefix ("<f9>" . "build")
       :desc "Setup build tool" "s" #'my/setup-build-tool))

;; Auto-setup build tool when entering project
(add-hook 'projectile-after-switch-project-hook #'my/setup-build-tool)

(provide 'my-jvm-build-config)
