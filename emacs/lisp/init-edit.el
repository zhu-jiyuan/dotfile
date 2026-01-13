;;; edit

(use-package mwim
  :ensure t
  :bind
  ("C-a" . mwim-beginning-of-code-or-line)
  ("C-e" . mwim-end-of-code-or-line))

;; (use-package company
;;   :ensure t
;;   :init (global-company-mode)
;;   :config
;;   (setq company-minimum-prefix-length 1) ; 只需敲 1 个字母就开始进行自动补全
;;   (setq company-tooltip-align-annotations t)
;;   (setq company-idle-delay 0.0)
;;   (setq company-selection-wrap-around t)
;;   )

;; (use-package company-box
;;   :ensure t
;;   :if window-system
;;   :hook (company-mode . company-box-mode))

(use-package corfu
  :ensure t
  :init
  (global-corfu-mode)
  :custom
  (corfu-auto t)
  (corfu-cycle t)
  (corfu-preselect 'prompt)
  :bind
  ;; (:map corfu-map
  ;;       ("C-n" . corfu-next)      ;; 使用 C-n 选择下一个
  ;;       ("C-p" . corfu-previous)  ;; 使用 C-p 选择上一个
  ;;       ("TAB" . corfu-insert)    ;; 建议：Tab 插入选中的
  ;;       ("RET" . corfu-insert))            ;; 回车仅换行，不确认补全（防止误触）
  )

(use-package cape
  :ensure t
  :commands (cape-dabbrev cape-file cape-elisp-block)
  :bind ("C-c p" . cape-prefix-map)
  :init
  ;; Add to the global default value of `completion-at-point-functions' which is
  ;; used by `completion-at-point'.
  (add-hook 'completion-at-point-functions #'cape-dabbrev)
  (add-hook 'completion-at-point-functions #'cape-file)
  (add-hook 'completion-at-point-functions #'cape-elisp-block))

(use-package kind-icon
  :ensure t
  :after corfu
  :custom
  (kind-icon-default-face 'corfu-default)
  :config
  (add-to-list 'corfu-margin-formatters #'kind-icon-margin-formatter))


(use-package corfu-popupinfo
  :after corfu
  :custom
  (corfu-popupinfo-delay 0.3)
  :config
  (corfu-popupinfo-mode))



(use-package eglot
  :ensure t
  :hook
  ;; 在 Python 和 Go 模式加载时自动启动 Eglot
  ((
     python-mode
     python-ts-mode
     go-mode
     go-ts-mode
      ) . eglot-ensure)
  
  :config
  ;; 优化：禁止 Eglot 修改 flymake 后端，防止冲突（可选）
  ;; (setq eglot-stay-out-of '(flymake))
  
  ;; 性能优化：对于某些重型 LSP，增加响应超时时间
  (setq eglot-connect-timeout 60)
  
  ;; 关键：Eglot 默认会向后端发送 shutdown 请求，有时会导致 server 崩溃或重启慢
  (setq eglot-autoshutdown t))


(use-package yasnippet
  :ensure t
  :init
  (yas-global-mode 1))



(use-package lsp-treemacs
  :ensure t  
  :init (lsp-treemacs-sync-mode 1)
  :commands lsp-treemacs-errors-list)

(use-package envrc
  :ensure t
  :hook (after-init . envrc-global-mode))

(use-package go-mode
  :ensure t
  :hook ((go-mode . eglot-ensure)) ;; 确保进入 go-mode 启动 LSP
  :config
  ;; 保存时自动格式化 (gofmt/goimports)
  (add-hook 'before-save-hook #'gofmt-before-save))

(provide 'init-edit)

