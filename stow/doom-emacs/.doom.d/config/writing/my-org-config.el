;; -*- lexical-binding: t; no-byte-compile: t; -*-

;; Load path utilities
(require 'my-paths)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!

;; Set to the location of your Org files on your local system
(setq org-directory (my/get-path :org))

(require 'org)
(load! "my-org-tools")

(setq org-startup-indented t)

;; Use the deep-nesting aware LaTeX class by default so highly nested
;; lists in Org export without hitting LaTeX's default depth limits.
(setq org-latex-default-class "article-deep")

(add-hook 'org-mode-hook
          #'(lambda ()
              (setq!
                    org-startup-with-inline-images t
                    org-startup-align-all-tables t
                    org-startup-shrink-all-tables t)))

(setq org-use-sub-superscripts '{}
      org-edit-src-content-indentation 2
      org-src-tab-acts-natively t)

;; Keybindings (Doom/Evil friendly)
;;
;; SPC m T x  List → Tabularx table (insert after list)
;; SPC m T h  List → Headings (insert after list)
;; Use C-u before the command to replace the list in-place.
(after! org
  (map! :map org-mode-map
        :localleader
        ;; Use existing tables group on `b` to avoid conflicts with `T`.
        (:prefix ("b" . "tables")
         :desc "List → Tabularx table (C-u: replace)" "x" #'my/org-list-to-tabularx
         :desc "List → Headings (C-u: replace)"       "H" #'my/org-list-to-headings
         :desc "List → Headings (C-u: replace)"       "p" #'my/org-list-to-headings)))

(setq org-latex-packages-alist '(("top=1.5cm, bottom=3cm, left=1.5cm, right=1.5cm" "geometry" nil)
                                 ("" "minted")
                                 ("" "enumitem"))  ; For deep list nesting
      org-latex-caption-above nil
      org-latex-listings 'minted
      org-latex-compiler "xelatex"
      org-latex-hyperref-template "\\hypersetup{\n pdfauthor={%a},\n pdftitle={%t},\n pdfkeywords={%k},\n pdfsubject={%d},\n pdfcreator={%c}, \n pdflang={%L},\n colorlinks=true,\n linkcolor=blue,\n urlcolor=blue,\n citecolor=blue,\n filecolor=blue,\n pdfborder={0 0 0}\n}"
      ;; Default header to handle Unicode and fonts
      org-latex-default-packages-alist '(("AUTO" "inputenc" t ("pdflatex"))
                                         ("T1" "fontenc" t ("pdflatex"))
                                         ("" "graphicx" t)
                                         ("" "longtable" nil)
                                         ("" "wrapfig" nil)
                                         ("" "rotating" nil)
                                         ("normalem" "ulem" t)
                                         ("" "amsmath" t)
                                         ("" "amssymb" t)
                                         ("" "capt-of" nil)
                                         ("" "hyperref" nil))
      ;; Custom header for XeLaTeX Unicode support
      org-latex-inputenc-alist nil
      org-latex-fontenc-alist nil)

;; Use tiny font for minted code blocks (not inline)
;; Note: Org uses \texttt for inline code (~, =) which will pick up the monospaced
;; font via \setmonofont; minted is used for src blocks.
(setq org-latex-minted-options '(("fontsize" "\\footnotesize")
                                 ("breaklines" "true")
                                 ("breakanywhere" "true")
                                 ;; Visual continuation markers
                                 ("breaksymbolleft" "\\textcolor{gray}{\\tiny\\ensuremath{\\hookrightarrow}}")
                                 ("breaksymbolright" "\\textcolor{gray}{\\tiny\\ensuremath{\\hookleftarrow}}")
                                 ("breaksymbolsepleft" "0.25em")
                                 ("breaksymbolsepright" "0.25em")
                                 ("breakindent" "0pt")))

;; Ensure org-latex uses absolute paths for LaTeX tools to avoid PATH issues
(let* ((latexmk (or (executable-find "latexmk")
                    (and (file-exists-p "/Library/TeX/texbin/latexmk")
                         "/Library/TeX/texbin/latexmk")))
       (xelatex (or (executable-find "xelatex")
                    (and (file-exists-p "/Library/TeX/texbin/xelatex")
                         "/Library/TeX/texbin/xelatex")))
       ;; Prefer a TeX bin dir we can prepend to PATH if latexminted isn't found
       (texbin-dir (or (and latexmk (file-name-directory latexmk))
                       (and xelatex (file-name-directory xelatex))
                       "/Library/TeX/texbin")))
  ;; Ensure latexminted (minted v3 helper) is discoverable during shell-escape
  (unless (executable-find "latexminted")
    (when (and (file-directory-p texbin-dir)
               (not (member texbin-dir exec-path)))
      (setenv "PATH" (concat texbin-dir ":" (getenv "PATH")))
      (add-to-list 'exec-path texbin-dir)))
  (when (and latexmk xelatex)
    ;; Use -pdf with an explicit -pdflatex pointing to xelatex with required flags.
    ;; Keep Org placeholders as single % (escaped as %% for format), and use
    ;; latexmk placeholders %O and %S (also escaped for format).
    (setq org-latex-pdf-process
          (list (format "\"%s\" -pdf -pdflatex=\"%s -interaction=nonstopmode -shell-escape %%%%O %%%%S\" -output-directory=%%o %%f"
                        latexmk
                        xelatex)))))

(with-eval-after-load 'ox-latex
  ;; Custom article class with deep nesting support
  (add-to-list 'org-latex-classes
               '("scrartcl" "\\documentclass{scrartcl}
% Deep nesting configuration
\\usepackage{fontspec}
% Enable ligatures globally for fontspec-aware fonts
\\defaultfontfeatures{Ligatures={TeX,Common,Contextual}}
% Text font: MonoLisaVariable Nerd Font (variable) for main/sans
% Define NFSS shapes using variable weight axis so \bfseries selects true bold
\\setmainfont{MonoLisa Nerd Font}[
  FontFace = {m}{n}{MonoLisa Nerd Font},
  FontFace = {b}{n}{MonoLisa Nerd Font Bold},
  FontFace = {m}{it}{MonoLisa Nerd Font Italic},
  FontFace = {b}{it}{MonoLisa Nerd Font Bold Italic}
]
\\setsansfont{MonoLisa Nerd Font}[
  FontFace = {m}{n}{MonoLisa Nerd Font},
  FontFace = {b}{n}{MonoLisa Nerd Font Bold},
  FontFace = {m}{it}{MonoLisa Nerd Font Italic},
  FontFace = {b}{it}{MonoLisa Nerd Font Bold Italic}
]
% Code font: PragmataPro Mono Liga for monospaced (inline/src blocks)
\\setmonofont{PragmataPro Mono Liga}
% Ensure minted v3 helper is found even if PATH is sanitized
\\AtBeginDocument{\\makeatletter\\edef\\MintedExecutable{\\detokenize{/Library/TeX/texbin/latexminted}}\\makeatother}
\\usepackage{enumitem}
\\setlistdepth{20}
\\renewlist{enumerate}{enumerate}{20}
\\renewlist{itemize}{itemize}{20}
% Configure each level
\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\arabic*.}
\\setlist[enumerate,5]{label=\\alph*.}
\\setlist[enumerate,6]{label=\\roman*.}
\\setlist[enumerate,7]{label=\\arabic*.}
\\setlist[enumerate,8]{label=\\alph*.}
% Continue pattern for deeper levels
\\setlist[itemize,1]{label=\\textbullet}
\\setlist[itemize,2]{label=--}
\\setlist[itemize,3]{label=*}
\\setlist[itemize,4]{label=\\textbullet}
\\setlist[itemize,5]{label=--}
\\setlist[itemize,6]{label=*}
\\setlist[itemize,7]{label=\\textbullet}
\\setlist[itemize,8]{label=--}"
                 ("\\section{%s}" . "\\section*{%s}")
                 ("\\subsection{%s}" . "\\subsection*{%s}")
                 ("\\subsubsection{%s}" . "\\subsubsection*{%s}")
                 ("\\paragraph{%s}" . "\\paragraph*{%s}")
                 ("\\subparagraph{%s}" . "\\subparagraph*{%s}")))

  ;; Also configure default article class with deep nesting
  (add-to-list 'org-latex-classes
               '("article-deep" "\\documentclass{article}
% Deep nesting configuration
\\usepackage{fontspec}
% Enable ligatures globally for fontspec-aware fonts
\\defaultfontfeatures{Ligatures={TeX,Common,Contextual}}
% Text font: MonoLisaVariable Nerd Font (variable) for main/sans
% Define NFSS shapes using variable weight axis so \bfseries selects true bold
\\setmainfont{MonoLisa Nerd Font}[
  FontFace = {m}{n}{MonoLisa Nerd Font},
  FontFace = {b}{n}{MonoLisa Nerd Font Bold},
  FontFace = {m}{it}{MonoLisa Nerd Font Italic},
  FontFace = {b}{it}{MonoLisa Nerd Font Bold Italic}
]
\\setsansfont{MonoLisa Nerd Font}[
  FontFace = {m}{n}{MonoLisa Nerd Font},
  FontFace = {b}{n}{MonoLisa Nerd Font Bold},
  FontFace = {m}{it}{MonoLisa Nerd Font Italic},
  FontFace = {b}{it}{MonoLisa Nerd Font Bold Italic}
]
% Code font: PragmataPro Mono Liga for monospaced (inline/src blocks)
\\setmonofont{PragmataPro Mono Liga}
% Ensure minted v3 helper is found even if PATH is sanitized
\\AtBeginDocument{\\makeatletter\\edef\\MintedExecutable{\\detokenize{/Library/TeX/texbin/latexminted}}\\makeatother}
\\usepackage{enumitem}
\\setlistdepth{20}
\\renewlist{enumerate}{enumerate}{20}
\\renewlist{itemize}{itemize}{20}
% Configure each level
\\setlist[enumerate,1]{label=\\arabic*.}
\\setlist[enumerate,2]{label=\\alph*.}
\\setlist[enumerate,3]{label=\\roman*.}
\\setlist[enumerate,4]{label=\\arabic*.}
\\setlist[enumerate,5]{label=\\alph*.}
\\setlist[enumerate,6]{label=\\roman*.}
\\setlist[enumerate,7]{label=\\arabic*.}
\\setlist[enumerate,8]{label=\\alph*.}
% Continue pattern for deeper levels
\\setlist[itemize,1]{label=\\textbullet}
\\setlist[itemize,2]{label=--}
\\setlist[itemize,3]{label=*}
\\setlist[itemize,4]{label=\\textbullet}
\\setlist[itemize,5]{label=--}
\\setlist[itemize,6]{label=*}
\\setlist[itemize,7]{label=\\textbullet}
\\setlist[itemize,8]{label=--}"
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
      (python . t)       ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-python.html
      (rust . t)         ;; https://github.com/emacs-rustic/rustic?tab=readme-ov-file#org-babel
      (shell . t)        ;; https://orgmode.org/worg/org-contrib/babel/languages/ob-doc-shell.html
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
