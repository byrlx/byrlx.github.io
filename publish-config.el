;;;(load-file "./ox-html.el")  
;;;(load-file "./ox-rss.el")  
;;; orgblog-publisher nothing

(add-to-list 'load-path "~/.emacs.d/")
(require 'org-jekyll-mode)

(require 'org-publish)
;;;(require 'ox-rss)

(setq org-publish-project-alist
      '(
        ;; These are the main web files
        ("org-notes"
         :base-directory "./org/post" ;; Change this to your local dir
         :base-extension "org"
         :publishing-directory "./_posts"
         :body-only t
         :recursive nil
         :publishing-function org-publish-org-to-html
         :headline-levels 4       ; Just the default for this project.
         :section-numbers nil
         :auto-preamble t
         :table-of-contents nil
         )
      ))

(defun myweb-publish nil
  "Publish myweb."
  (interactive)
  (org-publish-all))

(myweb-publish)

