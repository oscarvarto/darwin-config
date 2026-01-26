;;; my-org-tools.el --- Utilities to flatten nested Org lists -*- lexical-binding: t; no-byte-compile: t;-*-

(require 'org)
(require 'org-element)

(defun my/org--element-text (el)
  "Return trimmed text contents of element EL from the current buffer."
  (let ((beg (org-element-property :contents-begin el))
        (end (org-element-property :contents-end el)))
    (when (and beg end)
      (string-trim (buffer-substring-no-properties beg end)))))

(defun my/org--sanitize-cell (s)
  "Sanitize string S for safe insertion into an Org table cell."
  (when s
    (let ((s (replace-regexp-in-string "|" "\\\vert{}" s)))
      ;; Collapse consecutive blank lines
      (setq s (replace-regexp-in-string "\n\{2,\}" "\n" s))
      ;; Replace newlines with explicit LaTeX line breaks so export is robust
      (setq s (replace-regexp-in-string "\n" " @@latex:\\\\@@ " s))
      (string-trim s))))

(defun my/org--item-lines (item depth)
  "Collect flattened lines from list ITEM. DEPTH increases for nested lists."
  (let (acc)
    (dolist (child (org-element-contents item))
      (pcase (org-element-type child)
        ('paragraph
         (let ((txt (my/org--element-text child)))
           (when (and txt (not (string-empty-p txt)))
             (push (if (> depth 0)
                       (format "%s- %s" (make-string (* 2 depth) ?\s) txt)
                     txt)
                   acc))))
        ('plain-list
         (dolist (sub (org-element-contents child))
           (when (eq (org-element-type sub) 'item)
             (setq acc (append acc (my/org--item-lines sub (1+ depth)))))))
        (_ nil)))
    (nreverse acc)))

(defun my/org--first-plain-list-in (beg end)
  "Return the widest plain-list element between BEG and END, or nil."
  (let* ((ast (org-element-parse-region beg end nil))
         found)
    (org-element-map ast 'plain-list
      (lambda (pl) (unless found (setq found pl)))
      nil nil 'headline)
    found))

(defun my/org--bounds-of-list-at-point ()
  "Return cons (BEG . END) for the plain-list at point, or nil."
  (let ((ctx (org-element-context)))
    (catch 'done
      (while ctx
        (when (eq (org-element-type ctx) 'plain-list)
          (throw 'done (cons (org-element-property :begin ctx)
                             (org-element-property :end ctx))))
        (setq ctx (org-element-property :parent ctx))))))

;;;###autoload
(defun my/org-list-to-tabularx (&optional replace)
  "Convert the first-level items of the list at point (or region/subtree) to a tabularx table.

When called with prefix argument REPLACE (C-u), replace the list with the table.
Otherwise, insert the table below the list. The table has columns: Step, Action, Expected Result.
Nested list content is flattened and joined with explicit LaTeX line breaks."
  (interactive "P")
  (save-excursion
    (let* ((region-active (use-region-p))
           (beg (if region-active (region-beginning)
                  (or (when (org-before-first-heading-p)
                        (point-min))
                      (save-excursion (org-back-to-heading t) (point)))))
           (end (if region-active (region-end)
                  (or (save-excursion
                        (when (org-before-first-heading-p)
                          (point-max)))
                      (save-excursion (org-end-of-subtree t t) (point)))))
           (list-bounds (or (and (not region-active) (my/org--bounds-of-list-at-point))
                            (let ((pl (my/org--first-plain-list-in beg end)))
                              (when pl (cons (org-element-property :begin pl)
                                             (org-element-property :end pl)))))))
      (unless list-bounds
        (user-error "No list found at point, in region, or subtree"))
      (let* ((lbeg (car list-bounds))
             (lend (cdr list-bounds))
             (ast (org-element-parse-region lbeg lend nil))
             (items (seq-filter (lambda (el) (eq (org-element-type el) 'item))
                                (org-element-contents ast)))
             (rows
              (cl-loop for idx from 1
                       for it in items
                       for lines = (my/org--item-lines it 0)
                       for joined = (my/org--sanitize-cell (string-join lines "\n"))
                       collect (list (number-to-string idx)
                                     (or joined "")
                                     ""))))
        ;; Build table text
        (let ((table (concat
                      "#+ATTR_LATEX: :environment tabularx :width \\textwidth :align |l|X|X|\n"
                      "| Step | Action | Expected Result |\n"
                      "|------+--------+-----------------|\n"
                      (mapconcat (lambda (r)
                                   (format "| %s | %s | %s |" (nth 0 r) (nth 1 r) (nth 2 r)))
                                 rows
                                 "\n")
                      "\n")))
          (goto-char lend)
          (if replace
              (progn
                (delete-region lbeg lend)
                (insert table))
            (save-excursion
              (goto-char lend)
              (open-line 1)
              (forward-line 1)
              (insert table))))))))

;;;###autoload
(defun my/org-list-to-headings (&optional replace)
  "Promote the list at point (or in region/subtree) into headings.

Each top-level list item becomes a new heading at the next level below the
current heading (or level 1 if outside a heading). The first line of each
item becomes the heading title; remaining lines/nested items become the
content under that heading. With prefix arg REPLACE (C-u), replace the list,
otherwise insert the new headings below the list."
  (interactive "P")
  (save-excursion
    (let* ((region-active (use-region-p))
           (beg (if region-active (region-beginning)
                  (or (when (org-before-first-heading-p)
                        (point-min))
                      (save-excursion (org-back-to-heading t) (point)))))
           (end (if region-active (region-end)
                  (or (save-excursion
                        (when (org-before-first-heading-p)
                          (point-max)))
                      (save-excursion (org-end-of-subtree t t) (point)))))
           (list-bounds (or (and (not region-active) (my/org--bounds-of-list-at-point))
                            (let ((pl (my/org--first-plain-list-in beg end)))
                              (when pl (cons (org-element-property :begin pl)
                                             (org-element-property :end pl))))))
           (base-level (if (org-before-first-heading-p)
                           0
                         (save-excursion (org-back-to-heading t)
                                         (car (org-heading-components))))))
      (unless list-bounds
        (user-error "No list found at point, in region, or subtree"))
      (let* ((lbeg (car list-bounds))
             (lend (cdr list-bounds))
             (ast (org-element-parse-region lbeg lend nil))
             (items (seq-filter (lambda (el) (eq (org-element-type el) 'item))
                                (org-element-contents ast)))
             (heading-level (max 1 (1+ base-level)))
             (stars (make-string heading-level ?*))
             (blocks
              (mapcar
               (lambda (it)
                 (let* ((lines (my/org--item-lines it 0))
                        (title (or (car lines) "Item"))
                        (body-lines (cdr lines))
                        (body (if body-lines (string-join body-lines "\n") "")))
                   (concat stars " " title "\n"
                           (unless (string-empty-p body)
                             (concat body "\n")))))
               items))
             (out (string-join blocks "\n")))
        (goto-char lend)
        (if replace
            (progn
              (delete-region lbeg lend)
              (insert out))
          (save-excursion
            (goto-char lend)
            (open-line 1)
            (forward-line 1)
            (insert out)))))))

(provide 'my-org-tools)
