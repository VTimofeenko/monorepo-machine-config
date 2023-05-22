((org-mode . ((eval . (defun local-proj-detangle-all()
                        "Description of your custom function."
                        ;; Your function implementation goes here
                        (interactive)
                        (let ((previous-value org-src-window-setup))
                          ;; temporarily break org-src-window-setup, otherwise detangle creates unneeded frames
                          (setq org-src-window-setup 'nil)

                          (mapcar #'org-babel-detangle (directory-files-recursively "." ".*\.nix"))
                          ;; revert org-src-window-setup
                          (setq org-src-window-setup previous-value))))
              (eval . (defun local-proj-tangle-format-detangle()
                        "Function that tangles all src blocks, runs nix fmt and detangles the src blocks back"
                        (interactive)
                        (org-babel-tangle)
                        (shell-command "nix fmt")
                        (local-proj-detangle-all))))))
