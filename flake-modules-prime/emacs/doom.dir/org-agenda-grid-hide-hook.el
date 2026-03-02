;;; org-agenda-grid-hide-hook.el --- Hide agenda time grids for occupied time slots -*- lexical-binding: t; -*-
;;
;; Copyright (C) 2024 Vladimir Timofeenko
;;
;; Author: Vladimir Timofeenko <id@vtimofeenko.com>
;; Maintainer: Vladimir Timofeenko <id@vtimofeenko.com>
;; Created: October 15, 2024
;; Modified: October 15, 2024
;; Version: 1.0
;; Keywords: calendar
;; Package-Requires: ((emacs "27.1") (dash "2.19.1"))
;;
;; This file is not part of GNU Emacs.
;;
;;; Commentary:
;;
;;  This package provides a hook for org agenda that hides the time grids located in a span that is occupied by a headline.
;;
;;  Example:
;;
;;  Given this org-agenda-time-grid configuration:
;;
;;  ((daily today require-timed)
;;   (800 1000 1200 1400 1600 1800 2000)
;;   " ┄┄┄┄┄ " "┄┄┄┄┄┄┄┄┄┄┄┄┄┄┄")
;;
;;  And these headings:
;;
;;  * TODO Foo
;;  SCHEDULED: <2024-10-15 08:00-14:00>
;;
;;  This hook will make the agenda display:
;;
;;  8:00-14:00  Foo
;;  9:46 <- now
;;  14:00 ---------
;;  ...
;;
;;  By default agenda will display something along the lines of:
;;
;;  8:00-14:00  Foo
;;  9:46 <- now
;;  10:00 ---------
;;  12:00 ---------
;;  14:00 ---------
;;  ...
;;
;;  Note: author disclaims any knowledge of elisp and the code should be used for entertainment purposes only.
;;
;;; Code:

(require 'org)
(require 'org-ql)
(require 'dash)

;; TODO: implement as a mode?
;; (define-minor-mode org-agenda-grid-hide-hook-mode
;;   "Get your foos in the right places."
;;   :init-value nil
;;   ; group org?  Look at evil-org-agenda-mode
;;   :lighter " hiding occupied grid lines on org agenda")

(defun org-agenda-grid-hide-hook-f ()
  (let*
      ((occupied-timestamps
        (-->
         (org-ql-select
          'org-agenda-files ; Searches through all agenda files
          '(ts :on today) ; Query headlines with scheduled dates
          :action
          (lambda ()
            (->>
             (let* ((scheduled-time (org-entry-get (point) "SCHEDULED"))
                    (timestamp (org-entry-get (point) "TIMESTAMP"))
                    (determined-timestamp (or scheduled-time timestamp))
                    (parsed-timestamp
                     (when
                      determined-timestamp
                      (org-timestamp-from-string determined-timestamp)))
                    (hour-start
                     (plist-get (-second-item parsed-timestamp) :hour-start))
                    (hour-end
                     (plist-get (-second-item parsed-timestamp) :hour-end))
                    ; TODO: Maybe move subtraction logic here
                    ; Logic:
                    ; If hour-start == hour-end -- do nothing
                    ; Otherwise if minute-end > 0 -- do nothing
                    ;   Otherwise set the hour-end--
                    )
               (list hour-start hour-end)) ;; end of let*
             (--filter (not (equal it nil))) ;; removes nils
             )))
         (-distinct it) (remove nil it)
         (mapcan
          (lambda (y) ; Produces continuous list of hour stamps
            (-->
             y (apply #'number-sequence it)
             (-drop-last 1 it) ; The generated list will exclude the last hour. This is done so that there could be a grid _after_ an event
             (mapcar (lambda (x) (* x 100)) it) ; Turn into hours
             ))
          it)
         ;(message it)
         )))
    (setq org-agenda-time-grid
          (-update-at
           1
           (lambda (x) (-difference x occupied-timestamps))
           org-agenda-time-grid))))

;;;###autoload
(add-hook 'org-agenda-mode-hook 'org-agenda-grid-hide-hook-f)

(provide 'org-agenda-grid-hide-hook)
;;; org-agenda-grid-hide-hook.el ends here

;; TODO: maybe rename this, dropping "hook" postfix and keep it only for the key function

;; FIXME: this causes bindings to fail when initially opening the agenda. This probably has something to do with hook ordering?
