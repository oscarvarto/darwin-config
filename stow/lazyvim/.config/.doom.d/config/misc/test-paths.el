;;; test-paths.el --- Test path utilities for Doom Emacs config -*- lexical-binding: t; no-byte-compile: t; -*-

;; This script tests the path utilities in my-paths.el to ensure they correctly
;; expand and normalize paths across different platforms.

;; Load the path utilities
(load-file "my-paths.el")

;; Setup testing output

(defun print-section-header (title)
  (message "\n=== %s ===\n" title))

(defun test-path (description path-or-fn)
  (message "%-30s: %s" 
          description
          (if (functionp path-or-fn)
              (funcall path-or-fn)
            path-or-fn)))

;; Print platform information
(print-section-header "Platform Information")
(test-path "Current platform" my/platform)
(test-path "Path separator" my/path-separator)
(test-path "Home directory" (getenv "HOME"))

;; Test basic path expansion
(print-section-header "Basic Path Expansion")
(test-path "Expand ~/test" (my/expand-home-path "test"))
(test-path "Expand ~/Documents" (my/expand-home-path "Documents"))
(test-path "Join path components" (my/join-path "folder1" "folder2" "file.txt"))

;; Test pre-configured paths
(print-section-header "Pre-configured Paths")
(test-path "Env file path" (my/get-path :env))
(test-path "Dropbox path" (my/get-path :dropbox))
(test-path "OneDrive path" (my/get-path :onedrive))
(test-path "JDKs base path" (my/get-path :jdks))
(test-path "mmdc executable" (my/get-path :mmdc))
(test-path "Org directory" (my/get-path :org))
(test-path "MobileOrg directory" (my/get-path :mobileorg))

;; Test normalize path function
(print-section-header "Path Normalization")
(let ((mixed-path "folder1/folder2\\folder3/file.txt"))
  (test-path "Original mixed path" mixed-path)
  (test-path "Normalized for platform" (my/normalize-path mixed-path)))

;; Test executable finding
(print-section-header "Executable Finding")
(test-path "Find git executable" (my/find-executable "git"))
(test-path "Find multiple possibilities" (my/find-executable '("nonexistent" "git" "ls")))

;; Done
(message "\nPath utility tests completed. Review the output above to verify paths are correctly resolved.")

