;; -*- lexical-binding: t; no-byte-compile: t; -*-
;;; $DOOMDIR/packages.el

;; To install a package with Doom you must declare them here and run 'doom sync'
;; on the command line, then restart Emacs for the changes to take effect -- or
;; use 'M-x doom/reload'.
;; (straight-use-package 'use-package)

;; To install SOME-PACKAGE from MELPA, ELPA or emacsmirror:
;; (package! some-package)
(package! 1passel
  :recipe (:host github
           :repo "vinid/1passel"))
(package! catppuccin-theme)
(package! cider
  :recipe (:host github
           :repo "clojure-emacs/cider"
           :files (:defaults "*.el")
           :depth 1))
(package! centered-cursor-mode)
(package! claude-code-ide
  :recipe (:host github
           :repo "manzaltu/claude-code-ide.el"
           :depth 1))
(package! clomacs)
(package! combobulate)
(package! dash)
(package! diminish)
(package! eat
  :recipe (:host codeberg
           :repo "akib/emacs-eat"
           :files ("*.el" ("term" "term/*.el") "*.texi"
                   "*.ti" ("terminfo/e" "terminfo/e/*")
                   ("terminfo/65" "terminfo/65/*")
                   ("integration" "integration/*")
                   (:exclude ".dir-locals.el" "*-tests.el"))))
(package! ejc-sql
  :recipe (:host github
           :repo "kostafey/ejc-sql"
           :depth 1))
(package! eldoc :built-in t
  :recipe (:host github
           :repo "casouri/eldoc-box"
           :depth 1))
(package! ement)
(package! envrc)
(package! eterm-256color)
(package! f)
(package! flycheck-rust)
(package! ffmpeg-player)
(package! gnuplot)
(package! gptel-autocomplete
  :recipe (:host github
           :repo "JDNdeveloper/gptel-autocomplete"
           :depth 1))
(package! hydra)
(package! idle-highlight-mode
  :recipe (:host github
           :repo "nonsequitur/idle-highlight-mode"))
(package! image-roll :recipe
  (:host github
   :repo "dalanicolai/image-roll.el"))
(package! impostman
  :recipe (:host github
           :repo "flashcode/impostman"))
(package! indent-bars)
(package! inheritenv)
(package! ligature
  :recipe (:host github
           :repo "mickeynp/ligature.el"
           :depth 1))
(package! line-reminder)
(package! mermaid-mode)
(package! mise)
(package! modus-themes)
(package! nix-mode)
(package! nushell-mode
  :recipe (:host github
           :repo "mrkkrp/nushell-mode"))
(package! ob-mermaid)
(package! obsidian)
(package! org-modern)
(package! org-modern-indent
  :recipe (:host github
           :repo "jdtsmith/org-modern-indent"
           :depth 1))
(package! ob-nushell
  :recipe (:host github
           :repo "ln-nl/ob-nushell"
           :files ("*.el")))
(package! org-ref)
(package! ox-gfm)
(package! ox-hugo)
(package! parseedn)
(package! pdf-tools :recipe
  (:host github
   :repo "dalanicolai/pdf-tools"
   :branch "pdf-roll"
   :files ("lisp/*.el"
           "README"
           ("build" "Makefile")
           ("build" "server")
           (:exclude "lisp/tablist.el" "lisp/tablist-filter.el"))))
(package! pinentry)
(package! plz)
(package! prettier)
(package! rainbow-csv
  :recipe (:host github
           :repo "emacs-vs/rainbow-csv"
           :depth 1))
(package! rainbow-delimiters)
(package! repeat)
(package! ripgrep)
(package! rustic :recipe (:repo "emacs-rustic/rustic"))
(package! s)
(package! saveplace-pdf-view)
(package! shackle)
(package! tabnine)
(package! track-changes :built-in t)
(package! verb
  :recipe (:host github
           :repo "federicotdn/verb"))
(package! vterm)
(package! yasnippet-snippets)
(package! zoxide)

;; To install a package directly from a remote git repo, you must specify a
;; `:recipe'. You'll find documentation on what `:recipe' accepts here:
;; https://github.com/radian-software/straight.el#the-recipe-format
;; (package! another-package
;;   :recipe (:host github :repo "username/repo"))

;; If the package you are trying to install does not contain a PACKAGENAME.el
;; file, or is located in a subdirectory of the repo, you'll need to specify
;; `:files' in the `:recipe':
;; (package! this-package
;;   :recipe (:host github :repo "username/repo"
;;            :files ("some-file.el" "src/lisp/*.el")))

;; If you'd like to disable a package included with Doom, you can do so here
;; with the `:disable' property:
;; (package! builtin-package :disable t)
;; (package! mu4e-alert :disable t)
;; (package! ns-auto-titlebar :disable t)
;; (package! projectile :disable t)
;; (package! tree-sitter-indent :disable t)
;; (package! kkp :disable t)

;; You can override the recipe of a built in package without having to specify
;; all the properties for `:recipe'. These will inherit the rest of its recipe
;; from Doom or MELPA/ELPA/Emacsmirror:
;; (package! builtin-package :recipe (:nonrecursive t))
;; (package! builtin-package-2 :recipe (:repo "myfork/package"))


;; Specify a `:branch' to install a package from a particular branch or tag.
;; This is required for some packages whose default branch isn't 'master' (which
;; our package manager can't deal with; see radian-software/straight.el#279)
;; (package! builtin-package :recipe (:branch "develop"))

;; Use `:pin' to specify a particular commit to install.
;; (package! builtin-package :pin "1a2b3c4d5e")

;; Doom's packages are pinned to a specific commit and updated from release to
;; release. The `unpin!' macro allows you to unpin single packages...
;; (unpin! pinned-package)
;; ...or multiple packages
;; (unpin! pinned-package another-pinned-package)
;; ...Or *all* packages (NOT RECOMMENDED; will likely break things)
;; (unpin! t) ; Commented out as it's dangerous and can cause instability
