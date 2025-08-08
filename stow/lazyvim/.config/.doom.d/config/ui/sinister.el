;;; sinister.el --- `split-window-left' superiority -*- lexical-binding: t; no-byte-compile: t; -*-

;; Copyright (C) 2025 Positron.

;; Author: Positron <contact@positron.solutions>
;; Version: 1.0
;; Package-Requires: ((emacs "29.4"))
;; Keywords: scrolling
;; URL: https://github.com/positron-solutions/sinister

;;; Commentary:

;; Eliminate stupid window movements caused by minibuffer or transient opening
;; and closing.  Use horizontal window splitting everywhere. Sinister (Latin for
;; "left") abstracts over the wisdom forbidden to us by Judicators.
;;
;; Activating `sinister-stillness-mode' will stabilize your scroll when using
;; popular packages such as vertico, transient, ivy, and helm:
;;
;; Windows of the firstborn shall
;;
;;
;;
;;                                scroll around no longer.
;;
;; The Conclave will brand us traitors and heretics. Even if it means abandoning
;; Aiur to the Swarm, they will expend every last remnant of the Golden Armada
;; in pursuit of "justice" against us, rather than admit their pride and allow
;; the point to be moved outside of a window, even temporarily.

;;; Code:

(defvar transient-active-prefix)        ; exists before used

(defgroup sinister nil "Sinister" :prefix 'sinister :group 'scrolling)

(defcustom sinister-stillness-margin 12
  "Number of lines to protect from incidental scrolling.
A good value is the maximum height of your minibuffer, such as
configured by `ivy-height' and similar variables that configure packages
like `vertico' and `helm'.  Transient window heights are more dynamic."
  :type 'integer
  :group 'scrolling)

;; You would think we need one restore point per window.  However, there seems
;; to be a default behavior where window points in non-selected windows are
;; restored all the time.  This behavior only becomes apparent after moving
;; them.

(defvar sinister-stillness--restore nil
  "Where to restore selected buffer point.
List of BUFFER WINDOW SAFE-MARKER and RESTORE-MARKER.")

(defun sinister-stillness--enter (&rest _)
  "Adjust window points to prevent implicit scrolling."
  (unless (> (minibuffer-depth) 1)
    (let ((windows (window-at-side-list
                    (window-frame (selected-window))
                    'bottom))
          ;; height of default lines
          (frame-char-height (frame-char-height
                              (window-frame (selected-window)))))
      (while-let ((w (pop windows)))
        (with-current-buffer (window-buffer w)
          ;; Counting line height would be more correct.  In general, lines are
          ;; taller but not shorter than the default, so this is a conservative
          ;; approximation that treats all lines as the default height.
          (let* ((current-line (line-number-at-pos (window-point w)))
                 (end-line (line-number-at-pos (window-end w)))
                 (window-pixel-height (window-pixel-height w))
                 (window-used-height (cdr (window-text-pixel-size
                                           w (window-start w) (window-end w))))
                 (margin-height (* frame-char-height sinister-stillness-margin))
                 (unsafe-height (- window-used-height
                                   (- window-pixel-height margin-height)))
                 (unsafe-lines (+ 2 (ceiling (/ unsafe-height frame-char-height))))
                 (exceeded-lines (- unsafe-lines (- end-line current-line))))
            (when (> exceeded-lines 0)
              ;;  save value for restore
              (let* ((buffer (window-buffer w))
                     (restore-marker (let ((marker (make-marker)))
                                       ;; XXX this may error?
                                       (set-marker marker (window-point w)
                                                   buffer)))
                     (safe-point (progn
                                   (goto-char restore-marker)
                                   ;; XXX goes up too many lines when skipping
                                   ;; wrapped lines
                                   (ignore-error (beginning-of-buffer
                                                  end-of-buffer)
                                     (forward-line (- exceeded-lines)))
                                   (end-of-line)
                                   (point))))
                (set-window-point w safe-point)
                (when (eq w (minibuffer-selected-window))
                  (let ((safe-marker (make-marker)))
                    (set-marker safe-marker safe-point buffer)
                    (setq sinister-stillness--restore
                          (list buffer w safe-marker restore-marker))))
                (goto-char (marker-position restore-marker))))))))))

(defun sinister-stillness--exit ()
  "Restore window points that were rescued from implicit scrolling."
  (when (and sinister-stillness--restore
             (= (minibuffer-depth) 1)
             (null (transient-active-prefix)))
    (when-let* ((restore sinister-stillness--restore)
                (buffer (pop restore))
                (w (pop restore))
                (safe-marker (pop restore))
                (restore-marker (pop restore)))
      (when (and (window-live-p w)
                 (eq (window-buffer w) buffer)
                 (= (window-point w) (marker-position safe-marker)))
        (goto-char restore-marker)
        (set-window-point w restore-marker))
      (set-marker restore-marker nil)
      (set-marker safe-marker nil)
      (setq sinister-stillness--restore nil))))

;;;###autoload
(define-minor-mode sinister-stillness-mode
  "Guard the point from unintended and stupid scrolling.
One of the most annoying things about preferring `split-window-left' or
horizontal splits in general is the automatic scrolling that occurs when
using extremely popular packages like Vertico, Ivy, Helm, basically
anything but the default completions.  For every single window with a
window point that will be obsrurred by the minibuffer, the default is to
scroll to keep the window on screen, then to scroll to put the window
back.  A chain of such minibuffer commands will drive you absolutely
insane with full frame scrolling and different amounts of scroll in
every window.  It is torture.

This behavior is an intentional sabotage by the ruthless, self-righteous
cult of radicals who prefer you to memorize every symbol and use tab
completion.  They favor the terminal and 80 character width frames with
horizontal splits.  They intend for this incessent automatics scrolling
to drive you insane.  It is one of their many tools of enforcing
conformity of vertical splits upon you.  It is their will to exile the
graphical frontend users to Shakuras.

In exile on the tranquil plains of the endless midnight on Shakuras, you
will complete the shadow walk.  Alone, it is said that those of our kind
suffer, separated from the glory of the Khala.  But none of us are every
truly alone.  Our programmer hearts are bound by completions, 4k
monitors.  Transient is raised in the name of the many, who generation
after generation CHOOSE the mantle of...  DARK TEMPLAR!"
  :group 'pmx-no-herky-jerk
  :global t
  (cond
   (sinister-stillness-mode
    (add-hook 'minibuffer-setup-hook #'sinister-stillness--enter)
    (add-hook 'minibuffer-exit-hook #'sinister-stillness--exit))
   (t
    (remove-hook 'minibuffer-setup-hook #'sinister-stillness--enter)
    (remove-hook 'minibuffer-exit-hook #'sinister-stillness--exit))))

;; TODO integrate auto window balancing

(defun sinister-split-window-conservatively (&optional window)
  "Split WINDOW right and only if absolutely necessary.
Only split if there is no split, and only split into left & right
windows.  If no window is specified then WINDOW defaults to output of
`selected-window'.  `split-width-threshold' is observed."
  (interactive)
  (let ((window (or window (selected-window))))
    (when (and
           (window-splittable-p window t)
           (= (length (window-list)) 1))
      (with-selected-window window
        (split-window-right)))))

;;;###autoload

(defun sinister-misc-settings ()
  "The time has come to sever your windows, dividing left from right.
Maintained in this function is a body of settings that favor those who
split their windows horizontally.  It is not customizeable because each
setting is itself a custom option.  This function documents as much as
it abstracts over the preference for splitting the windows left and
right.

Since the Aeon of Strife, the Judicators have ruled systematically to
the detriment of all who dare question their so-called right way of
wielding Emacs. Through the blindness of their pride and their
unwavering faith in the Khala, they have grown corrupted by the will of
Amon.  As they have condemned us and abandoned our homeworld, so must we
forsake them."
  (setopt warning-display-at-bottom nil)
  (setopt split-height-threshold nil)
  (setopt ediff-split-window-function #'split-window-horizontally)
  (setopt split-width-threshold (* 2 (default-value 'fill-column)))
  (when (eq split-window-preferred-function #'split-window-sensibly)
    (setopt split-window-preferred-function #'split-window-right)))

(provide 'sinister)

;;; sinister.el ends here
