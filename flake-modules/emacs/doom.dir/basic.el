(use-package! emacs
  :init
  (setq scroll-margin 5)
  (setq inhibit-startup-screen t)
  (blink-cursor-mode 0)

  ;; TODO: auto-gen from nix
  (setq user-full-name "Vladimir Timofeenko"
        user-mail-address "id@vtimofeenko.com")

  (setq doom-theme 'doom-ir-black)

  (setq display-line-numbers-type 'relative)
  (setq display-line-numbers-type 'visual)

  ;; TODO: auto-gen from nix theme
  (custom-set-faces!
    '(line-number-current-line :foreground "#9A70A4")
    '(line-number :foreground "#A1A19A"))
  ;; Make the relative numbers disregard folds
  (setq datetime-timezone #'US/Pacific)
  ;; Needs to be set in advance
  (setq org-directory "~/org/")
  (setq ring-bell-function 'ignore))
