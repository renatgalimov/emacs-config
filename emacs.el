(load-theme 'tango-dark)

(delete-selection-mode t)
(require 'tls)
(setq gnutls-algorithm-priority "NORMAL:-VERS-TLS1.3")
(push "/usr/local/etc/libressl/cert.pem" gnutls-trustfiles)
(require 'package)

(let* ((no-ssl (and (memq system-type '(windows-nt ms-dos))
                    (not (gnutls-available-p))))
       (proto (if no-ssl "http" "https")))
  ;; Comment/uncomment these two lines to enable/disable MELPA and MELPA Stable as desired
  (add-to-list 'package-archives '("org" . "http://orgmode.org/elpa/") t)
  (add-to-list 'package-archives (cons "melpa" (concat proto "://melpa.org/packages/")) t)
  (add-to-list 'package-archives (cons "melpa-stable" (concat proto "://stable.melpa.org/packages/")) t)
  (when (< emacs-major-version 24)
    ;; For important compatibility libraries like cl-lib
    (add-to-list 'package-archives (cons "gnu" (concat proto "://elpa.gnu.org/packages/")))))

(package-initialize)
(package-refresh-contents)

(unless (condition-case nil (require 'use-package) (error nil))
  (package-install 'use-package)
  )

(use-package request :ensure t :pin "melpa")
(use-package request-deferred :ensure t :pin "melpa")

(set-fontset-font t 'symbol "Apple Color Emoji")
(set-fontset-font t 'symbol "Noto Color Emoji" nil 'append)

(add-to-list 'load-path "~/emacs/site-packages")

(setq ring-bell-function 'ignore)
(server-start)
(tool-bar-mode 0)
(scroll-bar-mode 0)
(menu-bar-mode 0)
(setq inhibit-startup-message t)
(setq scroll-conservatively 50)
(setq scroll-margin 4)
(show-paren-mode t)
(set-language-environment 'UTF-8)
(set-terminal-coding-system 'utf-8)
(set-keyboard-coding-system 'utf-8)
(prefer-coding-system 'mule-utf-8)
(setq-default indent-tabs-mode nil)
(setq-default tab-width 4)
(add-hook 'before-save-hook 'delete-trailing-whitespace)

(setq lsp-keymap-prefix "C-c C-l")

(load-file "~/emacs/rc/flycheck.el")
(load-file "~/emacs/rc/lsp.el")
(load-file "~/emacs/rc/docker.el")
(load-file "~/emacs/rc/autosave.el")
(load-file "~/emacs/rc/cucumber.el")
(load-file "~/emacs/rc/misc.el")
(load-file "~/emacs/rc/kubernetes.el")
(load-file "~/emacs/rc/magit.el")
(load-file "~/emacs/rc/helm.el")
(load-file "~/emacs/rc/multiple-cursors.el")
(load-file "~/emacs/rc/projectile.el")
(load-file "~/emacs/rc/python.el")
(load-file "~/emacs/rc/eshell.el")
(load-file "~/emacs/rc/c++.el")
(load-file "~/emacs/rc/yasnippet.el")
(load-file "~/emacs/rc/yaml.el")
(load-file "~/emacs/rc/org.el")
(load-file "~/emacs/rc/ledger.el")
(load-file "~/emacs/rc/doom.el")
(load-file "~/emacs/rc/elisp.el")

;; (load-file "~/emacs/rc/sudo.el")
;; (load-file "~/emacs/rc/web.el")
;; (load-file "~/emacs/rc/coffee.el")
;; (load-file "~/emacs/rc/rust.el")
;; (load-file "~/emacs/rc/elm.el")
;; (load-file "~/emacs/rc/nose.el")
;; (load-file "~/emacs/rc/go.el")
;; (load-file "~/emacs/rc/company.el")

(use-package exec-path-from-shell :ensure t
             :init
             (when (memq window-system '(mac ns x))
               (exec-path-from-shell-initialize)
               (exec-path-from-shell-copy-env "PYTHONPATH")
               (exec-path-from-shell-copy-env "PATH")
               )
             )

(defun risky-local-variable-p (sym &optional _ignored) nil)
(add-to-list 'safe-local-variable-values
             '(nose-test-command . "./bin/test.sh"))

(defun eshell/some-buffer (buffer)
  (with-current-buffer buffer
    (buffer-string)))

(global-set-key "\C-s" 'swiper)
(global-set-key (kbd "C-<") 'mc/mark-previous-like-this)
(global-set-key (kbd "C->") 'mc/mark-next-like-this)
(global-set-key (kbd "C-c <down>")  'windmove-down)
(global-set-key (kbd "C-c <left>")  'windmove-left)
(global-set-key (kbd "C-c <right>") 'windmove-right)
(global-set-key (kbd "C-c <up>")    'windmovppe-up)
(global-set-key (kbd "C-c C-<") 'mc/mark-all-like-this)
(global-set-key (kbd "C-c C-y") 'wsl-paste)
(global-set-key (kbd "C-c s") 'helm-do-ag-project-root)
(global-set-key (kbd "C-c t") 'window-toggle-split-direction)
(global-set-key (kbd "C-h C-s") 'hs-toggle-hiding)
(global-set-key (kbd "C-h s") 'helm-semantic)
(global-set-key (kbd "C-x C-b") 'helm-mini)
(global-set-key (kbd "C-x C-f") 'helm-find-files)
(global-set-key (kbd "M-x") 'helm-M-x)
(global-set-key (kbd "ESC M-SPC") 'helm-mark-ring)
(global-set-key (kbd "ESC M-f") 'ffap)
(global-set-key (kbd "M-w") 'wsl-kill-ring-save)
(global-set-key (kbd "\e\ems") 'magit-status)
(global-set-key (kbd "\e\emk") 'kubernetes-overview)
(global-set-key (kbd "C-c RET") 'yafolding-toggle-element)
(global-set-key (kbd "C-c C-j") 'yafolding-toggle-all)
(projectile-mode)

(setq phabricator-fetch-api-url "https://ph.wireload.net/api")
(setq phabricator-fetch-user-phid "renat2017")
