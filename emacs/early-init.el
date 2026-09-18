;;; early-init.el --- Input method setup before creating frames -*- lexical-binding: t; -*-

;; GTK/X11 Emacs otherwise uses XIM, which fails to handle Fcitx reliably
;; under XWayland.  Use the GTK input module, as PGTK Emacs already does.
(setq x-gtk-use-native-input t)

;; Desktop launchers and emacs --daemon do not necessarily inherit the
;; interactive shell's input method environment.  Keep explicit choices.
(when (and (eq system-type 'gnu/linux) (executable-find "fcitx5"))
  (dolist (setting '(("GTK_IM_MODULE" . "fcitx")
                     ("XMODIFIERS" . "@im=fcitx")))
    (when (member (getenv (car setting)) '(nil ""))
      (setenv (car setting) (cdr setting)))))

;;; early-init.el ends here
