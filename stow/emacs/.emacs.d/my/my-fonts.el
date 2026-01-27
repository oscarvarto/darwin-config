;; -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package ligature
  :ensure (:host github :repo "mickeynp/ligature.el" :depth 1)
  :demand t
  :config
  ;; Variables to track current configuration state
  (defvar my/current-font-config nil
    "Stores the currently loaded font configuration ('pragmatapro, 'monolisa, or 'jetbrains).")

  (load "pragmatapro-lig")

  (defun turn-on-pragmatapro-lig-mode ()
    "Enable pragmatapro-lig-mode for the current buffer."
    (interactive)
    (when (not (minibufferp))
      (ligature-mode -1)
      (pragmatapro-lig-mode 1)))

  (defun turn-off-pragmatapro-lig-mode ()
    "Disable pragmatapro-lig-mode for the current buffer."
    (interactive)
    (ligature-mode +1)
    (pragmatapro-lig-mode -1))

  (defun delayed-turn-on-pragmatapro-lig-mode ()
    "Enable pragmatapro-lig-mode after a short delay."
    (run-with-timer 1.0 nil #'turn-on-pragmatapro-lig-mode))

  (defun enable-pragmatapro-lig-hooks (&optional _)
    "Enable `pragmatapro-lig'"
    (add-hook 'text-mode-hook #'delayed-turn-on-pragmatapro-lig-mode)
    (add-hook 'org-mode-hook #'delayed-turn-on-pragmatapro-lig-mode)
    (add-hook 'prog-mode-hook #'delayed-turn-on-pragmatapro-lig-mode))

  (defun disable-pragmatapro-lig-hooks (&optional _)
    "Disable `pragmatapro-lig'"
    (remove-hook 'text-mode-hook #'delayed-turn-on-pragmatapro-lig-mode)
    (remove-hook 'org-mode-hook #'delayed-turn-on-pragmatapro-lig-mode)
    (remove-hook 'prog-mode-hook #'delayed-turn-on-pragmatapro-lig-mode))

  ;; Helper function to reload fonts in vanilla Emacs
  (defun my/reload-font ()
    "Reload font configuration by setting the default face."
    (when (display-graphic-p)
      (set-face-attribute 'default nil
                          :font (face-attribute 'default :font))
      (set-face-attribute 'fixed-pitch nil
                          :font (face-attribute 'fixed-pitch :font))
      (set-face-attribute 'variable-pitch nil
                          :font (face-attribute 'variable-pitch :font))
      ;; Force frame update
      (dolist (frame (frame-list))
        (set-frame-font (face-attribute 'default :font) nil (list frame)))))

  ;; Helper function to reload theme in vanilla Emacs
  (defun my/reload-theme ()
    "Reload the current theme."
    (let ((current-themes custom-enabled-themes))
      (mapc #'disable-theme current-themes)
      (mapc (lambda (theme) (load-theme theme t)) current-themes)))

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
    ;; Font configuration for vanilla Emacs
    (when (display-graphic-p)
      (set-face-attribute 'default nil
                          :family "MonoLisaVariable Nerd Font"
                          :height 160
                          :weight 'regular)
      (set-face-attribute 'fixed-pitch nil
                          :family "MonoLisaVariable Nerd Font"
                          :height 160
                          :weight 'regular)
      (set-face-attribute 'variable-pitch nil
                          :family "MonoLisaVariable Nerd Font"
                          :height 160
                          :weight 'regular))

    (turn-off-pragmatapro-lig-mode) ;; implies (ligature-mode-turn-on)
    (disable-pragmatapro-lig-hooks)
    ;; Enable ligature mode
    (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))

    ;; MonoLisa ligatures
    (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode) nil)
    (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode)
      ;; coding ligatures
      '("<!---" "--->" "|||>" "<!--" "<|||" "<==>" "-->" "->>" "-<<" "..=" "!=="
        "#_(" "/==" "||>" "||=" "|->" "===" "==>" "=>>" "=<<" "=/=" ">->" ">=>"
        ">>-" ">>=" "<--" "<->" "-<" "<||" "<|>" "<=" "<==" "<=>" "<=<" "<<-"
        "<<=" "<~>" "<~~" "~~>" ">&-" "<&-" "&>>" "&>" "->" "-<" "-~" ".=" "!="
        "#_" "/=" "|=" "|>" "==" "=>" ">-" ">=" "<-" "<|" "<~" "~-" "~@" "~="
        "~>" "~~"
        ;; whitespace ligatures
        "---" "'''" "\"\"\"" "..." "..<" "{|" "[|" ".?" "::" ":::" "::=" ":="
        ":>" ":<" ";;" "!!" "!!." "!!!" "?." "?:" "??" "?=" "*>"
        "*/" "--" "#:" "#!" "#?" "##" "###" "####" "#=" "/*" "/>" "//" "/**"
        "///" "$(" ">&" "<&" "&&" "|}" "|]" "$>" ".." "++" "+++" "+>" "=:="
        "=!=" ">:" ">>" ">>>" "<:" "<*" "<*>" "<$" "<$>" "<+" "<+>" "<>" "<<"
        "<<<" "</" "</>" "^=" "%%"))

    ;; Enable ligature mode globally
    (global-ligature-mode t))

  ;; Function to load PragmataPro font configuration
  (defun my/load-pragmatapro-font-config ()
    "Load the PragmataPro font configuration."
    ;; Font configuration for vanilla Emacs
    (when (display-graphic-p)
      (set-face-attribute 'default nil
                          :family "PragmataPro Mono Liga"
                          :height 180
                          :weight 'regular)
      (set-face-attribute 'fixed-pitch nil
                          :family "PragmataPro Mono Liga"
                          :height 180
                          :weight 'regular)
      (set-face-attribute 'variable-pitch nil
                          :family "PragmataPro Mono Liga"
                          :height 180
                          :weight 'regular))
    (enable-pragmatapro-lig-hooks)
    ;; Only enable pragmatapro-lig-mode if not in dashboard or minibuffer
    (unless (or (minibufferp)
                (and (boundp 'dashboard-buffer-name)
                     (string= (buffer-name) dashboard-buffer-name)))
      (turn-on-pragmatapro-lig-mode)))

  ;; Function to load JetBrains Mono font configuration
  (defun my/load-jetbrains-font-config ()
    "Load the JetBrains Mono font configuration (fallback option)."
    ;; Font configuration for vanilla Emacs
    (when (display-graphic-p)
      (set-face-attribute 'default nil
                          :family "JetBrainsMono Nerd Font"
                          :height 140
                          :weight 'regular)
      (set-face-attribute 'fixed-pitch nil
                          :family "JetBrainsMono Nerd Font"
                          :height 140
                          :weight 'regular)
      (set-face-attribute 'variable-pitch nil
                          :family "JetBrainsMono Nerd Font"
                          :height 140
                          :weight 'regular))

    (turn-off-pragmatapro-lig-mode) ;; implies (ligature-mode-turn-on)
    (disable-pragmatapro-lig-hooks)
    ;; Enable standard ligature mode
    (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))

    ;; JetBrains Mono ligatures (subset of standard programming ligatures)
    (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode) nil)
    (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode)
      ;; Basic coding ligatures that work well with JetBrains Mono
      '("-->" "->" "=>" "==>" "=>>" "=<<" "=/=" ">=" "<=" "!="
        "===" "==" "=<" "=>" "<-" "->" "<->" "<==" "==>" "<==>"
        "<=>" "=/" "/=" "!==" "!=" "<!>" "<~>" "~~>" "~>" "~="
        "<|" "|>" "|>>" "<||>" "||" "||>"
        "++" "--" "**" "***" "//" "///" "/*" "*/" "#?"
        "::" ":::" "::=" ":=" ":.>" ":>" ".="
        ".." "..." "?:" "??" ".?" "?."))

    ;; Enable ligature mode globally
    (global-ligature-mode t))

  ;; Initialize catppuccin flavor support
  ;; SINGLE SOURCE OF TRUTH: Default catppuccin flavor configuration
  (defconst my/default-catppuccin-flavor 'mocha
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
        (my/reload-theme)
        (message "Switched to Catppuccin %s flavor (via load-theme)" new-flavor))
       ;; Method 3: Fallback - just reload theme
       (t
        (my/reload-theme)
        (message "Theme toggled to %s mode (fallback method)" new-flavor)))))

  ;; Custom font toggle function
  (defun my/toggle-font ()
    "Cycle between PragmataPro Liga, MonoLisa Variable, and JetBrains Mono fonts."
    (interactive)
    (let ((new-font-config (cond
                            ((eq my/current-font-config 'pragmatapro) 'monolisa)
                            ((eq my/current-font-config 'monolisa) 'jetbrains)
                            ((eq my/current-font-config 'jetbrains) 'pragmatapro)
                            (t 'monolisa)))
          (in-dashboard (string= (buffer-name) dashboard-buffer-name)))
      ;; Load the new font configuration
      (my/load-font-config new-font-config)
      ;; Apply fonts to all frames without triggering redraws
      (dolist (frame (frame-list))
        (my/apply-fonts-to-frame frame))
      ;; If we're in dashboard, refresh it once cleanly
      (when in-dashboard
        (with-current-buffer dashboard-buffer-name
          (let ((inhibit-read-only t))
            (erase-buffer)
            (dashboard-insert-startupify-lists t)
            (goto-char (point-min)))))
      (message "Switched to %s font configuration" new-font-config)))

  ;; Common configuration that applies to both themes
  (defun my/load-common-appearance-config ()
    "Load configuration that's common to both appearance setups."

    ;; Rainbow delimiters
    (use-package rainbow-delimiters
      :ensure t
      :demand t
      :hook (prog-mode . rainbow-delimiters-mode))

    ;; Cursor configuration
    (blink-cursor-mode 1)
    (setq blink-cursor-blinks 0
          blink-cursor-interval 0.5)

    (when (fboundp 'cursor-face-highlight-mode)
      (cursor-face-highlight-mode 1))

    ;; Idle highlight mode (disabled due to repo issues)
    (use-package idle-highlight-mode
      :ensure t
      :demand t
      :config (setq idle-highlight-idle-time 0.1)
      :hook ((org-mode text-mode prog-mode) . idle-highlight-mode))

    ;; Ultra scroll
    (use-package ultra-scroll
      :ensure t
      :demand t
      :init
      (setq scroll-conservatively 30
            scroll-margin 0)
      :config
      (ultra-scroll-mode 0)))

     ;; End of my/load-common-appearance-config function

  ;; Helper function to apply ligature configuration for current font
  (defun my/apply-ligature-config ()
    "Apply ligature configuration for the current font."
    (cond
     ((eq my/current-font-config 'monolisa)
      ;; MonoLisa ligatures
      (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
      (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode) nil)
      (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode)
        '("<!---" "--->" "|||>" "<!--" "<|||" "<==>" "-->" "->>" "-<<" "..=" "!=="
          "#_(" "/==" "||>" "||=" "|->" "===" "==>" "=>>" "=<<" "=/=" ">->" ">=>"
          ">>-" ">>=" "<--" "<->" "-<" "<||" "<|>" "<=" "<==" "<=>" "<=<" "<<-"
          "<<=" "<~>" "<~~" "~~>" ">&-" "<&-" "&>>" "&>" "->" "-<" "-~" ".=" "!="
          "#_" "/=" "|=" "|>" "==" "=>" ">-" ">=" "<-" "<|" "<~" "~-" "~@" "~="
          "~>" "~~"
          "---" "'''" "\"\"\"" "..." "..<" "{|" "[|" ".?" "::" ":::" "::=" ":="
          ":>" ":<" ";;" "!!" "!!." "!!!" "?." "?:" "??" "?=" "*>"
          "*/" "--" "#:" "#!" "#?" "##" "###" "####" "#=" "/*" "/>" "//" "/**"
          "///" "$(" ">&" "<&" "&&" "|}" "|]" "$>" ".." "++" "+++" "+>" "=:="
          "=!=" ">:" ">>" ">>>" "<:" "<*" "<*>" "<$" "<$>" "<+" "<+>" "<>" "<<"
          "<<<" "</" "</>" "^=" "%%"))
      (unless (bound-and-true-p global-ligature-mode)
        (global-ligature-mode t)))
     ((eq my/current-font-config 'jetbrains)
      ;; JetBrains Mono ligatures
      (ligature-set-ligatures 'eww-mode '("ff" "fi" "ffi"))
      (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode) nil)
      (ligature-set-ligatures '(prog-mode text-mode org-mode markdown-mode)
        '("-->" "->" "=>" "==>" "=>>" "=<<" "=/=" ">=" "<=" "!="
          "===" "==" "=<" "=>" "<-" "->" "<->" "<==" "==>" "<==>"
          "<=>" "=/" "/=" "!==" "!=" "<!>" "<~>" "~~>" "~>" "~="
          "<|" "|>" "|>>" "<||>" "||" "||>"
          "++" "--" "**" "***" "//" "///" "/*" "*/" "#?"
          "::" ":::" "::=" ":=" ":.>" ":>" ".="
          ".." "..." "?:" "??" ".?" "?."))
      (unless (bound-and-true-p global-ligature-mode)
        (global-ligature-mode t)))))

  ;; Helper function to apply fonts to a specific frame
  (defun my/apply-fonts-to-frame (&optional frame)
    "Apply current font configuration to FRAME (or selected frame if nil)."
    (when (display-graphic-p frame)
      (with-selected-frame (or frame (selected-frame))
        (let* ((font-config my/current-font-config)
               (font-spec (cond
                           ((eq font-config 'monolisa)
                            '(:family "MonoLisaVariable Nerd Font" :height 160 :weight regular))
                           ((eq font-config 'pragmatapro)
                            '(:family "PragmataPro Mono Liga" :height 180 :weight regular))
                           ((eq font-config 'jetbrains)
                            '(:family "JetBrainsMono Nerd Font" :height 140 :weight regular))
                           (t '(:family "MonoLisaVariable Nerd Font" :height 160 :weight regular)))))
          (apply 'set-face-attribute 'default frame font-spec)
          (apply 'set-face-attribute 'fixed-pitch frame font-spec)
          (apply 'set-face-attribute 'variable-pitch frame font-spec)
          ;; Apply ligature configuration for MonoLisa and JetBrains
          (when (memq font-config '(monolisa jetbrains))
            (my/apply-ligature-config)
            ;; Enable ligature-mode in all existing buffers
            (dolist (buffer (buffer-list))
              (with-current-buffer buffer
                (when (and (not (minibufferp))
                           (or (derived-mode-p 'prog-mode)
                               (derived-mode-p 'text-mode)
                               (derived-mode-p 'org-mode)))
                  (ligature-mode 1)))))))))

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

    ;; Defer font initialization to avoid dashboard redraw issues
    (run-with-idle-timer 0.1 nil
      (lambda ()
        ;; Load initial font configuration (default to pragmatapro)
        (my/load-font-config 'pragmatapro)
        ;; Apply fonts to current frame
        (my/apply-fonts-to-frame)))

    ;; Add hook for new frames (important for emacsclient)
    (add-hook 'after-make-frame-functions #'my/apply-fonts-to-frame)

    ;; Note: demap-minimap-construct-hook removed as it's Doom-specific
    ;; If you need similar functionality, you'll need to implement it separately

    ;; Add keybindings
    (global-set-key (kbd "<f7>") #'my/toggle-theme)
    (global-set-key (kbd "<f8>") #'my/toggle-font)
    (global-set-key (kbd "<f9>") (lambda ()
                                    (interactive)
                                    (ligature-mode 'toggle)))
    (global-set-key (kbd "<f10>") (lambda ()
                                     (interactive)
                                     (when (fboundp 'pragmatapro-lig-mode)
                                       (pragmatapro-lig-mode 'toggle)))))

  ;; Auto-initialize after all functions are defined
  (my/initialize-theme-aware-appearance))

(provide 'my-fonts)
