;; ** Emacs-Bedrock/extras/org.el ideas, customized


;; Bring in everything needed for my perfect orgmode configuration!
;; settings
;; my-org-lib.el
;; my-org-capture.el
;; my-org-agenda.el
;; Org-mode configuration
;; WARNING: need to customize things inside the elisp file before use! See
;; the file extras/org-intro.txt for help.
;; ** Orgmode Customization

;; (global-set-key "\C-cl" 'org-store-link) ; Changed below

(global-set-key "\C-ca" 'org-agenda)
(global-set-key "\C-cb" 'org-iswitchb)

(defun org-mode-jgd ()
	(setq variable-pitch-mode 1)
	(set-face-attribute 'org-table nil :inherit 'fixed-pitch) )

(add-hook 'org-mode-hook 'turn-on-font-lock)
(add-hook 'org-mode-hook 'org-mode-jgd)

(load-library (my))

;; ** Load org-mode Package

(use-package org
  :hook ((org-mode . visual-line-mode)  ; wrap lines at word breaks
         (org-mode . flyspell-mode))    ; spell checking!

  :bind (:map global-map
              ("C-c l s" . org-store-link)          ; Mnemonic: link → store
              ("C-c l i" . org-insert-link-global)) ; Mnemonic: link → insert
  :config
  (require 'oc-csl)                     ; citation support
  (add-to-list 'org-export-backends 'md)

  ;; Make org-open-at-point follow file links in the same window
  (setf (cdr (assoc 'file org-link-frame-setup)) 'find-file)

  ;; Make exporting quotes better ??jgd??
  (setq org-export-with-smart-quotes t)
  )
