(defun ct/send-notification (title msg)
  (let ((notifier-path (executable-find "emacs-notifier")))
    (start-process
     "Appointment"
     "*Appointment Alert*"
     notifier-path
     msg
     title)))

(defun ct/appt-display-native (min-to-app new-time msg)
  (ct/send-notification
   (format "Appointment in %s minutes" min-to-app)
   (format "%s" msg)))

(require 'appt)
(setq appt-time-msg-list nil ;; clear existing appt list
      appt-display-interval '5 ;; warn every 5 minutes from t - appt-message-warning-time
      appt-message-warning-time '15
      appt-display-mode-line nil ;; Don't show in modeline
      appt-display-format 'window ;; Pass warning to the designated window function
      appt-disp-window-function (function ct/appt-display-native))

(after! org
  (appt-activate 1) ;; activate appointment notification
  (org-agenda-to-appt) ;; generate appointment list on emacs launch
  (run-at-time "24:01" 3600 'org-agenda-to-appt) ;; update appts hourly
  (add-hook 'org-finalize-agenda-hook 'org-agenda-to-appt) ;; update appt list on agenda view
  )

(after! vdirel
        (setq vdirel-repository "~/.local/state/vdirs/contacts/nextcloud/contacts"))

(after! notmuch
        (setq notmuch-fcc-dirs
              '(
                (".*" . "migadu/Sent"))) ;; Save sent emails to "Sent" dir
        )
