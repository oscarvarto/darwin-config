;;; my-consult-omni-config.el -*- lexical-binding: t; no-byte-compile: t; -*-
(require 'consult)

(require 'my-auth-helpers) ; For my/get-secret

(use-package consult-notes
  :commands (consult-notes
             consult-notes-search-in-all-notes
             ;; if using org-roam 
             consult-notes-org-roam-find-node
             consult-notes-org-roam-find-node-relation)
  :config
  (setq consult-notes-file-dir-sources '(("Org" ?o  "~/org/"))) ;; Set notes dir(s), see below
  ;; search only for text files in denote dir
  (setq consult-notes-denote-files-function (function denote-directory-text-only-files)))

(setq yequake-frames
      '(("yequake-omni" .
         ((width . 0.8)
          (height . 0.8)
          ;;(alpha . 0.9)
          (top . 0.0)
          ;;(left . 0.15)
          (buffer-fns . #'comsult-omni-multi)
                        ;; ("~/org/notes.org"
                         ;;split-window-horizontally
                         ;;"*scratch*"
                         
          (frame-parameters . ((minibuffer . t)
                               (autoraise . t)
                               (window-system . ns)))))))
                               ;;(undecorated . t)
                               

(use-package consult-omni
  :after consult
  :custom

  ;;; General settings that apply to all sources

  (consult-omni-show-preview t) ;;; show previews
  (consult-omni-preview-key "C-o") ;;; set the preview key to C-o
  (consult-omni-highlight-matches-in-minibuffer t) ;;; highlight matches in minibuffer
  (consult-omni-highlight-matches-in-file t) ;;; highlight matches in files
  (consult-omni-default-count 5) ;;; set default count
  (consult-omni-default-page 0) ;;; set the default page (default is 0 for the first page)

  ;; optionally change the consult-omni debounce, throttle and delay.
  ;; Adjust these (e.g. increase to avoid hiting a source (e.g. an API) too frequently)
  (consult-omni-dynamic-input-debounce 0.8)
  (consult-omni-dynamic-input-throttle 1.6)
  (consult-omni-dynamic-refresh-delay 0.8)

  ;; Optionally set backend for http request (either 'url, 'request, or 'plz)
  (consult-omni-http-retrieve-backend 'plz)

  :config

  ;;; Load Sources Core code
  (require 'consult-omni-sources)

  ;;; Load Embark Actions
  (require 'consult-omni-embark)

  ;;; Either load all source modules or a selected list
  ;; Select a list of modules you want to aload, otherwise all sources all laoded
  (setq consult-omni-sources-modules-to-load (list  'consult-omni-apps
                                                    'consult-omni-brave-autosuggest
                                                    'consult-omni-brave
                                                    'consult-omni-browser-history
                                                    'consult-omni-buffer
                                                    'consult-omni-calc
                                                    'consult-omni-consult-notes
                                                    'consult-omni-dict
                                                    'consult-omni-fd
                                                    'consult-omni-find
                                                    'consult-omni-gh
                                                    'consult-omni-git-grep
                                                    'consult-omni-gptel
                                                    'consult-omni-grep
                                                    'consult-omni-invidious
                                                    'consult-omni-line-multi
                                                    'consult-omni-locate
                                                    'consult-omni-man
                                                    'consult-omni-mdfind
                                                    'consult-omni-notes
                                                    'consult-omni-org-agenda
                                                    'consult-omni-ripgrep
                                                    'consult-omni-ripgrep-all
                                                    'consult-omni-stackoverflow
                                                    'consult-omni-wikipedia
                                                    'consult-omni-youtube))
  (consult-omni-sources-load-modules)

  ;; set multiple sources for consult-omni-multi command. Change these lists as needed for different interactive commands. Keep in mind that each source has to be a key in `consult-omni-sources-alist'.
  (setq consult-omni-multi-sources '("calc"
                                     "File"
                                     "Buffer"
                                     "Bookmark"
                                     "Apps"
                                     "gptel"
                                     "Brave"
                                     "Dictionary"
                                     "Wikipedia"
                                     "Notes Search"
                                     "Org Agenda"
                                     "GitHub"
                                     "Invidious"))
                                     

  ;;; Per source customization

  ;; Set API KEYs. Retrieve securely.
  ;; Assumes 1Password item "brave-search-api" exists with field "api-key".
  (setq consult-omni-source-brave-api-key (my/get-secret :op-item "brave-search-api" :op-field "api-key"))

  ;; gptel settings
  (setq consult-omni-gptel-cand-title #'consult-omni--gptel-make-title-short-answer)

  ;; default terminal
  (setq consult-omni-embark-default-term #'vterm)

  ;; default video player
  (setq consult-omni-embark-video-default-player  #'mpv-play-url)

  ;; pretty prompt for launcher
  (setq consult-omni-open-with-prompt "  ")

  ;;; Pick you favorite autosuggest command.
  (setq consult-omni-default-autosuggest-command #'consult-omni-dynamic-brave-autosuggest) ;;or any other autosuggest source you define

  ;;; Set your shorthand favorite interactive command
  (setq consult-omni-default-interactive-command #'consult-omni-multi)

  ;;; Optionally Set back-end for notes search to ripgrep-all (requires ripgrep-all)
  (setq consult-omni-notes-backend-command "rga")

  ;;; Optionally add more interactive commands

  ;; consult-omni-web

  (defvar consult-omni-web-sources (list "Brave"
                                         "gptel"
                                         "Wikipedia"
                                         "GitHub"
                                         "Invidious"))
                                         
  (defun consult-omni-web (&optional initial prompt sources no-callback &rest args)
    "Interactive web search”

This is similar to `consult-omni-multi', but runs the search on
web sources defined in `consult-omni-web-sources'.
See `consult-omni-multi' for more details.
"
    (interactive "P")
    (let ((prompt (or prompt (concat "[" (propertize "consult-omni-web" 'face 'consult-omni-prompt-face) "]" " Search:  ")))
          (sources (or sources consult-omni-web-sources)))
      (consult-omni-multi initial prompt sources no-callback args)))

  ;; consult-omni-local

  (defvar consult-omni-local-sources (list "ripgrep"
                                           "mdfind"
                                           "Notes Search"
                                           "Apps"
                                           "Org Agenda"))

  (defun consult-omni-local (&optional initial prompt sources no-callback &rest args)
    "Interactive local search”

This is similar to `consult-omni-multi', but runs the search on
local sources defined in `consult-omni-local-sources'.
See `consult-omni-multi' for more details.
"
    (interactive "P")
    (let ((prompt (or prompt (concat "[" (propertize "consult-omni-local" 'face 'consult-omni-prompt-face) "]" " Search:  ")))
          (sources (or sources consult-omni-local-sources)))
      (consult-omni-multi initial prompt sources no-callback args)))

  (setq consult-omni-default-search-engine "Brave")

  ;; AutoSuggest at point

  (defun consult-omni-autosuggest-at-point ()
   (interactive)
   (let ((input (or (thing-at-point 'url) (thing-at-point 'filename) (thing-at-point 'symbol) (thing-at-point 'sexp) (thing-at-point 'word))))
     (when (and (minibuffer-window-active-p (selected-window))
                (equal (substring input 0 1) (consult--async-split-initial nil)))
       (setq input (substring input 1)))
     (consult-omni-brave-autosuggest input))))

  ;; Key bindings
  ;; Suggestion:
  ;; "M-" keys for changing sources, queries, ...
  ;; "C-" keys for interaction with candidates ...
  ;; "s-" keys for completion
  

;; Set global keybindings for `consult-omni'.
(map! :leader
      (:prefix-map ("\\" . "consult-omni")
       :desc "Fd"    "f" #'consult-omni-fd
       :desc "Brave" "b" #'consult-omni-brave
       :desc "Gptel" "g" #'consult-omni-gptel))

(use-package! consult-gh
    :after consult)

(setq consult-omni-default-count 10)
