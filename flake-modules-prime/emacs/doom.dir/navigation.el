;; TODO: most used shortcuts from vim - [d, ]d, <SPC>l to look around

(map! :leader
      (:desc "Jump around" "j" #'evil-avy-goto-word-0))
