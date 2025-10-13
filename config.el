;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-
;;;

;; Theme
(setq doom-theme 'catppuccin)
(setq catppuccin-flavor 'mocha) ; or 'frappe 'latte, 'macchiato, or 'mocha
(load-theme 'catppuccin t)

;; Font
(setq-default line-spacing nil)
(setq doom-font (font-spec :family "Monospace" :size 16)
      doom-font-increment 1)

;; Keybindings
(map! :leader
      :desc "Comment line" "-" #'comment-line)
(map! :leader
      (:prefix ("t" . "toggle")
       :desc "Toggle eshell split"            "e" #'+eshell/toggle
       :desc "Toggle line highlight in frame" "h" #'hl-line-mode
       :desc "Toggle line highlight globally" "H" #'global-hl-line-mode
       :desc "Toggle line numbers"            "l" #'doom/toggle-line-numbers
       :desc "Toggle markdown-view-mode"      "m" #'my/toggle-markdown-view-mode
       :desc "Toggle truncate lines"          "t" #'toggle-truncate-lines
       :desc "Toggle treemacs"                "T" #'+treemacs/toggle
       :desc "Toggle treemacs"                "n" #'+treemacs/toggle
       :desc "Toggle vterm split"             "v" #'+vterm/toggle))

;; Options
(setq org-directory "~/Documents/Org/")
(setq org-modern-table-vertical 1)
(setq org-modern-table t)
(setq display-line-numbers-type t) ;; `t' = normal, `relative', `nil' = off.
(setq confirm-kill-emacs nil) ;; Don't confirm on exit

;; use zsh shell by default
;; (setq explicit-shell-file-name "/run/current-system/sw/bin/zsh")

(defun my/toggle-markdown-view-mode ()
  "Toggle between `markdown-mode' and `markdown-view-mode'."
  (interactive)
  (if (eq major-mode 'markdown-view-mode)
      (markdown-mode)
    (markdown-view-mode)))

;; Transparency (Currently broken)
(set-frame-parameter (selected-frame) 'alpha '(80 80))
(add-to-list 'default-frame-alist '(alpha 80 80))

;; Whenever you reconfigure a package, make sure to wrap your config in an
;; `after!' block, otherwise Doom's defaults may override your settings. E.g.
;;
;;   (after! PACKAGE
;;     (setq x y))
;;
;; The exceptions to this rule:
;;
;;   - Setting file/directory variables (like `org-directory')
;;   - Setting variables which explicitly tell you to set them before their
;;     package is loaded (see 'C-h v VARIABLE' to look up their documentation).
;;   - Setting doom variables (which start with 'doom-' or '+').
;;
;; Here are some additional functions/macros that will help you configure Doom.
;;
;; - `load!' for loading external *.el files relative to this one
;; - `use-package!' for configuring packages
;; - `after!' for running code after a package has loaded
;; - `add-load-path!' for adding directories to the `load-path', relative to
;;   this file. Emacs searches the `load-path' when you load packages with
;;   `require' or `use-package'.
;; - `map!' for binding new keys
;;
;; To get information about any of these functions/macros, move the cursor over
;; the highlighted symbol at press 'K' (non-evil users must press 'C-c c k').
;; This will open documentation for it, including demos of how they are used.
;; Alternatively, use `C-h o' to look up a symbol (functions, variables, faces,
;; etc).
;;
;; You can also try 'gd' (or 'C-c c d') to jump to their definition and see how
;; they are implemented.

;; (after! doom-modeline
;;   (doom-modeline-def-modeline 'main
;;     '(bar matches buffer-info vcs word-count)
;;     '(buffer-position misc-info major-mode)))

;; source: https://nayak.io/posts/golang-development-doom-emacs/
;; golang formatting set up
;; use gofumpt
(after! lsp-mode
  (setq  lsp-go-use-gofumpt t)
  )
;; automatically organize imports
(add-hook 'go-mode-hook #'lsp-deferred)
;; Make sure you don't have other goimports hooks enabled.
(defun lsp-go-install-save-hooks ()
  (add-hook 'before-save-hook #'lsp-organize-imports t t))
(add-hook 'go-mode-hook #'lsp-go-install-save-hooks)

;; enable all analyzers; not done by default
(after! lsp-mode
  (setq  lsp-go-analyses '((fieldalignment . t)
                           (nilness . t)
                           (shadow . t)
                           (unusedparams . t)
                           (unusedwrite . t)
                           (useany . t)
                           (unusedvariable . t)))
  )

;; use system clipboard
(require 'pbcopy)
(turn-on-pbcopy)

;; use wayland copy
(when (and string= (getenv "XDG_SESSION_TYPE") "wayland")
  (executable-find "wl-copy")
  (executable-find "wl-paste"))
(defun my/wl-copy (text)
  (if (display-graphic-p)
      (gui-select-text text)
    (let ((wl-copy-process
           (make-process :name "wl-copy"
                         :buffer nil
                         :command '("wl-copy")
                         :connection-type 'pipe)))
      (process-send-string wl-copy-process text)
      (process-send-eof wl-copy-process))))
(defun my/wl-paste ()
  (if (display-graphic-p)
      (gui-selection-value)
    (shell-command-to-string "wl-paste --no-newline")))
(setq interprogram-cut-function #'my/wl-copy)
(setq interprogram-paste-function #'my/wl-paste))
