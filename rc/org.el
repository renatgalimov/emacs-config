;;; org.el ---
;;
;; Filename: org.el
;; Description:
;; Author: Renat Galimov
;; Maintainer:
;; Created: Чт дек 17 10:04:54 2020 (+0300)
;; Version:
;; Package-Requires: ()
;; Last-Updated: Sun Jun 27 06:51:38 2021 (+0300)
;;           By: Ренат Галимов
;;     Update #: 209
;; URL:
;; Doc URL:
;; Keywords:
;; Compatibility:
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Commentary:
;;
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Change Log:
;;
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;; This program is free software: you can redistribute it and/or modify
;; it under the terms of the GNU General Public License as published by
;; the Free Software Foundation, either version 3 of the License, or (at
;; your option) any later version.
;;
;; This program is distributed in the hope that it will be useful, but
;; WITHOUT ANY WARRANTY; without even the implied warranty of
;; MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the GNU
;; General Public License for more details.
;;
;; You should have received a copy of the GNU General Public License
;; along with GNU Emacs.  If not, see <https://www.gnu.org/licenses/>.
;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;
;;; Code:

(require 'use-package)

(use-package ein :ensure t)
(use-package ob-ipython :ensure t)
(use-package ob-async :ensure t)
(use-package ob-restclient :ensure t)

(add-to-list 'load-path "~/emacs/site-packages/org-roam")

(use-package emacsql-sqlite :ensure t)
(require 'org-roam)


(defun org-roam-node-read (&optional initial-input filter-fn sort-fn require-match)
  "Read and return an `org-roam-node'.
INITIAL-INPUT is the initial prompt value.
FILTER-FN is a function to filter out nodes.
SORT-FN is a function to sort nodes.
If REQUIRE-MATCH, require returning a match."
  (let* ((nodes (org-roam-node--completions))
         (nodes (funcall (or filter-fn #'identity) nodes))
         (sort-fn (or sort-fn
                      (when org-roam-node-default-sort
                        (intern (concat "org-roam-node-sort-by-" (symbol-name org-roam-node-default-sort))))))
         (_ (when sort-fn (setq nodes (seq-sort sort-fn nodes))))
         (node (helm-comp-read
                "Node: "
                (lambda (string pred action)
                  (if (eq action 'metadata)
                      '(metadata
                        (annotation-function . (lambda (title)
                                                 (funcall org-roam-node-annotation-function
                                                          (get-text-property 0 'node title))))
                        (category . org-roam-node))
                    (complete-with-action action nodes string pred)))
                :test require-match :initial-input initial-input :buffer "*Helm Roam Node Read*")))
    (or (cdr (assoc node nodes))
        (org-roam-node-create :title node))))



(require 'org-roam-protocol)
(setq r/org-directory "~/Dropbox/org")
(setq org-roam-directory r/org-directory)
(org-roam-setup)

(defun r/org-roam--get-project-files ()
  "Return a list of org files tagged as projects."
  (mapcan 'identity (org-roam-db-query
                     [:select [files:file] :from files
                              :left :join tags
                              :on (= files:file tags:file)
                              :where (and (like tags:tags '"%project%") (not (like tags:tags '"%archive%")))
                              ])))



(defvar org-babel-eval-verbose t
  "A non-nil value makes `org-babel-eval' display.")

(setq org-babel-eval-verbose t)
(defun org-babel-eval (cmd body)
  "Run CMD on BODY.
If CMD succeeds then return its results, otherwise display
STDERR with `org-babel-eval-error-notify'."
  (let ((err-buff (get-buffer-create " *Org-Babel Error*")) exit-code)
    (with-current-buffer err-buff (erase-buffer))
    (with-temp-buffer
      (insert body)
      (setq exit-code
            (org-babel--shell-command-on-region
             (point-min) (point-max) cmd err-buff))
      (if (or (not (numberp exit-code)) (> exit-code 0)
              (and org-babel-eval-verbose (> (buffer-size err-buff) 0))) ; new condition
          (progn
            (with-current-buffer err-buff
              (org-babel-eval-error-notify exit-code (buffer-string)))
            nil)
        (buffer-string)))))

(use-package ob-ipython :ensure t)

(use-package org
  :ensure t
  :init
  (require 'ob-plantuml)
  (require 'ox-md)
  (require 'org-tempo)
  (require 'ox-pandoc)
  (require 'org-ph)
  (require 'org-crypt)
  (require 'org-protocol)

  (add-to-list 'org-modules 'org-id)

  (defun tangle-in-attach (sub-path)
    "Expand the SUB-PATH into the directory given by the tangle-dir
property if that property exists, else use the
`default-directory'."
    (expand-file-name sub-path
                      (or
                       (org-entry-get (point) "dir" 'inherit)
                       (default-directory))))

  (advice-add 'ob-ipython-auto-configure-kernels :around
              (lambda (orig-fun &rest args)
                "Configure the kernels when found jupyter."
                (when (executable-find ob-ipython-command)
                  (apply orig-fun args))))
  (org-babel-do-load-languages
   'org-babel-load-languages
   '((ipython . t)
     (plantuml . t)
     (shell . t)
     (sql . t)
     ;; other languages.
     ))

  (setq org-id-extra-files (org-roam--list-all-files))

  (setq org-clock-auto-clockout-timer (* 10 60))
  (org-clock-auto-clockout-insinuate)
  (setq org-attach-use-inheritance t)
  (setq plantuml-default-exec-mode 'jar)
  (setq org-image-actual-width nil)
  (setq plantuml-jar-path
        (cond ((eq system-type 'darwin) "/usr/local/Cellar/plantuml/1.2020.21/libexec/plantuml.jar")
              ((eq system-type 'gnu/linux) "~/.local/bin/plantuml.jar")))

  (setq plantuml-java-command
        (cond ((eq system-type 'darwin) "/usr/local/opt/openjdk/bin/java")
              ((eq system-type 'gnu/linux) "java")))

  (setq org-plantuml-jar-path plantuml-jar-path)
  (setq org-default-notes-file (expand-file-name "index.org" r/org-directory))
  (setq org-tags-column -77)
  (setq org-log-into-drawer t
        org-id-link-to-org-use-id 'use-existing)
  (add-hook 'org-mode-hook 'auto-revert-mode)
  (add-hook 'org-mode-hook 'visual-line-mode)

  ;; Making org-mode buffers more readable
  (add-hook 'org-mode-hook 'mixed-pitch-mode)
  (add-hook 'org-mode-hook 'display-fill-column-indicator-mode)
  (add-hook 'org-mode-hook (lambda () (setq left-margin-width 3 right-margin-width 2)))

  (defun org-ascii--box-string (s info)
    "Return string S with a partial box to its left.
INFO is a plist used as a communication channel."
    (let ((utf8p (eq (plist-get info :ascii-charset) 'utf-8)))
      (format (if utf8p "  ┌────\n%s\n  └────" "  ,----\n%s\n  `----")
              (replace-regexp-in-string
               "^" (if utf8p "  │ " "  | ")
               ;; Remove last newline character.
               (replace-regexp-in-string "\n[ \t]*\\'" "" s)))))
  (setq org-outline-path-complete-in-steps nil)         ; Refile in a single go
  (setq org-refile-use-outline-path t)                  ; Show full paths for refili
  (setq org-refile-use-outline-path 'file)

  (defun my-refile-targets ()
    (seq-filter
     (lambda (s)
       (and
        (not (string-prefix-p ".#" s))
        (string-suffix-p ".org" s)))
     (directory-files r/org-directory)))

  (setq org-refile-targets
        '((nil :maxlevel . 1)
          (my-refile-targets :maxlevel . 2)))

  (setq org-agenda-files `(,r/org-directory)
        org-directory r/org-directory
        org-startup-folded 'content)
  (setq org-roam-capture-templates
        '(("r" "Roam" plain "%?" :if-new (file+head "roam/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n")
           :unnarrowed t)
          ("p" "Project" plain "%?" :if-new (file+head "roam/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+roam_tags project\n\n* ${title}\n:DEADLINE: %^{Project deadline}t\n\n$?")
           :unnarrowed t)
          ("d" "Diary" plain "- %U %?" :if-new (file+head "roam/%<%Y%m%d%H%M%S>-${slug}.org" "#+title: ${title}\n#+roam_tags diary\n\n#+CAPTION: Diary record %^{Diary record date}u\n\n")
           :unnarrowed t)))

  (setq org-capture-templates
        '(("t" "Todo" entry (file org-default-notes-file)
           "* TODO %?\n  %u\n  %i\n  %a")
          ("m" "Message Response" entry (file+headline "index.org" "Message responses")
           "** %?
    :PROPERTIES:
    :URL: %(org-web-tools--get-first-url)
    :END:

    %T" :jump-to-captured)
          ("c" "Currently clocked-in" item (clock)
           "Note taken on %U\n%?")))
  (setq org-link-search-must-match-exact-headline nil)
  (defun renat-org-html-format-headline-function
      (todo _todo-type priority text tags info)
    "Format TODO keywords into HTML."
    (format "<span class=\"headline %s %s%s\">%s</span>"
            (if (member todo org-done-keywords) "done" "todo")
            (or (plist-get info :html-todo-kwd-class-prefix) "")
            (org-html-fix-class-name todo)
            (org-html-format-headline-default-function todo _todo-type priority text tags info)))
  (setq org-html-format-headline-function 'org-html-format-headline-default-function)
  (setq org-crypt-key "091AE83A9A988E1B"))


(use-package mixed-pitch :ensure t)
(use-package org-projectile
  :bind (("C-c c" . org-capture))
  :config
  (progn
    (setq org-projectile-projects-file "~/Dropbox/org/projects.org")
    (setq org-agenda-files (append org-agenda-files (org-projectile-todo-files)))
    (push (org-projectile-project-todo-entry) org-capture-templates))
  :ensure t)

(setq org-todo-keywords
      '((sequence
         "TODO(t)" "|"
         "DONE(d!)" "CANCELED(c@)" "NEGATIVE(n!)" "POSITIVE(p!)")))

(setq org-todo-keyword-faces
      '(("TODO" . org-todo)
        ("DONE" . org-done)
        ("CANDELED" . org-done)
        ("NEGATIVE" . (:foreground "cadetblue"))
        ("POSITIVE" . (:foreground "darkseagreen"))))

(use-package org-gcal
  :ensure t
  :init
  (setq org-gcal-client-id "863558406881-122rl0kfk481dcsuqmi2m96le0s3tbhv.apps.googleusercontent.com"
        org-gcal-file-alist `(("rgalimov@screenly.io" .  ,(expand-file-name "screenly-calendar.org" r/org-directory)))))

(use-package org-download
  :ensure t)

(defun org-gcal-clear-some-duplicates()
  (let ((cleared 0)
        (ids ()))
    (org-map-entries
     (lambda ()
       (let* ((properties (org-entry-properties))
              (id (assoc-default "ID" properties))
              (timestamp (org-timestamp-from-string (assoc-default "TIMESTAMP" properties)))
              (key (concat id "-" (org-timestamp-format timestamp "%s" nil) "-"  (org-timestamp-format timestamp "%s" t))))
         (if (not (member key ids))
             (setq ids (cons key ids))
           (save-excursion
             (org-mark-subtree)
             (delete-region
              (region-beginning)
              (region-end)
              )
             )
           (setq cleared (+ cleared 1)))))
     "CATEGORY=\"Screenly\"-ID=\"\""
     'agenda)
    cleared))

(defun org-gcal-clear-duplicates()
  (interactive)
  (let ((cleared (org-gcal-clear-some-duplicates)))
    (while (> cleared 0)
      (setq cleared (org-gcal-clear-some-duplicates)))))

;; (org-gcal-fetch)
(org-gcal-clear-duplicates)

(use-package org-super-agenda :ensure t
  :init
  (setq org-super-agenda-groups
        '(;; Each group has an implicit boolean OR operator between its selectors.
          (:name "Today"  ; Optionally specify section name
                 :time-grid t  ; Items that appear on the time grid
                 )  ; Items that have this TODO keyword
          ;; Set order of multiple groups at once
          (:name "Work"
                 :category "Screenly")
          (:order-multi (2 (:name "Personal"
                                  :habit t
                                  :tag "personal")))
          ;; Groups supply their own section names when none are given
          (:priority<= "B"
                       ;; Show this section after "Today" and "Important", because
                       ;; their order is unspecified, defaulting to 0. Sections
                       ;; are displayed lowest-number-first.
                       :order 1)
          ;; After the last group, the agenda will display items that didn't
          ;; match any of these groups, with the default order position of 99
          ))
  (org-super-agenda-mode))

(require 'org-yt)

(load-file "~/emacs/site-packages/sbe.el")

(use-package org-web-tools
  :ensure t
  )

(use-package org-bullets :ensure t
  :config
  (add-hook 'org-mode-hook (lambda () (org-bullets-mode 1))))

(setq org-image-actual-width nil)


;; Search

(setq helm-deft-extension '("org"))
(setq helm-deft-dir-list '("~/Dropbox/org/roam"))

;; Org QL
(use-package org-ql :ensure t
  :init
  (setq org-ql-search-directories-files-recursive t)
  )

(use-package helm-recoll
    :commands helm-recoll
    :init (setq helm-recoll-directories
                '(("default" . "~/.recoll"))))


(defun org-inline-data-image (_protocol link _description)
  "Interpret LINK as base64-encoded image data."
  (base64-decode-string link))

(org-link-set-parameters
 "img"
 :image-data-fun #'org-inline-data-image)

(defun org-image-link (protocol link _description)
  "Interpret LINK as base64-encoded image data."
  (cl-assert (string-match "\\`img" protocol) nil
             "Expected protocol type starting with img")
  (let ((buf (url-retrieve-synchronously (concat (substring protocol 3) ":" link))))
    (cl-assert buf nil
               "Download of image \"%s\" failed." link)
    (with-current-buffer buf
      (goto-char (point-min))
      (re-search-forward "\r?\n\r?\n")
      (buffer-substring-no-properties (point) (point-max)))))

(org-link-set-parameters
 "imghttp"
 :image-data-fun #'org-image-link)

(org-link-set-parameters
 "imghttps"
 :image-data-fun #'org-image-link)

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;; org.el ends here
