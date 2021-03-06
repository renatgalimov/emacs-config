(use-package helm
  :ensure t
  :init
  (add-to-list 'display-buffer-alist
               `(,(rx bos "*helm" (* not-newline) "*" eos)
                 (display-buffer-in-side-window)
                 (inhibit-same-window . t)
                 (window-height . 0.4))))

(use-package helm-projectile :ensure t
  :init
  (helm-projectile-on))
(use-package helm-flycheck :ensure t)

(defun helm-rg-project-root (&optional query)
  "Not documented, QUERY."
  (interactive)
  (let ((helm-rg-default-directory (or (projectile-project-root) default-directory)))
    (helm-rg query nil)))
