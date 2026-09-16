;;; excalidash.el --- org-mode preview integration for ExcaliDash -*- lexical-binding: t; -*-

(require 'url)
(require 'json)

(defvar excalidash-base-url "http://localhost:6767/api"
  "Base URL of the ExcaliDash backend, reachable via the frontend's /api proxy.")

(defvar excalidash-api-key nil
  "Optional API key. Leave nil when the instance has auth disabled (dev/local).")

(defun excalidash--get (path)
  "Fetch PATH under `excalidash-base-url' and return the parsed JSON body."
  (let* ((url (concat excalidash-base-url path))
         (url-request-extra-headers
          (when excalidash-api-key
            `(("Authorization" . ,(concat "Bearer " excalidash-api-key))))))
    (with-current-buffer (url-retrieve-synchronously url t t 10)
      (goto-char (point-min))
      (unless (re-search-forward "\n\n" nil t)
        (error "excalidash: malformed HTTP response from %s" url))
      (prog1
          (let ((json-object-type 'plist)
                (json-key-type 'keyword))
            (json-read-from-string
             (buffer-substring-no-properties (point) (point-max))))
        (kill-buffer)))))

(defun excalidash-list-drawings ()
  "Return the list of drawings as plists (id/name/updatedAt/...)."
  (plist-get (excalidash--get "/drawings") :drawings))

(defun excalidash--preview-path (drawing-id)
  "Deterministic cache path for DRAWING-ID's preview SVG.
Stable across calls so refetching overwrites the same file, which lets
`excalidash-refresh-preview-at-point' and friends work in place."
  (expand-file-name (format "excalidash-preview-%s.svg" drawing-id)
                     temporary-file-directory))

(defun excalidash-fetch-preview (drawing-id)
  "Fetch DRAWING-ID's preview SVG, write/overwrite its cache file, return its path.
Returns nil if the drawing has no preview yet (never opened/saved in the web UI)."
  (let* ((data (excalidash--get (format "/drawings/%s/preview" drawing-id)))
         (svg (plist-get data :preview)))
    (when (and svg (not (eq svg :null)) (> (length svg) 0))
      (let ((path (excalidash--preview-path drawing-id)))
        (with-temp-file path (insert svg))
        path))))

;;;###autoload
(defun excalidash-insert-preview (drawing-id)
  "Insert an org inline-image link for DRAWING-ID's preview at point."
  (interactive
   (list (let* ((drawings (excalidash-list-drawings))
                (choices (mapcar (lambda (d) (cons (plist-get d :name) (plist-get d :id)))
                                  drawings)))
           (cdr (assoc (completing-read "Drawing: " choices nil t) choices)))))
  (if-let ((path (excalidash-fetch-preview drawing-id)))
      (progn
        (insert (format "[[file:%s]]\n" path))
        (org-display-inline-images))
    (message "No preview available for %s (never opened/saved in the web UI)" drawing-id)))

(defun excalidash--drawing-id-from-path (path)
  "Extract the drawing id encoded in a cache PATH produced by
`excalidash--preview-path', or nil if PATH isn't one of ours."
  (when (and path (string-match "excalidash-preview-\\(.+\\)\\.svg\\'" path))
    (match-string 1 path)))

;;;###autoload
(defun excalidash-refresh-preview-at-point ()
  "Refetch the preview for the excalidash image link at point and redisplay it."
  (interactive)
  (let* ((context (org-element-context))
         (path (org-element-property :path context))
         (drawing-id (excalidash--drawing-id-from-path path)))
    (unless drawing-id
      (user-error "No excalidash preview link at point"))
    (if (excalidash-fetch-preview drawing-id)
        (org-redisplay-inline-images)
      (message "No preview available for %s" drawing-id))))

;;;###autoload
(defun excalidash-refresh-all-previews ()
  "Refetch every excalidash preview link in the current buffer and redisplay."
  (interactive)
  (let ((ids nil))
    (org-element-map (org-element-parse-buffer) 'link
      (lambda (link)
        (when-let ((id (excalidash--drawing-id-from-path
                         (org-element-property :path link))))
          (push id ids))))
    (dolist (id (delete-dups ids))
      (excalidash-fetch-preview id))
    (org-redisplay-inline-images)
    (message "Refreshed %d preview(s)" (length ids))))

(provide 'excalidash)
;;; excalidash.el ends here
