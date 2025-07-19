

; LSP-Mode configuration 
(use-package lsp-mode
  :ensure t
  :init
  (setq gc-cons-threshold 100000000)
  (setq lsp-auto-configure t)
  :hook (
         (js-ts-mode . lsp-deferred)
	 (rust-mode . lsp-deferred)
	 (web-mode . lsp-deferred)
	 (tsx-ts-mode . lsp-deferred)
	 ;; for which-key integration
         (lsp-mode . lsp-enable-which-key-integration))
  :commands (lsp lsp-deferred))

(use-package lsp-ui
  :ensure t
  :commands lsp-ui-mode)

(use-package lsp-treemacs
  :ensure t  
  :init (lsp-treemacs-sync-mode 1)
  :commands lsp-treemacs-errors-list)

(provide 'init-lsp)
