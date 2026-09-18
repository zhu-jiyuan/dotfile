;;; init.el --- Personal Emacs configuration -*- lexical-binding: t; -*-

(when (fboundp 'tool-bar-mode)
  (tool-bar-mode 0))
(menu-bar-mode 0)
(add-to-list 'default-frame-alist '(font . "JetBrainsMono Nerd Font 13"))
(when (display-graphic-p)
  (set-frame-font "JetBrainsMono Nerd Font 13" nil t))
(when (fboundp 'scroll-bar-mode)
  (scroll-bar-mode 0))
(show-paren-mode 1)

(electric-pair-mode t)

(pixel-scroll-precision-mode t)

(column-number-mode t)
(global-display-line-numbers-mode 1)

(global-auto-revert-mode t)

(delete-selection-mode t)

;turn off startup dashboard
(setq inhibit-startup-message t)

(setq make-backup-files nil)
(setq auto-save-default nil)

(add-hook 'prog-mode-hook #'hs-minor-mode)

(defun open-my-config-file ()
  "Open this Emacs configuration."
  (interactive)
  (find-file (locate-user-emacs-file "init.el")))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("gnu"    . "https://elpa.gnu.org/packages/") t)
;(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
(package-initialize)
(require 'use-package)


(let ((dir (locate-user-emacs-file "lisp")))
  (add-to-list 'load-path (file-name-as-directory dir)))

(use-package exec-path-from-shell
  :ensure t
  :if (or (daemonp) (memq window-system '(mac ns x pgtk)))
  :custom
  (exec-path-from-shell-arguments '("-l"))
  :config
  (exec-path-from-shell-initialize))


(with-temp-message ""
  (require 'init-ui)
  (require 'init-edit)
  (require 'init-tools)
  (require 'init-org)
  )

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(cape company-box corfu doom-modeline ef-themes embark-consult envrc
	  flycheck go-mode keycast kind-icon lsp-treemacs lsp-ui magit
	  marginalia multiple-cursors mwim orderless org-contrib
	  org-modern vertico yasnippet)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )

