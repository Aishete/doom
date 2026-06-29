;;; $DOOMDIR/config.el -*- lexical-binding: t; -*-

;; Place your private configuration here! Remember, you do not need to run 'doom
;; sync' after modifying this file!


;; Some functionality uses this to identify you, e.g. GPG configuration, email
;; clients, file templates and snippets. It is optional.
(setq user-full-name "John Doe"
      user-mail-address "john@doe.com")

;; Doom exposes five (optional) variables for controlling fonts in Doom:
;;
;; - `doom-font' -- the primary font to use
;; - `doom-variable-pitch-font' -- a non-monospace font (where applicable)
;; - `doom-big-font' -- used for `doom-big-font-mode'; use this for
;;   presentations or streaming.
;; - `doom-unicode-font' -- for unicode glyphs
;; - `doom-serif-font' -- for the `fixed-pitch-serif' face
;;
;; See 'C-h v doom-font' for documentation and more examples of what they
;; accept. For example:

(setq doom-font (font-spec :family "Terminess Nerd Font" :size 25 :weight 'medium)
      doom-variable-pitch-font (font-spec :family "Terminess Nerd Font" :size 25))
;;
;; If you or Emacs can't find your font, use 'M-x describe-font' to look them
;; up, `M-x eval-region' to execute elisp code, and 'M-x doom/reload-font' to
;; refresh your font settings. If Emacs still can't find your font, it likely
;; wasn't installed correctly. Font issues are rarely Doom issues!

;; There are two ways to load a theme. Both assume the theme is installed and
;; available. You can either set `doom-theme' or manually load a theme with the
;; `load-theme' function. This is the default:
(setq doom-theme 'catppuccin)
(setq catppuccin-flavor 'macchiato) ; or 'frappe 'latte, 'macchiato, or 'mocha
(load-theme 'catppuccin t)
;; set transparency... I don't think this works so TODO
(set-frame-parameter (selected-frame) 'alpha '(85 85))
(add-to-list 'default-frame-alist '(alpha 85 85))

;; This determines the style of line numbers in effect. If set to `nil', line
;; numbers are disabled. For relative line numbers, set this to `relative'.
(setq display-line-numbers-type t)

;; If you use `org' and don't want your org files in the default location below,
;; change `org-directory'. It must be set before org loads!
(setq org-directory "~/org/")
;; you can customize your rss feed at ~/org/elfeed.org. This works because I'm
;; using +org with my rss plugin. Check out
;; https://github.com/remyhonig/elfeed-org to see an example.


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
;; Also run immediately after Doom modules finish loading
(after! doom-init
  (+clipboard-setup-wl))

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

;; use fish shell by default
(setq explicit-shell-file-name "/run/current-system/sw/bin/fish")

;; remove LSP delays
(after! flycheck (setq flycheck-idle-change-delay 0.1))
(after! lsp-mode
  (setq lsp-idle-delay 0.1)
  :custom
  (setq lsp-completion-enable-additional-text-edit t)
  (setq lsp-modeline-code-actions-enable t)
  )

;; Better debugging
(use-package! dape)
