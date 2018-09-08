;;; -*- lexical-binding: t; -*-

(use-package helm :demand
  :config (require 'helm-config)

  ;; raise windows using wmctrl
  (when (executable-find "wmctrl")
    (setq helm-raise-command "wmctrl -xa %s"))

  ;; don't show nixos .wrapper-binaries
  (progn
    (setq helm-external-commands-list
          (cl-loop
           for dir in (split-string (getenv "PATH") path-separator)
           when (and (file-exists-p dir) (file-accessible-directory-p dir))
           for lsdir = (cl-loop for i in (directory-files dir t)
                                for bn = (file-name-nondirectory i)
                                when (and (not (member bn completions))
                                          (not (file-directory-p i))
                                          (file-executable-p i))
                                collect bn)
           append lsdir into completions
           finally return
           completions))
    (setq helm-external-commands-list
          (cl-remove-if (lambda (v) (string-match "^\\." v)) helm-external-commands-list)))





  (when (executable-find "curl")
    (setq helm-net-prefer-curl t))

  (setq helm-split-window-inside-p            t
        helm-buffers-fuzzy-matching           t
        helm-move-to-line-cycle-in-source     t
        helm-ff-search-library-in-sexp        t
        helm-ff-file-name-history-use-recentf t
        helm-ff-auto-update-initial-value t)

  (global-set-key (kbd "C-c h") 'helm-command-prefix)
  (global-unset-key (kbd "C-x c"))

  (define-key helm-command-map (kbd "o")     'helm-occur)
  (define-key helm-command-map (kbd "g")     'helm-do-grep)
  (define-key helm-command-map (kbd "C-c w") 'helm-wikipedia-suggest)
  (define-key helm-command-map (kbd "SPC")   'helm-all-mark-rings)

  (global-set-key (kbd "M-x") 'helm-M-x)
  (global-set-key (kbd "C-x C-m") 'helm-M-x)
  (global-set-key (kbd "M-y") 'helm-show-kill-ring)
  (global-set-key (kbd "C-x b") 'helm-mini)
  (global-set-key (kbd "C-x C-b") 'helm-buffers-list)
  (global-set-key (kbd "C-x C-f") 'helm-find-files)
  (global-set-key (kbd "C-h f") 'helm-apropos)
  (global-set-key (kbd "C-h r") 'helm-info-emacs)
  (global-set-key (kbd "C-h C-l") 'helm-locate-library)
  (global-set-key (kbd "C-x C-r") 'helm-recentf)
  (global-set-key (kbd "C-c C-r") 'helm-resume)
  (define-key minibuffer-local-map (kbd "C-c C-l") 'helm-minibuffer-history)
  (define-key isearch-mode-map (kbd "C-o") 'helm-occur-from-isearch)

  ;; shell history.
  (define-key shell-mode-map (kbd "C-c C-r") 'helm-comint-input-ring)

  (helm-mode 1))

(use-package helm-projectile :demand :after helm
  :config (helm-projectile-on))

(use-package helm-descbinds :demand :after helm
  :config (helm-descbinds-mode))

;; add swoop
(use-package helm-swoop :demand :after helm)

;; add emms
(use-package helm-emms)

;; nixos specific, remove hidden files from helm launcher

;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
