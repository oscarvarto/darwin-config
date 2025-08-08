;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; Load path utilities
(require 'my-paths)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!

;; Set to the location of your Org files on your local system
(setq org-directory (my/get-path :org))
;; Set to the name of the file where new notes will be stored
(setq org-mobile-inbox-for-pull (expand-file-name "flagged.org" (my/get-path :org)))
;; Set to <your Dropbox root directory>/MobileOrg.
(setq org-mobile-directory (my/get-path :mobileorg))

(require 'org)

(setq org-startup-indented t)

(add-hook 'org-mode-hook
          #'(lambda ()
              (setq!
                    org-startup-with-inline-images t
                    org-startup-align-all-tables t
                    org-startup-shrink-all-tables t)))

(setq org-use-sub-superscripts '{}
      org-edit-src-content-indentation 2
      org-src-tab-acts-natively t)

(setq org-latex-packages-alist '(("top=1.5cm, bottom=3cm, left=1.5cm, right=1.5cm" "geometry" nil)
                                 ("" "minted"))
      org-latex-caption-above nil
      org-latex-listings 'minted
      org-latex-hyperref-template "\\hypersetup{\n pdfauthor={%a},\n pdftitle={%t},\n pdfkeywords={%k},\n pdfsubject={%d},\n pdfcreator={%c}, \n pdflang={%L},\n colorlinks=true,\n linkcolor=blue,\n urlcolor=blue,\n citecolor=blue,\n filecolor=blue,\n pdfborder={0 0 0}\n}"
      org-latex-pdf-process '("latexmk -xelatex -shell-escape -interaction=nonstopmode -output-directory=%o %f"))

(with-eval-after-load 'ox-latex
  (add-to-list 'org-latex-classes
               '("scrartcl" "\\documentclass{scrartcl}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}"))))

(require 'clojure-mode)

(require 'ob-clojure)

(setq org-babel-clojure-backend 'cider)
(require 'cider)

(require 'ob-java)

(nconc org-babel-default-header-args:java
       '((:dir . nil)
         (:results . value)))

(setq ob-mermaid-cli-path (my/get-path :mmdc))
(org-babel-do-load-languages
    'org-babel-load-languages
    '((clojure . t)      ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-clojure.html
      (emacs-lisp . t)   ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-elisp.html
      (java . t)         ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-java.html
      (mermaid . t)      ;; https://github.com/arnm/ob-mermaid
      (nushell . t)      ;; https://github.com/ln-nl/ob-nushell
      ;; (python . t)       ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-python.html
      (rust . t)         ;; https://github.com/emacs-rustic/rustic?tab=readme-ov-file#org-babel
      (shell . t)        ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-shell.html
      ;; (scala-cli . t) ;; https://github.com/ag91/scala-cli-repl
      (sql . t)          ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-sql.html
      (sqlite . t)       ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-sqlite.html
      (verb . t)))


;; Add frame borders and window dividers
(modify-all-frames-parameters
 '((right-divider-width . 40)
   (internal-border-width . 40)))
(dolist (face '(window-divider
                window-divider-first-pixel
                window-divider-last-pixel))
  (face-spec-reset-face face)
  (set-face-foreground face (face-attribute 'default :background)))
(set-face-background 'fringe (face-attribute 'default :background))

;; org-modern
(setq
 ;; Edit settings
 org-auto-align-tags nil
 org-tags-column 0
 org-catch-invisible-edits 'smart
 org-special-ctrl-a/e t
 org-insert-heading-respect-content t

 ;; https://github.com/minad/org-modern/discussions/227
 org-modern-star 'replace

 ;; Org styling, hide markup etc.
 org-modern-table t
 org-hide-emphasis-markers t
 org-pretty-entities t

 ;; Agenda styling
 org-agenda-tags-column 0
 org-agenda-block-separator ?─
 org-agenda-time-grid
 '((daily today require-timed)
   (800 1000 1200 1400 1600 1800 2000)
   " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
 org-agenda-current-time-string
 "◀── now ─────────────────────────────────────────────────")

;; Ellipsis styling
(setq org-ellipsis "…")
(set-face-attribute 'org-ellipsis nil :inherit 'default :box nil)
(global-org-modern-mode)

(use-package org-modern-indent
  :config ; add late to hook
  (add-hook 'org-mode-hook #'org-modern-indent-mode 90))

(use-package ox-hugo
  :after ox)

(use-package verb
  :config
  (setq verb-suppress-load-unsecure-prelude-warning t))

(provide 'my-org-config)
