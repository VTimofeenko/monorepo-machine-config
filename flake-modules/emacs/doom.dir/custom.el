(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(safe-local-variable-values
   '((eval defun local-proj-tangle-format-detangle nil "Function that tangles all src blocks, runs nix fmt and detangles the src blocks back"
           (interactive)
           (org-babel-tangle)
           (shell-command "nix fmt")
           (local-proj-detangle-all))
     (eval defun local-proj-detangle-all nil "Description of your custom function."
           (interactive)
           (let
               ((previous-value org-src-window-setup))
             (setq org-src-window-setup 'nil)
             (mapcar #'org-babel-detangle
                     (directory-files-recursively "." ".*.nix"))
             (setq org-src-window-setup previous-value))))))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(line-number ((t (:foreground "#A1A19A"))))
 '(line-number-current-line ((t (:foreground "#9A70A4")))))
