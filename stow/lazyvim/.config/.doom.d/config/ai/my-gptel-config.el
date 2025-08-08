;;  -*- lexical-binding: t; no-byte-compile: t; -*-

(use-package! gptel
  :config
  (setq
   gptel-model 'deepseek-r1:70b
   gptel-backend (gptel-make-ollama "Ollama"
                   :host "localhost:11434"
                   :stream t
                   :models '(deepseek-r1:70b)))
  (setq gptel-default-mode 'org-mode))

;; (require 'gptel-autocomplete)
;; (setq gptel-autocomplete-before-context-lines 100)
;; (setq gptel-autocomplete-after-context-lines 20)
;; (setq gptel-autocomplete-temperature 0.1)
;;
;; ;; M-x gptel-complete — Request a completion at point and display it as ghost text.
;; (define-key global-map (kbd "<f1>")  #'gptel-complete)
;; ;; M-x gptel-accept-completion — Accept the currently displayed completion and insert it.
;; (define-key global-map (kbd "<f2>")  #'gptel-accept-completion)

(provide 'my-gptel-config)
