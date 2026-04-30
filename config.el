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
       :desc "Toggle vterm split"             "v" #'+vterm/toggle));

;; Options
(setq org-directory "~/document/obsidian/00 - DailyNotes")
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
;; NixOS + Wayland Clipboard Fix
;; Doom's +clipboard module sets interprogram-paste-function to
;; pbcopy-selection-value which doesn't work on Wayland.
;; Since NixOS rebuild freezes config in nix store, we run this
;; on every frame so it always takes effect.
(defun +clipboard-setup-wl ()
  "Set up Wayland clipboard integration."
  (let ((wl-copy-path "/run/current-system/sw/bin/wl-copy")
        (wl-paste-path "/run/current-system/sw/bin/wl-paste"))
    (if (file-exists-p wl-copy-path)
        (progn
          (setq interprogram-cut-function
                (lambda (text)
                  (let ((process-connection-type nil))
                    (let ((proc (make-process :name "wl-copy"
                                              :buffer nil
                                              :command (list wl-copy-path)
                                              :connection-type 'pipe)))
                      (process-send-string proc text)
                      (process-send-eof proc)))))
          (setq interprogram-paste-function
                (lambda ()
                  ;; Use call-process to avoid shell dependency
                  (with-temp-buffer
                    (call-process wl-paste-path nil t nil "--no-newline")
                    (buffer-string))))
          (setq select-enable-clipboard t)
          (setq select-enable-primary t)
          (message "Clipboard: Wayland integration loaded using %s" wl-copy-path))
      (message "Clipboard Warning: %s not found!" wl-copy-path))))

;; Run on every new frame to override nix store's frozen +clipboard module
(add-hook 'after-make-frame-functions
          (lambda (&optional frame)
            (+clipboard-setup-wl)))
;; Also run immediately for initial daemon
(+clipboard-setup-wl)

;; Test clipboard
(defun test-clipboard ()
  "Test clipboard integration."
  (interactive)
  (let ((test-text "Doom clipboard test"))
    (kill-new test-text)
    (message "Copied: %s" test-text)
    (sit-for 1)
    (let ((pasted (current-kill 0)))
      (message "Pasted: %s" pasted))))

;; Quick test on startup
(add-hook 'emacs-startup-hook
          (lambda ()
            (message "Clipboard configured: %s"
                     (if interprogram-cut-function "YES" "NO"))))

;; Ensure clipboard works with evil
(after! evil
  (setq evil-want-fine-undo t)
  (setq evil-want-Y-yank-to-eol t)
  (setq evil-want-integration t)
  ;; Use system clipboard for yank/paste
  (setq evil-kill-on-visual-paste nil)
  (setq evil-want-C-u-scroll t)
  (setq evil-want-C-i-jump t))

;; Also set kill-ring to use clipboard
(setq save-interprogram-paste-before-kill t)
(setq x-select-enable-clipboard t)
(setq x-select-enable-primary t)

;; Make yank use clipboard
(setq select-enable-clipboard t)
(setq select-enable-primary t)

;; Ensure kill-ring and clipboard synchronized
(setq kill-ring-max 200)
(setq kill-do-not-save-duplicates t)

;; Keybinding to copy to clipboard (C-c C-c)
(global-set-key (kbd "C-c C-c") 'clipboard-kill-ring-save)
(global-set-key (kbd "C-c C-v") 'clipboard-yank)

;; For evil mode, ensure "p" and "P" use clipboard
(after! evil
  (defadvice evil-paste-after (before use-clipboard activate)
    "Use clipboard for paste."
    (when (and interprogram-paste-function (not current-prefix-arg))
      (let ((text (funcall interprogram-paste-function)))
        (when text
          (kill-new text)))))
  (defadvice evil-paste-before (before use-clipboard activate)
    "Use clipboard for paste."
    (when (and interprogram-paste-function (not current-prefix-arg))
      (let ((text (funcall interprogram-paste-function)))
        (when text
          (kill-new text))))))
