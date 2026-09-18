;;; org-inline-comment.el --- Fold multiline @@comment:...@@ blocks in org-mode -*- lexical-binding: t; -*-

;;; Commentary:
;;; - Allows writing inline comments in org-mode files.
;;; - Has org-toggle-link-display style folding ability

;;; Code:
(require 'org)

(defgroup org-inline-comment nil
  "Fold multiline @@comment:...@@ blocks in `org-mode'."
  :group 'org
  :prefix "org-inline-comment-")

(defcustom org-inline-comment-marker "@@comment:...@@"
  "Text shown in place of a folded comment block."
  :type 'string
  :group 'org-inline-comment)

(defconst org-inline-comment--regexp
  ;; "[^z-a]" matches any character, including newlines, since the
  ;; character range z-a is empty and its negation is therefore everything.
  "@@comment:\\(?:[^z-a]*?\\)@@"
  "Regexp matching `@@comment:...@@' blocks, including newlines.")

(defvar-local org-inline-comment--overlays nil
  "Overlays created by `org-inline-comment-mode' in the current buffer.")

(defvar-local org-inline-comment--expand-all nil
  "When non-nil, all comment overlays stay revealed regardless of point.
Toggled by `org-inline-comment-toggle-all', mirroring
`org-toggle-link-display'.")

(defun org-inline-comment--clear ()
  "Delete all comment-fold overlays in the current buffer."
  (mapc #'delete-overlay org-inline-comment--overlays)
  (setq org-inline-comment--overlays nil))

(defun org-inline-comment--make-overlay (beg end)
  "Create a foldable comment overlay from BEG to END."
  (let ((ov (make-overlay beg end nil nil nil)))
    (overlay-put ov 'org-inline-comment t)
    (overlay-put ov 'face 'font-lock-comment-face)
    (overlay-put ov 'evaporate t)
    (push ov org-inline-comment--overlays)
    ov))

(defun org-inline-comment--rescan (&rest _)
  "Recreate comment overlays for the whole buffer and refresh their fold state."
  (org-inline-comment--clear)
  (save-excursion
    (goto-char (point-min))
    (while (re-search-forward org-inline-comment--regexp nil t)
      (org-inline-comment--make-overlay (match-beginning 0) (match-end 0))))
  (org-inline-comment--update))

(defun org-inline-comment--update (&rest _)
  "Reveal the comment overlay point is inside; fold the rest.
When `org-inline-comment--expand-all' is set, reveal all of them instead."
  (dolist (ov org-inline-comment--overlays)
    (when (overlay-buffer ov)
      (overlay-put
       ov 'display
       (unless (or org-inline-comment--expand-all
                    (and (>= (point) (overlay-start ov)) (<= (point) (overlay-end ov))))
         org-inline-comment-marker)))))

;;;###autoload
(define-minor-mode org-inline-comment-mode
  "Fold `@@comment:...@@' blocks, revealing them when point enters."
  :lighter " ICmt"
  (if org-inline-comment-mode
      (progn
        (add-hook 'post-command-hook #'org-inline-comment--update nil t)
        (add-hook 'after-change-functions #'org-inline-comment--rescan nil t)
        (org-inline-comment--rescan))
    (remove-hook 'post-command-hook #'org-inline-comment--update t)
    (remove-hook 'after-change-functions #'org-inline-comment--rescan t)
    (org-inline-comment--clear)))

(add-hook 'org-mode-hook #'org-inline-comment-mode)

;;;###autoload
(defun org-inline-comment-insert ()
  "Insert an `@@comment:...@@' template at point, leaving point inside it."
  (interactive)
  (insert "@@comment:@@")
  (backward-char 2)
  (org-inline-comment--update))

;;;###autoload
(defun org-inline-comment-toggle-all ()
  "Toggle all `@@comment:...@@' blocks between folded and revealed.
Like `org-toggle-link-display', but for inline comments: while toggled
on, point entering/leaving a block no longer folds or reveals it."
  (interactive)
  (setq org-inline-comment--expand-all (not org-inline-comment--expand-all))
  (org-inline-comment--update)
  (message "Inline comments %s" (if org-inline-comment--expand-all "expanded" "folded")))

(map! :map org-mode-map
      :i "C-c ;" #'org-inline-comment-insert
      :n "C-c ;" #'org-inline-comment-toggle-all)

(provide 'org-inline-comment)
;;; org-inline-comment.el ends here
