;; A very simple semantic commits implementation
;; Queries the user for the issue type and inserts it
(define-derived-mode vt-git-commit-mode text-mode "Git commit"
  (save-match-data
    (when (save-excursion (re-search-forward "\\`[\n[:space:]]*#" nil :noerror))
      (let (
            (committype (completing-read "Choose semantic commit type: "
                                         '("fix" "feat" "chore" "doc") nil t)))
        (save-excursion
          (insert (format "%s: \n" committype)))))))
(setq git-commit-major-mode 'vt-git-commit-mode)
