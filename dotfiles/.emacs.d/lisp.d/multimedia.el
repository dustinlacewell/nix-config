;;; -*- lexical-binding: t; -*-

(use-package emms
  :after hydra
  :init
  (defhydra emms-hydra ()
    "Emacs Multimedia System"
    ("h" helm-emms "helm-emms")
    ("f" emms-play-file "play file")
    ("d" emms-play-directory "play directory")
    ("p" emms "playlist")
    ("q" nil "Quit" :color blue))
  :config
  (setq emms-source-file-default-directory "~/Downloads")
  (emms-all)
  (emms-default-players))

(use-package pdf-tools
  :magic ("%PDF" . pdf-view-mode)
  :config
  (pdf-tools-install t))

;; Local Variables:
;; coding: utf-8
;; no-byte-compile: t
;; End:
