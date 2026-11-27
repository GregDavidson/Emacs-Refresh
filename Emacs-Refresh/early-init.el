;;; -*- lexical-binding: t -*-

;; * File: Emacs-Refresh/early-init.el

;; Loaded by early-init.el in user-emacs-directory
;; - unless 'error or 'no-early-init

;; Keep this file short and sweet!  Anything that doesn't
;; need to be done in the early-init phase should instead
;; be put in one of the init.el files!

;; ** Startup speed, annoyance suppression

(refresh-unless: no-early-speedups
 (setq bedrock--initial-gc-threshold gc-cons-threshold)
 (setq gc-cons-threshold 10000000)
 (setq byte-compile-warnings '(not obsolete))
 (setq warning-suppress-log-types '((comp) (bytecomp)))
 (setq native-comp-async-report-warnings-errors 'silent)
 )

(refresh-unless: display-startup-echo-area-message
  ;; Silence stupid startup message
  (advice-add #'display-startup-echo-area-message :override #'ignore)
)

;; ** Packages

(refresh-unless: no-use-package-always-ensure
  ;; Tell use-package to install if missing by default
  ;; Use `:ensure nil' in packages you *don't* want to install
  (setq use-package-always-ensure t)
  )

;; ** Smooth Resizing

(refresh-unless: no-smooth-resize
 ;; Setting *-resize-pixelwise to `t' lets frames/windows resize
 ;; smoothly at sub-character increments
 (setq frame-resize-pixelwise t)
 ;; (setq window-resize-pixelwise t)
)

(refresh-unless: tool-bar
 (when (fboundp 'tool-bar-mode) ; When in a GUI, disable tool bar;
   (tool-bar-mode -1))          ; all these tools are in the menu-bar anyway
)

;; ** Disabled Emacs-Bedrock Settings

;; Settings from Emacs-Bedrock early-init.el which I don't think
;; should be Emacs-Refresh defaults.  Users can put these settings
;; in My-Emacs/early-init.el if desired.

;; These settings apply to *all* frames.

;; You can turn off scroll bars by uncommenting these lines:
;; (push '(vertical-scroll-bars . nil) default-frame-alist)
;; (push '(horizontal-scroll-bars . nil) default-frame-alist)

;; (push '(ns-appearance . dark) default-frame-alist)
;; (push '(ns-transparent-titlebar . t) default-frame-alist)

;; Use these to turn off the OS window decoration
;; (push '(undecorated-round . t) default-frame-alist)
;; (push '(internal-border-width . 3) default-frame-alist)

;; These settings apply to the first frame created. The
;; (back|fore)ground-color settings need to live here so that a
;; theme's background color applies correctly to subsequent frames.
;; (setq initial-frame-alist '((fullscreen . maximized)
;;                             ;; Setting the face in here prevents flashes of
;;                             ;; color as the theme gets activated
;;                             (background-color . "#000000")
;;                             (foreground-color . "#ffffff")))

;; (push '(fullscreen . maximized) initial-frame-alist)

;; ** Early setting of foreground and background colors

;; Hooks so users can put something like
;; (push '(foreground-color . "#000000") refresh-alist)
;; (push '(background-color . "#ffffff") refresh-alist)
;; in their My-Emacs/early-init.el file.

;; Setting the face in here prevents flashes of
;; color as the theme gets activated
(let ( (foreground-color (refresh-feature? 'foreground-color)) )
  (when foreground-color
    (push (cons ('foreground-color foreground-color)) initial-frame-alist) ) )
	
(let ( (background-color (refresh-feature? 'background-color)) )
  (when background-color
    (push (cons ('background-color background-color)) initial-frame-alist) ) )
	
(refresh-unless: no-custom.el
  (setq custom-file (concat user-emacs-directory "custom.el"))
)

;; ** Emacs Customization Settings File

;; Settings created by Emacs' Customization System should have their own file!
;; Without this, they'll be dumped into the bottom of init.el!

(defvar refresh-customization-file (refresh-truename ("custom.el" user-emacs-directory))
  "alternative place for emacs customizations instead of init.el" )

(refresh-unless: no-custom-file
 ;; consider using defvar here instead of setq
 (setq custom-file refresh-customization-file)
)
