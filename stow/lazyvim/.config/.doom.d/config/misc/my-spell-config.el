;;; my-spell-config.el -*- lexical-binding: t; no-byte-compile: t; -*-

;; With Doom's (spell +enchant), Enchant will select the aspell provider based on env.
;; Do not override ispell-program-name here.

;; Default to English; we'll auto-switch to Spanish with guess-language
(setq ispell-dictionary "en")
(setq ispell-silently-savep t)
(setq flyspell-issue-message-flag nil)

;; Tweak aspell for better performance/accuracy
(setq ispell-extra-args '("--sug-mode=ultra" "--run-together"))

;; Enable Flyspell where it makes sense
(add-hook 'text-mode-hook #'flyspell-mode)
(add-hook 'prog-mode-hook #'flyspell-prog-mode)

;; Auto-detect language between English and Spanish
(use-package guess-language
  :after flyspell
  :hook ((text-mode . guess-language-mode)
         (org-mode . guess-language-mode)
         (markdown-mode . guess-language-mode))
  :custom
  (guess-language-languages '(en es))
  (guess-language-min-paragraph-length 40)
  (guess-language-excluded-major-modes '(prog-mode))
  ;; When language changes, set ispell dictionary accordingly
  :config
  (setq guess-language-langcodes
        '((en . ("en" "en_US" "en-GB"))
          (es . ("es" "es_MX" "es-ES"))))
  (add-hook 'guess-language-after-detection-functions
            (defun my/guess-language-set-ispell (lang)
              (pcase lang
                ('en (ispell-change-dictionary "en"))
                ('es (ispell-change-dictionary "es"))
                (_ nil)))))

;; Optional: add Nix profile bin to exec-path if missing
(let ((nix-bin (expand-file-name "~/.nix-profile/bin")))
  (unless (member nix-bin exec-path)
    (push nix-bin exec-path)))

(provide 'my-spell-config)
