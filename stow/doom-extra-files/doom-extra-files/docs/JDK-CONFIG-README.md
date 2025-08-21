# Centralized JDK Configuration System for Doom Emacs

This document explains how to use the centralized JDK configuration system for managing Java Development Kit (JDK) versions across multiple language servers (Java, Scala, Clojure) and build systems (Maven, Gradle, Mill) in your Doom Emacs setup.

## Overview

The centralized JDK configuration system allows you to:

- Define and manage multiple JDK installations in one place
- Automatically select the appropriate JDK for different projects and build systems
- Configure LSP servers for Java, Scala, and Clojure to use consistent JDK versions
- Specify project-specific JDK requirements using `.java-version` files
- Handle build systems that may have specific JDK version requirements

## Table of Contents

1. [Loading the Configuration](#loading-the-configuration)
2. [Configuring Metals (Scala LSP)](#configuring-metals-scala-lsp)
3. [Configuring CIDER (Clojure)](#configuring-cider-clojure)
4. [Project-Specific JDK Configuration](#project-specific-jdk-configuration)
5. [Managing JDK Installations](#managing-jdk-installations)
6. [Using with super-jvm-compile](#using-with-super-jvm-compile)

## Loading the Configuration

To load the centralized JDK configuration, add the following to your `config.el`:

```elisp
;; Load the centralized JDK configuration
(load! "my-jdk-config")
```

Note: If you don't have the `my-jdk-config.el` file in your `.doom.d` directory yet, make sure to create it first.

## Configuring Metals (Scala LSP)

To configure Metals (the Scala LSP server) to use the centralized JDK configuration:

1. Add the following to your `config.el` or create a new `my-scala-config.el` file:

```elisp
(after! lsp-metals
  (require 'my-jdk-config)
  
  ;; Set Metals Java Home to the default JDK from our configuration
  (setq lsp-metals-java-home (my-jdk-get-default-path))
  
  ;; Hook to update Metals' Java Home when switching projects
  (defun my-update-metals-java-home ()
    "Update Metals' Java Home based on project requirements."
    (when (and (derived-mode-p 'scala-mode 'scala-ts-mode)
               (boundp 'lsp-metals-java-home))
      (let* ((project-dir (projectile-project-root))
             (env-file (when project-dir (expand-file-name ".java-version" project-dir)))
             (java-version (when (and env-file (file-exists-p env-file))
                             (with-temp-buffer
                               (insert-file-contents env-file)
                               (string-trim (buffer-string))))))
        (if java-version
            (let ((java-path (my-jdk-get-path-by-version java-version)))
              (when java-path
                (setq-local lsp-metals-java-home java-path)
                (message "Set Metals Java Home to JDK %s for project %s" java-version project-dir)))
          ;; No .java-version file, set to default
          (setq-local lsp-metals-java-home (my-jdk-get-default-path))))))
  
  ;; Add hook to update Metals' Java Home when opening Scala files
  (add-hook 'scala-mode-hook #'my-update-metals-java-home)
  (add-hook 'scala-ts-mode-hook #'my-update-metals-java-home))
```

2. If you created a new file, make sure to load it in your `config.el`:

```elisp
(load! "my-scala-config")
```

## Configuring CIDER (Clojure)

To configure CIDER (Clojure's development environment) to use the centralized JDK configuration:

1. Add the following to your `my-clojure-config.el` file:

```elisp
(require 'my-jdk-config)

(defun my-update-cider-java-home (&rest _)
  "Update CIDER's Java Home based on project requirements."
  (let* ((project-dir (projectile-project-root))
         (env-file (when project-dir (expand-file-name ".java-version" project-dir)))
         (java-version (when (and env-file (file-exists-p env-file))
                         (with-temp-buffer
                           (insert-file-contents env-file)
                           (string-trim (buffer-string))))))
    (if java-version
        (let ((java-path (my-jdk-get-path-by-version java-version)))
          (when java-path
            (setenv "JAVA_HOME" java-path)
            (message "Set CIDER Java Home to JDK %s for project %s" java-version project-dir)))
      ;; No .java-version file, set to default
      (setenv "JAVA_HOME" (my-jdk-get-default-path)))))

;; Run when starting a CIDER REPL
(advice-add 'cider-jack-in :before #'my-update-cider-java-home)
(advice-add 'cider-connect :before #'my-update-cider-java-home)
```

2. If you don't already have `my-clojure-config.el` loaded, add this to your `config.el`:

```elisp
(load! "my-clojure-config")
```

## Project-Specific JDK Configuration

You can specify a JDK version for a specific project by creating a `.java-version` file in the project's root directory. The file should contain just the JDK version number, e.g.:

```
21
```

or

```
24
```

When you open a file in this project:
- The JDK specified in `.java-version` will be used for LSP servers
- The `super-jvm-compile` function will use this JDK for compilation
- CIDER will use this JDK when starting a REPL

If no `.java-version` file is found, the default JDK (currently JDK 21) will be used.

## Managing JDK Installations

To add or modify JDK installations, edit the `my-jdk-paths` variable in `my-jdk-config.el`:

```elisp
(defvar my-jdk-paths
  '((:name "JavaSE-21"
     :path "/path/to/jdk-21"
     :version "21"
     :default t)  ;; Default for LSP servers and most builds
    (:name "JavaSE-24"
     :path "/path/to/jdk-24"
     :version "24"
     :default nil))
  "List of JDK installations available for use by LSP servers and build tools.")
```

For each JDK installation, specify:
- `:name`: A human-readable name for the JDK
- `:path`: The full path to the JDK home directory
- `:version`: The version number (as a string) for the JDK
- `:default`: Set to `t` for the default JDK, `nil` for others

After modifying this list, restart Emacs or evaluate the buffer to apply the changes.

## Using with super-jvm-compile

The `super-jvm-compile` function (bound to `C-c s`) has been enhanced to:

1. Detect the appropriate JDK for the current project
2. Temporarily set JAVA_HOME to the appropriate JDK for compilation
3. Run the appropriate build command (Maven, Gradle, or Mill)
4. Restore the original JAVA_HOME after compilation

The JDK selection logic prioritizes:
1. Build system requirements (e.g., older Gradle versions need JDK 21)
2. Project-specific requirements in `.java-version`
3. The default JDK specified in `my-jdk-paths`

No additional configuration is needed to use this functionality.

