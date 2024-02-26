(when (eq system-type 'darwin)
  (require 'ejc-sql)
  (setq nrepl-sync-request-timeout 60)
  (setq clomacs-httpd-default-port 8090) ; Use a port other than 8080.
  (after! org
    (add-to-list 'org-structure-template-alist
                 '("sql" . "src sql :exports both :eval no-export\n"))))
