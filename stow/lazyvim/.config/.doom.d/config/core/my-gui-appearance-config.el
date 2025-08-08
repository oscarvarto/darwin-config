;;; my-gui-appearance-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Variables to track current configuration state
(defvar my/current-font-config 'monolisa
  "Stores the currently loaded font configuration ('pragmatapro or 'monolisa).")

(defvar my/light-theme 'modus-operandi-deuteranopia
  "The light theme to use.")

(defvar my/dark-theme 'modus-vivendi-deuteranopia
  "The dark theme to use.")

;; Function to determine if a theme is light or dark
(defun my/theme-is-light-p (theme)
  "Return t if THEME is a light theme."
  (eq theme my/light-theme))

(load! "pragmatapro-lig")

(defun turn-on-pragmatapro-lig-mode ()
  "Enable pragmatapro-lig-mode for the current buffer."
  (interactive)
  (when (not (minibufferp))
    (ligature-mode -1)
    (pragmatapro-lig-mode 1)))

(defun turn-off-pragmatapro-lig-mode ()
  "Enable pragmatapro-lig-mode for the current buffer."
  (interactive)
  (ligature-mode +1)
  (pragmatapro-lig-mode -1))

(defun delayed-turn-on-pragmatapro-lig-mode ()
  "Enable pragmatapro-lig-mode after a short delay."
  (run-with-timer 1.0 nil #'turn-on-pragmatapro-lig-mode))

(defun enable-pragmatapro-lig-hooks (&optional _)
  "Enable `pragmatapro-lig'"
  (add-hook! '(text-mode-hook
               org-mode-hook
               ;; vterm-mode-hook
               prog-mode-hook)
             #'delayed-turn-on-pragmatapro-lig-mode))

(defun disable-pragmatapro-lig-hooks (&optional _)
  "Disable `pragmatapro-lig'"
  (remove-hook! '(text-mode-hook
                  org-mode-hook
                  ;;vterm-mode-hook
                  prog-mode-hook)
    #'delayed-turn-on-pragmatapro-lig-mode))

;; Function to load font configuration
(defun my/load-font-config (font-type)
  "Load the specified font configuration FONT-TYPE ('pragmatapro or 'monolisa)."
  (when (not (eq my/current-font-config font-type))
    (message "Loading %s font configuration" font-type)

    ;; Load the appropriate configuration
    (cond
     ((eq font-type 'monolisa)
      ;; Load MonoLisa configuration
      (my/load-monolisa-font-config))
     ((eq font-type 'pragmatapro)
      ;; Load PragmataPro configuration
      (my/load-pragmatapro-font-config)))
    (setq my/current-font-config font-type)))

;; Function to load MonoLisa font configuration
(defun my/load-monolisa-font-config ()
  "Load the MonoLisa font configuration."
  ;; Font configuration
  (setq doom-font (font-spec :family "MonoLisaVariable Nerd Font" :size 16 :weight 'regular)
        doom-variable-pitch-font (font-spec :family "MonoLisaVariable Nerd Font" :size 16 :weight 'regular)
        doom-symbol-font (font-spec :family "MonoLisaVariable Nerd Font" :size 16 :weight 'regular))

  (turn-off-pragmatapro-lig-mode) ;; implies (ligature-mode-turn-on)
  (disable-pragmatapro-lig-hooks)
  ;; Enable ligature mode
  (set-font-ligatures! 'eww-mode "ff" "fi" "ffi")

  ;; MonoLisa ligatures
  (set-font-ligatures! '(prog-mode text-mode org-mode doom-docs-mode markdown-mode) nil)
  (set-font-ligatures! '(prog-mode text-mode org-mode doom-docs-mode markdown-mode)
    ;; coding ligatures
    "<!---" "--->" "|||>" "<!--" "<|||" "<==>" "-->" "->>" "-<<" "..=" "!=="
    "#_(" "/==" "||>" "||=" "|->" "===" "==>" "=>>" "=<<" "=/=" ">->" ">=>"
    ">>-" ">>=" "<--" "<->" "<-<" "<||" "<|>" "<=" "<==" "<=>" "<=<" "<<-"
    "<<=" "<~>" "<~~" "~~>" ">&-" "<&-" "&>>" "&>" "->" "-<" "-~" ".=" "!="
    "#_" "/=" "|=" "|>" "==" "=>" ">-" ">=" "<-" "<|" "<~" "~-" "~@" "~="
    "~>" "~~"
    ;; whitespace ligatures
    "---" "'''" "\"\"\"" "..." "..<" "{|" "[|" ".?" "::" ":::" "::=" ":="
    ":>" ":<" "\;\;" "!!" "!!." "!!!"  "?." "?:" "??" "?=" "*>"
    "*/" "--" "#:" "#!" "#?" "##" "###" "####" "#=" "/*" "/>" "//" "/**"
    "///" "$(" ">&" "<&" "&&" "|}" "|]" "$>" ".." "++" "+++" "+>" "=:="
    "=!=" ">:" ">>" ">>>" "<:" "<*" "<*>" "<$" "<$>" "<+" "<+>" "<>" "<<"
    "<<<" "</" "</>" "^=" "%%"))

;; Function to load PragmataPro font configuration
(defun my/load-pragmatapro-font-config ()
  "Load the PragmataPro font configuration."
  ;; Font configuration
  (setq doom-font (font-spec :family "PragmataPro Liga" :size 18 :weight 'regular)
        doom-variable-pitch-font (font-spec :family "PragmataPro Liga" :size 18 :weight 'regular)
        doom-symbol-font (font-spec :family "PragmataPro Liga" :size 18 :weight 'regular))
  (enable-pragmatapro-lig-hooks)
  (turn-on-pragmatapro-lig-mode))

;; Custom theme toggle function
(defun my/toggle-theme ()
  "Toggle between light and dark themes without changing font."
  (interactive)
  (let ((current-theme (car custom-enabled-themes))
        (new-theme (if (eq (car custom-enabled-themes) my/light-theme)
                       my/dark-theme
                     my/light-theme)))
    (load-theme new-theme t)
    (doom/reload-theme)
    (message "Switched to %s theme" new-theme)))

;; Custom font toggle function
(defun my/toggle-font ()
  "Toggle between PragmataPro Liga and MonoLisa Variable fonts."
  (interactive)
  (let ((new-font-config (if (eq my/current-font-config 'pragmatapro)
                             'monolisa
                           'pragmatapro)))
    (my/load-font-config new-font-config)
    (doom/reload-font)
    (message "Switched to %s font configuration" new-font-config)))

;; Common configuration that applies to both themes
(defun my/load-common-appearance-config ()
  "Load configuration that's common to both appearance setups."
  ;; Ensure doom-themes is available
  (require 'doom-themes)

  ;; Dashboard configuration
  (setq dashboard-center-content t
        dashboard-vertically-center-content t)

  ;; Rainbow delimiters
  (use-package rainbow-delimiters
    :hook (prog-mode . rainbow-delimiters-mode))

  ;; Modus themes configuration
  (use-package! emacs
    :config
    (require-theme 'modus-themes)
    (setq modus-themes-italic-constructs t
          modus-themes-bold-constructs t
          modus-themes-common-palette-overrides
          '((cursor "#FEB000")))
    ;; Theme toggle keybinding
    (define-key global-map (kbd "<f8>") #'my/toggle-theme))

  ;; Cursor configuration
  (blink-cursor-mode 1)
  (setq blink-cursor-blinks 0
        blink-cursor-interval 0.5)

  (when (fboundp 'cursor-face-highlight-mode)
    (cursor-face-highlight-mode 1))

  ;; Idle highlight mode
  (use-package idle-highlight-mode
    :config (setq idle-highlight-idle-time 0.1)
    :hook ((org-mode text-mode) . idle-highlight-mode))

  (global-centered-cursor-mode +1)
  ;; Treemacs
  (load (expand-file-name "config/ui/my-treemacs-config" doom-user-dir))

  ;; Ultra scroll
  (use-package ultra-scroll
    :init
    (setq scroll-conservatively 30
          scroll-margin 0)
    :config
    (ultra-scroll-mode 1))

  (use-package indent-bars
    :hook (prog-mode . indent-bars-mode)
    :custom
    (indent-bars-no-descend-lists t) ; no extra bars in continued func arg lists
    (indent-bars-treesit-support t)
    (setopt
     indent-bars-color '(highlight :face-bg t :blend 0.8)
     indent-bars-pattern "."
     indent-bars-color-by-depth '(:regexp "outline-\\([0-9]+\\)" :blend 0.8)
     indent-bars-highlight-current-depth '(:blend 1.0 :width 0.4 :pad 0.1 :pattern "!.!.!." :zigzag 0.1)
     indent-bars-pad-frac 0.3
     indent-bars-ts-highlight-current-depth '(no-inherit) ; equivalent to nil
     indent-bars-ts-color-by-depth '(no-inherit)
     indent-bars-ts-color '(inherit fringe :face-bg t :blend 0.2))))
;; End of my/load-common-appearance-config function

;; Initialize the configuration
(defun my/initialize-theme-aware-appearance ()
  "Initialize the theme-aware appearance configuration."
  ;; Load common configuration first
  (my/load-common-appearance-config)

  ;; Determine initial theme (default to dark theme)
  (let ((initial-theme (or (car custom-enabled-themes) my/dark-theme)))
    (load-theme initial-theme t)
    ;; Load initial font configuration (default to pragmata)
    (my/load-font-config my/current-font-config))

  (after! (solaire-mode demap)
    (setq demap-minimap-window-width 15)
    (let ((gray1 "#1A1C22")
          (gray2 "#21242b")
          (gray3 "#282c34")
          (gray4 "#2b3038"))
      (face-spec-set 'demap-minimap-font-face
                     `((t :background ,gray2
                          :inherit    unspecified
                          :family     "minimap"
                          :height     15)))
      (face-spec-set 'demap-visible-region-face
                     `((t :background ,gray4
                          :inherit    unspecified)))
      (face-spec-set 'demap-visible-region-inactive-face
                     `((t :background ,gray3
                          :inherit    unspecified)))
      (face-spec-set 'demap-current-line-face
                     `((t :background ,gray1
                          :inherit    unspecified)))
      (face-spec-set 'demap-current-line-inactive-face
                     `((t :background ,gray1
                          :inherit    unspecified)))))

  (add-hook! 'demap-minimap-construct-hook
    (when (bound-and-true-p org-modern-mode)
      (org-modern-mode -1))
    (when (bound-and-true-p ligature-mode)
      (ligature-mode -1))
    (when (bound-and-true-p pragmatapro-lig-mode)
      (pragmatapro-lig-mode -1)))

  ;; Add keybindings [INFO]
  (define-key global-map (kbd "<f7>")  #'my/toggle-theme)
  (define-key global-map (kbd "<f8>")  #'my/toggle-font)
  (define-key global-map (kbd "<f9>")  (lambda ()
                                         (interactive)
                                         (ligature-mode 'toggle)))
  (define-key global-map (kbd "<f10>")  (lambda ()
                                          (interactive)
                                          (pragmatapro-lig-mode 'toggle)))
  (define-key global-map (kbd "<f11>") (lambda ()
                                         (interactive)
                                         (indent-bars-reset)))
  (define-key global-map (kbd "<f12>") (lambda ()
                                         (interactive)
                                         (global-centered-cursor-mode 'toggle))))

;; Auto-initialize when this file is loaded
(my/initialize-theme-aware-appearance)
(my/load-monolisa-font-config)

(provide 'my-gui-appearance-config)
