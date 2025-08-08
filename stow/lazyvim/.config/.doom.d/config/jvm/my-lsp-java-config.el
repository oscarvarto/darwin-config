;;; my-lsp-java-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

;;;###autoload

(defun my/setup-java-environment ()
  "Setup Java development environment with LSP."
  (interactive)
  ;; Only load paths if not already loaded
  (require 'my-paths)

  ;; Load JDK configuration lazily
  (unless (featurep 'my-jdk-config)
    (load (expand-file-name "my-jdk-config" doom-private-dir)))

  ;; Basic LSP Java settings
  (setq lsp-java-jdt-download-url
        "https://www.eclipse.org/downloads/download.php?file=/jdtls/snapshots/jdt-language-server-latest.tar.gz")

  ;; Lazy load Lombok
  (setq lombok-library-path (concat doom-data-dir "lombok.jar"))
  (unless (file-exists-p lombok-library-path)
    (url-copy-file "https://projectlombok.org/downloads/lombok.jar" lombok-library-path))
  (setq lsp-java-vmargs '("-XX:+UseParallelGC" "-XX:GCTimeRatio=4" "-XX:AdaptiveSizePolicyWeight=90" "-Dsun.zip.disableMemoryMapping=true" "-Xmx16G" "-Xms100m"))
  (push (concat "-javaagent:"
                  (expand-file-name lombok-library-path))
        lsp-java-vmargs)

  ;; Configure LSP Java settings
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

;; Add debug configuration management
;;;###autoload

(defun my/setup-java-debug ()
  "Setup Java debugging environment."
  (interactive)
  (require 'dap-java)

  ;;(dap-java-setup)
  (message "Java debug environment ready"))

;; Keybindings - only set up when java-mode is loaded
(map! :map java-mode-map
      :localleader
      (:prefix ("j" . "java")
       :desc "Setup Java environment" "s" #'my/setup-java-environment
       :desc "Setup debugger" "d" #'my/setup-java-debug))

;; Hook into java-mode - ensures environment is set up when needed
(add-hook 'java-mode-hook #'my/setup-java-environment)

(provide 'my-lsp-java-config)

;;; my-lsp-java-config.el ends here
