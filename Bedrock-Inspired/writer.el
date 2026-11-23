;;; -*- lexical-binding: t -*-
;;;
;;; Emacs Bedrock
;;;
;;; Extra config: Writer

;;; Usage: Append or require this file from init.el for writing aids.
;;;
;;; Jinx is a spell-checking package that is performant and flexible.
;;; You can use Jinx inside of programming modes and it will only
;;; check spelling inside of strings and comments. (Configurable, of
;;; course.) It also supports having multiple languages (e.g. English
;;; and German) in the same file.
;;;
;;; Olivetti narrows the window margins so that your text is centered.
;;; This makes writing in a wide, dedicated window more pleasant.

;;; Contents:
;;;
;;;  - Spell checking
;;;  - Dictionary
;;;  - Distraction mitigation

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   General prose-friendly behavior
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(when (>= emacs-major-version 30)       ; compat test
  (add-hook 'text-mode-hook 'visual-wrap-prefix-mode))

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Spell checking
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;


;; Leaving this commented out for now until it works reliably!
;; Jinx: Enchanted spell-checking
;; (use-package jinx
;;   :hook (((text-mode prog-mode) . jinx-mode))
;;   :bind (("C-;" . jinx-correct))
;;   :custom
;;   (jinx-camel-modes '(prog-mode))
;;   (jinx-delay 0.01))

;; New Error after apparent fix
;; - Tuesday, 10 November 2026
;; As directed in:
;;   https://github.com/minad/jinx#installation
;; I ran:
;;   apt install libenchant-2-dev pkgconf
;; And now I have this New error:
;; Jinx: jinx-mod.so compiled successfully
;; File mode specification error: (module-open-failed "/home/greg/.emacs.d/elpa/jinx-20260926.912/jinx-mod.so" "libenchant-2.so.2: cannot open shared object file: No such file or directory")


;; Old info on first attempt to load package:
;; This fails! jgd, 2026-10-31
;; Jinx: Compiling jinx-mod.so
;; Jinx: pkgconf or pkg-config not found
;; gcc -I. -O2 -Wall -Wextra -fPIC -shared -o jinx-mod.so jinx-mod.c -I/usr/include/enchant-2 -I/usr/local/include/enchant-2 -L/usr/local/lib -lenchant-2
;; jinx-mod.c:21:10: fatal error: enchant.h: No such file or directory
;;    21 | #include <enchant.h>
;;       |          ^~~~~~~~~~~
;; compilation terminated.
;; Jinx: Compilation of jinx-mod.so failed


;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Dictionary
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

(setopt dictionary-use-single-buffer t)
(setopt dictionary-server "dict.org")

;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;
;;;
;;;   Distraction mitigation
;;;
;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;;

;; Olivetti: Set the window margins so your text is centered
;; (use-package olivetti
;;   ;; Uncomment below to make olivetti-mode turn on automatically in certain modes
;;   ; :hook ((markdown-mode . olivetti-mode))
;;   )
;; ■  Error (use-package): Cannot load olivetti
