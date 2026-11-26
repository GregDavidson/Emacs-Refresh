;;; -*- lexical-binding: t -*-

;; ** Default emacs-new feature alist

;; Most features are enabled by NOT including them at all here!
(define emacs-new-feature-alist
	"Emacs-New Feature-Symbol->Value Association List, values are USUALLY booleans"
	'() )

;; Explicitly include or exclude boolean features like this:
;; (push emacs-new-feature-alist '(include-by-default . t))
;; (push emacs-new-feature-alist '(exclude-by-default . nil))
;; Examples of non-boolean features
;; (push emacs-new-feature-alist '(foreground-color . "#000000"))
;; (push emacs-new-feature-alist '(background-color . "#ffffff"))

(defun use-feature? (feature-name)
  "return the value associated with feature-name using eq in emacs-new-feature-alist or nil if not found"
  (let ( (feature (assq feature-name emacs-new-feature-alist)) )
    (and feature (cdr feature)) ) )

(defmacro use-feature: (feature-name)
  `(use-feature ',feature-name) )

;; Be sure to explore what features are in use
;; $ rg -t lisp "[(]use-feature?  *'"
;; $ rg -g '*.el' "[(]use-feature?  *'"

;; ** Startup speed, annoyance suppression

(unless (use-feature? 'no-speedups)
  (setq bedrock--initial-gc-threshold gc-cons-threshold)
  (setq gc-cons-threshold 10000000)
  (setq byte-compile-warnings '(not obsolete))
  (setq warning-suppress-log-types '((comp) (bytecomp)))
  (setq native-comp-async-report-warnings-errors 'silent)
)

(unless (use-feature? 'cruft)
  ;; Silence stupid startup message
  (advice-add #'display-startup-echo-area-message :override #'ignore)
)

;; ** Packages

(unless (use-feature? 'no-ensure-package)
  ;; Tell use-package to install if missing by default
  ;; Use `:ensure nil' in packages you *don't* want to install
  (setq use-package-always-ensure t)
  )

;; ** Smooth Resizing

(unless (use-feature? 'no-smoth-resize)

;; Setting *-resize-pixelwise to `t' lets frames/windows resize
;; smoothly at sub-character increments
(setq frame-resize-pixelwise t)
; (setq window-resize-pixelwise t)

)

(unless (use-feature? 'tool-bar)

(when (fboundp 'tool-bar-mode) ; When in a GUI, disable tool bar;
  (tool-bar-mode -1))          ; all these tools are in the menu-bar anyway

)

;; These settings apply to *all* frames.

;; You can turn off scroll bars by uncommenting these lines:
;; (push default-frame-alist '(vertical-scroll-bars . nil))
;; (push default-frame-alist '(horizontal-scroll-bars . nil))

;; (push default-frame-alist '(ns-appearance . dark))
;; (push default-frame-alist '(ns-transparent-titlebar . t))

;; Use these to turn off the OS window decoration
;; (push default-frame-alist '(undecorated-round . t))
;; (push default-frame-alist '(internal-border-width . 3))

;; These settings apply to the first frame created. The
;; (back|fore)ground-color settings need to live here so that a
;; theme's background color applies correctly to subsequent frames.
;; (setq initial-frame-alist '((fullscreen . maximized)
;;                             ;; Setting the face in here prevents flashes of
;;                             ;; color as the theme gets activated
;;                             (background-color . "#000000")
;;                             (foreground-color . "#ffffff")))

;; (push initial-frame-alist '(fullscreen . maximized))

;; Setting the face in here prevents flashes of
;; color as the theme gets activated
(when (use-feature? 'foreground-color)
  (push initial-frame-alist
	(cons (foreground-color (use-feature? 'foreground-color)))) )
(when (use-feature? 'background-color)
  (push initial-frame-alist
	(cons (background-color (use-feature? 'background-color)))) )

(unless (use-feature? 'no-custom.el)
  (setq custom-file (concat user-emacs-directory "custom.el"))
)
