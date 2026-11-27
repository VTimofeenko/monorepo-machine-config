;;; excalidash.el --- org-mode preview integration for ExcaliDash -*- lexical-binding: t; -*-

(require 'url)
(require 'json)

(defvar excalidash-base-url "http://localhost:6767/api"
  "Base URL of the ExcaliDash backend, reachable via the frontend's /api proxy.")

(defvar excalidash-api-key nil
  "Optional API key. Leave nil when the instance has auth disabled (dev/local).")

(defun excalidash--request (path)
  "GET PATH under `excalidash-base-url'; return (CONTENT-TYPE . BODY).
BODY is a unibyte string of the raw response bytes.  Signals an error on
any non-2xx status, so auth failures don't masquerade as empty results."
  (let* ((url (concat excalidash-base-url path))
         (url-request-extra-headers
          (when excalidash-api-key
            `(("Authorization" . ,(concat "Bearer " excalidash-api-key)))))
         (buf (url-retrieve-synchronously url t t 10)))
    (unless buf (error "excalidash: no response from %s" url))
    (with-current-buffer buf
      (unwind-protect
          (let ((status (bound-and-true-p url-http-response-status))
                (ctype (bound-and-true-p url-http-content-type)))
            (set-buffer-multibyte nil)
            (goto-char (point-min))
            (unless (re-search-forward "\r?\n\r?\n" nil t)
              (error "excalidash: malformed HTTP response from %s" url))
            (let ((body (buffer-substring-no-properties (point) (point-max))))
              (unless (and (integerp status) (<= 200 status 299))
                (error "excalidash: HTTP %s from %s: %s" status url
                       (truncate-string-to-width
                        (decode-coding-string body 'utf-8) 200)))
              (cons ctype body)))
        (kill-buffer buf)))))

(defun excalidash--get (path)
  "Fetch PATH under `excalidash-base-url' and return the parsed JSON body."
  (let ((json-object-type 'plist)
        (json-key-type 'keyword))
    (json-read-from-string
     (decode-coding-string (cdr (excalidash--request path)) 'utf-8))))

(defun excalidash--inline-file-refs (svg)
  "Replace server-relative /api/files/... image refs in SVG with data URLs.
Since ExcaliDash 0.7.0 the backend interns embedded images and rewrites the
preview to point at /api/files/<drawing>/<file>, which a local SVG file
can't resolve."
  (replace-regexp-in-string
   "/api\\(/files/[^\"' )]+\\)"
   (lambda (match)
     ;; replace-regexp-in-string reuses the match data after we return.
     (let ((file-path (match-string 1 match)))
       (save-match-data
         (condition-case err
             (let* ((resp (excalidash--request file-path))
                    (ctype (or (car resp) "application/octet-stream")))
               (concat "data:" ctype ";base64,"
                       (base64-encode-string (cdr resp) t)))
           (error (message "excalidash: could not inline %s: %s"
                           match (error-message-string err))
                  match)))))
   svg t t))

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
      (let ((path (excalidash--preview-path drawing-id))
            (coding-system-for-write 'utf-8))
        (with-temp-file path (insert (excalidash--inline-file-refs svg)))
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
