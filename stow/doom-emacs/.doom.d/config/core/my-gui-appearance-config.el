;;; my-gui-appearance-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; Variables to track current configuration state
(defvar my/current-font-config 'monolisa
  "Stores the currently loaded font configuration ('pragmatapro, 'monolisa, or 'jetbrains).")

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
  "Load the specified font configuration FONT-TYPE ('pragmatapro, 'monolisa, or 'jetbrains)."
  (when (not (eq my/current-font-config font-type))
    (message "Loading %s font configuration" font-type)

    ;; Load the appropriate configuration
    (cond
     ((eq font-type 'monolisa)
      ;; Load MonoLisa configuration
      (my/load-monolisa-font-config))
     ((eq font-type 'pragmatapro)
      ;; Load PragmataPro configuration
      (my/load-pragmatapro-font-config))
     ((eq font-type 'jetbrains)
      ;; Load JetBrains Mono configuration
      (my/load-jetbrains-font-config)))
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

;; Function to load JetBrains Mono font configuration
(defun my/load-jetbrains-font-config ()
  "Load the JetBrains Mono font configuration (fallback option)."
  ;; Font configuration
  (setq doom-font (font-spec :family "JetBrains Mono" :size 14 :weight 'regular)
        doom-variable-pitch-font (font-spec :family "JetBrains Mono" :size 14 :weight 'regular)
        doom-symbol-font (font-spec :family "JetBrains Mono" :size 14 :weight 'regular))

  (turn-off-pragmatapro-lig-mode) ;; implies (ligature-mode-turn-on)
  (disable-pragmatapro-lig-hooks)
  ;; Enable standard ligature mode
  (set-font-ligatures! 'eww-mode "ff" "fi" "ffi")

  ;; JetBrains Mono ligatures (subset of standard programming ligatures)
  (set-font-ligatures! '(prog-mode text-mode org-mode doom-docs-mode markdown-mode) nil)
  (set-font-ligatures! '(prog-mode text-mode org-mode doom-docs-mode markdown-mode)
    ;; Basic coding ligatures that work well with JetBrains Mono
    "-->" "->" "=>" "==>" "=>>" "=<<" "=/=" ">=" "<=" "!="
    "===" "==" "=<" "=>" "<-" "->" "<->" "<==" "==>" "<==>"
    "<=>" "=/" "/=" "!==" "!=" "<!>" "<~>" "~~>" "~>" "~="
    "<|" "|>" "|>>" "<||>" "||" "||>"
    "++" "--" "**" "***" "//" "///" "/*" "*/" "#?"
    "::" ":::" "::=" ":=" ":.>" ":>" ".="
    ".." "..." "?:" "??" ".?" "?."))

;; Initialize catppuccin flavor support
;; SINGLE SOURCE OF TRUTH: Default catppuccin flavor configuration
(defconst my/default-catppuccin-flavor 'latte
  "The default catppuccin flavor to use on startup and as fallback.")

(defvar my/catppuccin-current-flavor my/default-catppuccin-flavor
  "Current catppuccin flavor (fallback if catppuccin-flavor is not available).")

(defun my/ensure-catppuccin-loaded ()
  "Ensure catppuccin theme package is loaded and initialized."
  (condition-case nil
      (progn
        (require 'catppuccin-theme)
        ;; Check if catppuccin-flavor variable exists
        (unless (boundp 'catppuccin-flavor)
          (defvar catppuccin-flavor my/default-catppuccin-flavor))
        ;; Set our fallback to match the actual variable if it exists
        (when (boundp 'catppuccin-flavor)
          (setq my/catppuccin-current-flavor catppuccin-flavor))
        t)
    (error
     (message "Warning: catppuccin-theme package not available, using fallback")
     nil)))

(defun my/get-current-catppuccin-flavor ()
  "Get the current catppuccin flavor, with fallback support."
  (if (boundp 'catppuccin-flavor)
      catppuccin-flavor
    my/catppuccin-current-flavor))

(defun my/set-catppuccin-flavor (flavor)
  "Set catppuccin flavor with fallback support."
  (if (boundp 'catppuccin-flavor)
      (setq catppuccin-flavor flavor)
    (setq my/catppuccin-current-flavor flavor)))

;; Custom theme toggle function
(defun my/toggle-theme ()
  "Toggle between light and dark Catppuccin flavors without changing font."
  (interactive)
  (my/ensure-catppuccin-loaded)

  (let* ((current-flavor (my/get-current-catppuccin-flavor))
         (new-flavor (if (eq current-flavor 'latte)
                         'mocha
                       'latte)))
    (my/set-catppuccin-flavor new-flavor)

    ;; Try different methods to reload the theme
    (cond
     ;; Method 1: Use catppuccin-reload if available
     ((fboundp 'catppuccin-reload)
      (catppuccin-reload)
      (message "Switched to Catppuccin %s flavor (via catppuccin-reload)" new-flavor))
     ;; Method 2: Try loading catppuccin theme directly
     ((featurep 'catppuccin-theme)
      (load-theme 'catppuccin :no-confirm)
      (doom/reload-theme)
      (message "Switched to Catppuccin %s flavor (via load-theme)" new-flavor))
     ;; Method 3: Fallback - just reload doom theme
     (t
      (doom/reload-theme)
      (message "Theme toggled to %s mode (fallback method)" new-flavor)))))

;; Custom font toggle function
(defun my/toggle-font ()
  "Cycle between PragmataPro Liga, MonoLisa Variable, and JetBrains Mono fonts."
  (interactive)
  (let ((new-font-config (cond
                          ((eq my/current-font-config 'pragmatapro) 'monolisa)
                          ((eq my/current-font-config 'monolisa) 'jetbrains)
                          ((eq my/current-font-config 'jetbrains) 'pragmatapro)
                          (t 'pragmatapro))))
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
  (load (expand-file-name "config/ui/my-treemacs-config" doom-user-dir))

  (use-package indent-bars
    :custom
    (indent-bars-no-descend-lists t) ; no extra bars in continued func arg lists
    (indent-bars-treesit-support t)
    (indent-bars-treesit-ignore-blank-lines-types '("module"))
    (setq
     indent-bars-pattern "."
     indent-bars-width-frac 0.5
     indent-bars-pad-frac 0.25
     indent-bars-color-by-depth nil
     indent-bars-highlight-current-depth '(:face default :blend 0.4))
    :hook (prog-mode . indent-bars-mode))

  ;; Ultra scroll
  (use-package ultra-scroll
    :init
    (setq scroll-conservatively 30
          scroll-margin 0)
    :config
    (ultra-scroll-mode 1)))

   ;; End of my/load-common-appearance-config function

;; Initialize the configuration
(defun my/initialize-theme-aware-appearance ()
  "Initialize the theme-aware appearance configuration."
  ;; Load common configuration first
  (my/load-common-appearance-config)

  ;; Initialize catppuccin following official documentation pattern
  (condition-case nil
      (progn
        ;; Set the flavor BEFORE loading the theme (per documentation)
        (setq catppuccin-flavor my/default-catppuccin-flavor)
        ;; Load the theme with the pre-set flavor (no need to call catppuccin-reload)
        (load-theme 'catppuccin :no-confirm)
        (message "Loaded Catppuccin theme with %s flavor" my/default-catppuccin-flavor))
    (error
     (message "Warning: catppuccin theme not available, using default theme")))

  ;; Load initial font configuration (default to monolisa)
  (my/load-font-config my/current-font-config)

  (after! (solaire-mode demap)
    (setq demap-minimap-window-width 15)
    (let ((gray1 "#1A1C22")
          (gray2 "#21242b")
          (gray3 "#282c34")
          (gray4 "#2b3038"))
      (face-spec-set 'demap-minimap-font-face
                     `((t :background ,gray2
                          :inherit    nil
                          :family     "minimap"
                          :height     15)))
      (face-spec-set 'demap-visible-region-face
                     `((t :background ,gray4
                          :inherit    nil)))
      (face-spec-set 'demap-visible-region-inactive-face
                     `((t :background ,gray3
                          :inherit    nil)))
      (face-spec-set 'demap-current-line-face
                     `((t :background ,gray1
                          :inherit    nil)))
      (face-spec-set 'demap-current-line-inactive-face
                     `((t :background ,gray1
                          :inherit    nil))))

    (add-hook! 'demap-minimap-construct-hook
      (when (bound-and-true-p org-modern-mode)
        (org-modern-mode -1))
      (when (bound-and-true-p ligature-mode)
        (ligature-mode -1))
      (when (bound-and-true-p pragmatapro-lig-mode)
        (pragmatapro-lig-mode -1))))


  ;; Add keybindings [INFO]
  (define-key global-map (kbd "<f6>") (lambda ()
                                         (interactive)
                                         (indent-bars-reset)))
  (define-key global-map (kbd "<f7>")  #'my/toggle-theme)
  (define-key global-map (kbd "<f8>")  #'my/toggle-font)
  (define-key global-map (kbd "<f9>")  (lambda ()
                                         (interactive)
                                         (ligature-mode 'toggle)))
  (define-key global-map (kbd "<f10>")  (lambda ()
                                          (interactive)
                                          (pragmatapro-lig-mode 'toggle)))
  (define-key global-map (kbd "<f12>") (lambda ()
                                         (interactive)
                                         (global-centered-cursor-mode 'toggle))))

;; Auto-initialize when this file is loaded
(my/initialize-theme-aware-appearance)
(my/load-monolisa-font-config)

(provide 'my-gui-appearance-config)
