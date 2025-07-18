;;; turn off tool bar
(tool-bar-mode 0)
(menu-bar-mode 0)
(set-frame-font "JetBrainsMono Nerd Font 13" nil t)
(scroll-bar-mode 0)
(show-paren-mode 1)

(electric-pair-mode t)

(pixel-scroll-precision-mode t)

(add-hook 'prog-mod-hook #'show-paren-mode)

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
  (interactive)
  (find-file "~/.config/emacs/init.el"))

(require 'package)
(add-to-list 'package-archives '("melpa" . "https://melpa.org/packages/") t)
(add-to-list 'package-archives '("gnu"    . "https://elpa.gnu.org/packages/") t)
(add-to-list 'package-archives '("nongnu" . "https://elpa.nongnu.org/nongnu/") t)
(package-initialize)


(let ((dir (locate-user-emacs-file "lisp")))
  (add-to-list 'load-path (file-name-as-directory dir)))

(with-temp-message ""
  (require 'init-ui)
  (require 'init-edit)
  (require 'init-tools)
  (require 'init-org)
  ;;(require 'init-lsp)
  )

(custom-set-variables
 ;; custom-set-variables was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 '(package-selected-packages
   '(ace-window amx company-box consult counsel doom-modeline ef-themes
		embark-consult flycheck keycast magit marginalia
		minions mwim orderless org-contrib org-modern vertico)))
(custom-set-faces
 ;; custom-set-faces was added by Custom.
 ;; If you edit it by hand, you could mess it up, so be careful.
 ;; Your init file should contain only one such instance.
 ;; If there is more than one, they won't work right.
 )


