;;; my-jvm-navigation-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Author: Oscar Vargas Torres <oscarvarto@protonmail.com>

;;; Commentary:
;; Functions for navigating across mixed JVM language codebases (Java, Scala, Clojure)
;; These functions handle name mangling patterns and provide enhanced search capabilities

;;; Code:

(after! (:any java-mode scala-mode groovy-mode clojure-mode)
  (require 'consult)

  (require 'projectile)

  (require 'vertico)

  (defun my-jvm-demangle-name (mangled-name)
    "Convert a mangled JVM name to its likely source form.
For example, 'com.example.M$Person' becomes ('M' 'Person') or ('com.example.M' 'Person').
Also handles Clojure constructor notation with trailing dot, e.g., 'M$Person.'."
    (when mangled-name
      ;; Remove trailing dot from Clojure constructor invocation syntax (e.g., "M$Person.")
      (let ((cleaned-name (if (string-match "\\(.*\\)\\.$" mangled-name)
                              (match-string 1 mangled-name)
                            mangled-name)))
        (if (string-match "\\([^$]+\\)\\$\\([^$]+\\)" cleaned-name)
            (let ((outer-class (match-string 1 cleaned-name))
                  (inner-class (match-string 2 cleaned-name)))
              (cons outer-class inner-class))
          (cons cleaned-name nil)))))

  (defun my-jvm-find-definition-at-point ()
    "Find definition of JVM symbol at point, handling cross-language references.
This works with mangled names like 'M$Person' or Clojure constructor calls like 'M$Person.'
to find their definitions in Scala/Java source files."
    (interactive)
    (let* ((symbol-at-point (thing-at-point 'symbol t))
           ;; Handle special case for Clojure constructor calls where the dot might be separated
           ;; For example, when point is on "M$Person" in "(M$Person. args)"
           (symbol-with-context (when symbol-at-point
                                  (save-excursion
                                    (let ((end (point)))
                                      (forward-symbol 1)
                                      (when (looking-at "\\.")
                                        (concat symbol-at-point "."))))))
           (effective-symbol (or symbol-with-context symbol-at-point))
           (demangled-parts (my-jvm-demangle-name effective-symbol)))
      (if demangled-parts
          (my-jvm-search-definition (car demangled-parts) (cdr demangled-parts))
        (message "No symbol at point or not a valid JVM symbol"))))

  (defun my-jvm-search-definition (outer-name inner-name)
    "Search for definition of a JVM class across language boundaries.
OUTER-NAME is the container class/object name (e.g., 'M' or 'com.example.M').
INNER-NAME is the inner class/trait name (e.g., 'Person')."
    (let* ((project-root (projectile-project-root))
           (simple-outer-name (car (last (split-string outer-name "\\."))))
           ;; Potential patterns to search for:
           (patterns
            (delq nil
                  (list
                   ;; Scala 3 - object with colon followed by indented case class
                   (when inner-name
                     (format "object\\s+%s:\\s*(?:[^\n]*\n\\s+)(?:.*\n\\s+)*?case\\s+class\\s+%s\\b"
                             simple-outer-name inner-name))
                   ;; Scala 3 - Export pattern
                   (format "export\\s+%s\\.\\*" simple-outer-name)
                   ;; Scala 3 - object with colon
                   (format "\\bobject\\s+%s:" simple-outer-name)
                   ;; Scala 2/3 - case class inside object (traditional)
                   (when inner-name
                     (format "\\bcase\\s+class\\s+%s\\b" inner-name))
                   ;; Scala 2/3 - class inside object
                   (when inner-name
                     (format "\\bclass\\s+%s\\b" inner-name))
                   ;; Scala 2/3 - trait inside object
                   (when inner-name
                     (format "\\btrait\\s+%s\\b" inner-name))
                   ;; Scala 2 - object definition with braces
                   (format "\\bobject\\s+%s\\s*\\{" simple-outer-name)
                   ;; Java class
                   (format "\\bclass\\s+%s\\b"
                           (if inner-name
                               (concat simple-outer-name "." inner-name)
                             simple-outer-name))
                   ;; Fallback
                   (if inner-name
                       (concat "\\b" inner-name "\\b")
                     (concat "\\b" simple-outer-name "\\b"))))))
      (if (and project-root patterns)
          (consult-ripgrep project-root (string-join patterns "\\|"))
        (message "Could not determine project root or search patterns"))))

  (defun my-jvm-search-symbol ()
    "Search for a JVM symbol across language boundaries.
Prompts for symbol name and searches across Java, Scala, and Clojure files.
Handles both standard JVM names (e.g., 'M$Person') and Clojure constructor calls (e.g., 'M$Person.')."
    (interactive)
    (let* ((symbol (read-string "Search for JVM symbol: "))
           (demangled-parts (my-jvm-demangle-name symbol)))
      (if demangled-parts
          (my-jvm-search-definition (car demangled-parts) (cdr demangled-parts))
        (consult-ripgrep (projectile-project-root) symbol))))

  (defun my-jvm-find-source-file ()
    "Find a source file in the current JVM project.
Searches across Java, Scala, and Clojure files."
    (interactive)
    (let ((file-pattern "\\.(java|scala|clj|cljs|cljc)$"))
      (consult-find (projectile-project-root) file-pattern)))

  ;; Enhanced version that detects specific patterns for different JVM languages

  (defun my-jvm-search-by-language ()
    "Search for symbols with language-specific patterns.
Allows selecting which language pattern to search with."
    (interactive)
    (let* ((lang-patterns '(("Scala 3 Object" . "object\\s+([A-Za-z0-9_]+):")
                            ("Scala 2 Object" . "object\\s+([A-Za-z0-9_]+)\\s*\\{")
                            ("Scala Class" . "class\\s+([A-Za-z0-9_]+)")
                            ("Scala Case Class" . "case\\s+class\\s+([A-Za-z0-9_]+)")
                            ("Scala Trait" . "trait\\s+([A-Za-z0-9_]+)")
                            ("Scala Export" . "export\\s+([A-Za-z0-9_]+)\\.\\*")
                            ("Java Class" . "class\\s+([A-Za-z0-9_]+)")
                            ("Java Interface" . "interface\\s+([A-Za-z0-9_]+)")
                            ("Clojure Namespace" . "\\(ns\\s+([A-Za-z0-9_.\\-]+)")
                            ("Clojure Function" . "\\(defn\\s+([A-Za-z0-9_\\-!?]+)")))
           (selected (completing-read "Search pattern: " lang-patterns nil t))
           (pattern (cdr (assoc selected lang-patterns))))
      (consult-ripgrep (projectile-project-root) pattern)))

  ;; Key bindings for JVM navigation functions
  (map! :map prog-mode-map
        :desc "Find JVM definition at point" "C-c j d" #'my-jvm-find-definition-at-point
        :desc "Search for JVM symbol" "C-c j s" #'my-jvm-search-symbol
        :desc "Find JVM source file" "C-c j f" #'my-jvm-find-source-file
        :desc "Search by JVM language pattern" "C-c j p" #'my-jvm-search-by-language)

  ;; Special key binding for Java, Scala, and Clojure modes to override go-to-definition
  (map! :map (java-mode-map scala-mode-map scala-ts-mode-map clojure-mode-map)
        :desc "Find definition (JVM-aware)" "C-c g" #'my-jvm-find-definition-at-point)

  ;; Doom-specific leader key bindings
  (map! :leader
        (:prefix ("j" . "JVM navigation")
         :desc "Find definition at point" "d" #'my-jvm-find-definition-at-point
         :desc "Search for JVM symbol" "s" #'my-jvm-search-symbol
         :desc "Find JVM source file" "f" #'my-jvm-find-source-file
         :desc "Search by language pattern" "p" #'my-jvm-search-by-language)))

;; Example usages:
;; - M$Person -> Finds definition of Person inside object M
;; - M$Person. -> Also finds definition of Person inside object M (Clojure constructor)
;; - com.example.M$Address -> Finds definition of Address inside object M in package com.example
;; - com.example.M$Address. -> Same as above, with Clojure constructor syntax
;;
;; Notes on Scala 3 support:
;; - Handles Scala 3 object definitions with colon syntax: `object M:`
;; - Supports finding case classes inside Scala 3 objects with proper indentation
;; - Recognizes Scala 3 `export M.*` syntax

(provide 'my-jvm-navigation-config)

;;; my-jvm-navigation-config.el ends here
