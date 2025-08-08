;; -*- lexical-binding: t; no-byte-compile: t; -*-

(defun predator-banner-fn ()
  (let* ((banner '(" ⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ ⣀⣀⡀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀⠀ "
                   "⠀⠀⠀⠀⠀⠀⠀⠀⠀⢀⣤⣾⠟⠛⠛⠛⠛⠻⣷⣤⡀⠀⠀⠀⠀⠀⠀⠀⠀ "
                   "⠀⠀⠀⠀⠀⢀⣠⠂⣰⣿⠋⣀⣴⣶⣿⣿⣶⣦⣀⠙⣿⣆⠀⣄⡀⠀⠀⠀⠀ "
                   "⠀⠀⠀⢀⣴⠟⠁⢠⣿⡏⠀⣿⣿⣿⣿⣿⣿⣿⣿⠀⢹⣿⠄⠈⠻⣦⡀⠀⠀ "
                   "⠀⠀⢠⡿⠁⣠⡦⠀⢿⣿⡄⠙⢿⣿⣿⣿⣿⡿⠋⢠⣿⡿⠀⢴⣄⠈⢿⡄⠀ "
                   "⠀⢰⡿⠀⣰⡟⠀⣤⠈⠻⣿⣷⣤⣀⣀⣀⣀⣤⣾⣿⠟⠁⣤⠀⢻⣆⠀⢿⡆ "
                   "⢀⣿⠁⢠⡿⠀⣸⡏⢠⣤⠈⠙⠻⠿⠿⠿⠿⠟⠋⠁⣤⡆⢹⣇⠀⢿⡄⠈⣿⡀"
                   "⢸⡇⠀⣿⠁⢠⡟⠀⣼⣿⣷⣄⣀⣠⣴⣦⣄⣀⣠⣾⣿⣧⠀⢿⡄⠈⣿⠀⢸⡇"
                   "⣼⠇⢀⣿⠀⣼⡇⠀⣿⣿⣿⡿⠛⢁⣠⣄⡈⠛⢿⣿⣿⣿⠀⢸⣧⠀⣿⡀⠸⣧"
                   "⣿⠀⢸⡏⠀⣿⠃⠀⠹⣿⣿⡇⢸⣿⣿⣿⣿⡇⢸⣿⣿⠏⠀⠘⣿⠀⢹⡇⠀⣿"
                   "⠀⠀⢸⡇⠀⣿⠀⠀⠀⠈⠛⠃⢸⣿⣿⣿⣿⡇⠘⠛⠁⠀⠀⠀⣿⠀⢸⡇⠀⠀"
                   "⠀⠀⠀⠀⠀⠿⠀⠀⠀⠀⠀⠀⠈⠛⠛⠛⠛⠁⠀⠀⠀⠀⠀⠀⠿⠀⠀⠀⠀⠀"))
         (longest-line (apply #'max (mapcar #'length banner))))
    (put-text-property
     (point)
     (dolist (line banner (point))
       (insert (+doom-dashboard--center
                +doom-dashboard--width
                (concat line (make-string (max 0 (- longest-line (length line))) 32)))
               "\n"))
     'face 'doom-dashboard-banner)))

(setq +doom-dashboard-ascii-banner-fn #'predator-banner-fn)

;;(setq fancy-splash-image "~/doom-extra-files/banners/predator-19-banner.png")
;;(setq fancy-splash-image "~/doom-extra-files/banners/predator-dark-19-banner.png")
;;(setq fancy-splash-image "~/doom-extra-files/banners/predator.jpg")
(setq fancy-splash-image "~/doom-extra-files/banners/emacs-lsp-left.png")

(provide 'my-banner-config)
