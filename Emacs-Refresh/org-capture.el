;; * Org Capture Configuration  -*- lexical-binding: t; -*-

;; References
;; https://orgmode.org/org.html#Capture-and-Attachments
;; https://orgmode.org/org.html#Capture-templates

;; Questions
;; - What would be the consequences of having org-directory
;;   go directly to ~/Notes/GTD


;; ** Where I keep things

;; Is there an advantage to keeping org-directory
;; higher up in the tree than my gtd-dir?

;; org-capture package global variable
(setq org-directory (expand-file-name "~/Notes"))
;; my Getting Things Done directory
(defconst my-gtd-dir (expand-file-name "GTD" org-directory))

;; ** Org Capture Mode

;; We're capturing everything under our GTD directory
;; Maybe someday we'll separate these things out?

(global-set-key "\C-cc" 'org-capture)

(ert-deftest directory-exists?-gtd-dir ()
  (should (directory-exists? my-gtd-dir)) )

;; Abridged from https://orgmode.org/org.html#Template-expansion-1
;; %t          Time stamp, date only.  The time stamp is the current
;;             time, except when called from agendas with
;;             ‘M-x org-agenda-capture’ or with
;;             ‘org-capture-use-agenda-date’ set.
;; %T          Time stamp as above, with date and time.
;; %u, %U      Like the above, but inactive time stamps.
;; %i          Initial content, copied from the active region.  If
;;             there is text before %i on the same line, such as
;;             indentation, and %i is not inside a %(sexp), that prefix
;;             will be added before every line in the inserted text.
;; %a          Annotation, normally the link created with ‘org-store-link’.
;; %A          Like %a, but prompt for the description part.
 ;; %l          Like %a, but only insert the literal link.
;; %L          Like %l, but without brackets (the link content itself).
;; %c          Current kill ring head.
;; %x          Content of the X clipboard.
;; %?          After completing the template, position cursor here.

;; ** Org-Capture Defaults

;; org-capture-templates defaults
;; The target-alias is often just the target-type
;; for the most common situation using that target-type.
(defconst capture!defaults-table
      '(
	;; fieldnames
	(target-alias template-type target-type entry-template)
	;; data
	(file+headline entry file+headline "** %?\nEntered %U\n  %i\n  %a\n  %x")
	(file+datetree entry file+datetree  "** %?\nEntered %U\n  %i\n  %a")
	)
      "table of defaults for org-capture-templates, used by function capture!" )

(defconst capture!defaults-fieldnames (car capture!defaults-table)
  "field names of records in capture!defaults list" )
(defconst capture!defaults (cdr capture!defaults-table)
  "defaults for fields of org-capture-templates, used by function capture!" )

;; column selector functions for the capture!defaults-table
(defconst capture!defaults->template-type (symbol-function 'cl-second)
  "select template-type from capture!defaults record" )
(defconst capture!defaults->target-type (symbol-function 'cl-third)
  "select target-type from capture!defaults record" )
(defconst capture!defaults->entry-template (symbol-function 'cl-fourth)
  "select entry-template from capture!defaults record" )

(ert-deftest capture!template-fieldnames ()
  (should (eq (cl-second capture!defaults-fieldnames)
	      (funcall capture!defaults->template-type capture!defaults-fieldnames) )) )

;; sets of valid values for testing templates for validity
(defconst capture!defaults-template-types
  (cl-remove-duplicates
   (mapcar capture!defaults->template-type capture!defaults) ) )
(defconst capture!defaults-target-types
  (cl-remove-duplicates
   (mapcar capture!defaults->target-type capture!defaults) ) )
(defconst capture!defaults-entry-templates
  (cl-remove-duplicates
   (mapcar capture!defaults->entry-template capture!defaults) ) )

(ert-deftest capture!template-column-sets ()
  (should (member 'file+datetree capture!defaults-target-types))
)

(defun capture!default (item item-selector target-alias)
  "capture! helper function: return item or a default if item is nil"
  (or item
      (let ( (defaults (assoc target-alias capture!defaults) ) )
	(and defaults (funcall item-selector defaults)) )
      (error "%s %s No default for %s given target-alias %s"
	     "org-capture.el" 'capture!default (funcall item-selector capture!defaults-fieldnames) target-alias ) ) )

(ert-deftest capture!default-test ()
  (should (eq 'happy (capture!default 'happy capture!defaults->template-type 'file+datetree)))
  (should (eq 'entry (capture!default nil capture!defaults->template-type 'file+datetree)))
)

;; ** (capture!template) creates well-formed org-capture-templates entries

(defun capture!template (key description template-type target-type path node-string entry-template options &optional context)
  "capture! helper: construct org-capture-templates template from the parts"
  (let ( (context (append context 'capture!template))
	 (first-four-fields
	  (list (my 'stringp key context 'key)
		(my 'stringp description context 'description)
		(my 'symbolp template-type context 'template-type)
		(let ( (target-type (my 'symbolp target-type context 'target-type))
		       (path (my 'stringp path context 'path)) )
		  (cond ( (eq target-type 'file+headline)
			  (list  target-type path (my 'stringp node-string context 'node-string)) )
			( (eq target-type 'file+datetree)
			  (list target-type path) )
			( t (error "In %S unknown template-type %S" context template-type) ) ) ) ) )
	 (remaining-fields (cons (my 'stringp entry-template context 'entry-template)
				 (my 'listp options context 'options) )) )
       (nconc first-four-fields remaining-fields) ) )


(ert-deftest capture!template-file+headline-0 ()
  (let ( (entry-template "** TODO %i%? \n %U")
	 (fullpath (expand-file-name "todos-org" my-gtd-dir)) )
	    (should 
	     (equal 
	      (capture!template
	       "t" "Todos" 'entry 'file+headline fullpath "Todos" entry-template nil )
	      `("t" "Todos" entry (file+headline ,fullpath "Todos") ,entry-template) ) ) ) )

;; ** org-capture package global variable initialization

(setq org-capture-templates '())

;; ** (capture!) creates and saves entries to org-capture-templates

(cl-defun capture! (key description target-alias path
			&optional node-string
			&rest options
			&key type pattern (dir my-gtd-dir) )
  "using mutation, install a new org-capture-templates template with nice defaults"
  (let ( (context '("org-capture.el" capture!)) ; for debugging or errors
	 (template-type (capture!default type capture!defaults->template-type target-alias))
	 (target-type (capture!default nil capture!defaults->target-type target-alias))
	 (entry-template (capture!default pattern capture!defaults->entry-template target-alias)) )
    (let ( (template (capture!template key description template-type target-type
				       (expand-file-name path dir) node-string entry-template options ))
	   (old-template (assoc key org-capture-templates)) )
      (cond ( (not template) nil )
	    ;; put the new template at the end of the list
	    ( (null org-capture-templates) (push template org-capture-templates) )
	    ( (not old-template) (nconc org-capture-templates (list template)) template )
	    ;; leave any old template alone if it isn't going to change
	    ( (equal template old-template) old-template )
	    ;; otherwise replace it with the new value using mutation
	    ;; so the new value retains its place in the list
	    ( t (setcar old-template (car template))
	      (setcdr old-template (cdr template))
	      old-template ) ) ) ) )

;; *** testing capture!default, capture!template

;; Only test the features we're planning on using!
;; Don't be concerned about embedded entry-template codes!
(defun valid-org-capture-template? (template)
  "Is this template valid syntactically?  Unknown target types are given a pass!!"
  (and (listp template)
       (= (length template) 5)
       (stringp (cl-first template))
       (stringp (cl-second template))
       (symbolp (cl-third template))
       (let ( (target (cl-fourth template)) )
	 (and (listp target) (>= (length target) 2)
	      (let ( (type (cl-first target)) )
		(and 
		 (symbolp type)
		 (stringp (cl-second target))
		 (cond ( (eq type 'file+headline)
			 (and (eq (length target) 3) (stringp (cl-third target))) )
		       ( (eq type 'file+datetree) (eq (length target) 2) )
		       ;; give unknown target types a pass!
		       ( t t ) ) ) ) ) )
       (stringp (cl-fifth template)) ) )

;; Only test the features we're planning on using!
;; Don't be concerned about embedded entry-template codes!
(defun good-org-capture-template? (template)
  "Is this template known to be valid? Checks against default sets.  Checks file exists."
  (and (valid-org-capture-template? template)
       (member (cl-third template) capture!defaults-template-types)
       (member (cl-first (cl-fourth template)) capture!defaults-target-types)
       (member (cl-fifth template) capture!defaults-entry-templates)
       (file-exists? (cl-second (cl-fourth template))) ) )

;; assumes
;; [1] template-type is 'entry
;; [2] target-type = target-alias
;; [3] first default for target-alias is target-type
;; [4] "todos.org" exists under my-gtd-dir
(ert-deftest capture!template-file+headline ()
  (let* ( (key "t")
	  (description  "Todo [inbox]")
	  (path "todos.org")
	  (node-string "Todos")
	  (options nil)
	  (fullpath (expand-file-name path my-gtd-dir))
	  (target-alias 'file+headline)
	  (expected-template-type 'entry)
	  (expected-target-type 'file+headline)
	  ;; fill these in with setq
	  (template-type nil)
	  (target-type nil)
	  (entry-template nil)
	  (template nil) )
    (setq template-type (capture!default nil capture!defaults->template-type target-alias))
    (should (eq template-type expected-template-type))
    (setq target-type (capture!default nil capture!defaults->target-type target-alias))
    (should (eq target-type expected-target-type))
    (setq entry-template (capture!default nil capture!defaults->entry-template target-alias))
    (should (stringp entry-template))
    (setq template (capture!template key description template-type target-type
				     fullpath node-string entry-template options ))
    (should (valid-org-capture-template? template))
    (should (good-org-capture-template? template)) ) )

;; *** TODO (ert-deftest capture!template-file+headline ()
;; goes here!!

;; *** testing capture!

(ert-deftest capture!-file+headline-1 ()
  (let ( (save-org-capture-templates org-capture-templates) )
    (unwind-protect
	(progn
	  (setq org-capture-templates '())
	  (let ( (length0 (length org-capture-templates)) )
	    ;; we're testing the effect of
	    (capture! "t" "Todos" 'file+headline "todos.org" "Todos")
	    (let ( (length1 (length org-capture-templates)) )
	      ;; there should now be one more entry in org-capture-templates
	      (should (= (+ 1 length0) length1))
	      (let ( (template (assoc "t" org-capture-templates)) ; the one we just added
		     (expected-template `( "t" "Todos" entry
					   (file+headline ,(expand-file-name "todos.org" my-gtd-dir)
							  "Todos" )
					   ,(capture!default nil capture!defaults->entry-template 'file+headline) )) )
		(should (eq (nth length0 org-capture-templates) template))
		(should (valid-org-capture-template? template))
		(should (good-org-capture-template? template))
		(should (equal template expected-template)) ) ) ) )
	      (setq org-org-capture-templates save-org-capture-templates) ) ) )
	
(ert-deftest capture!-file+datetree-1 ()
  (let ( (save-org-capture-templates org-capture-templates ) )
    (unwind-protect
	(progn
	  (setq org-capture-templates '())
	  (let ( (length0 (length org-capture-templates)) )
	    (capture! "J" "Journal" 'file+datetree "journal.org")
	    (let ( (length1 (length org-capture-templates)) )
	      (should (= (+ 1 length0) length1))
	      (let ( (template (assoc "J" org-capture-templates))
		     (expected-template `( "J" "Journal" entry
					   (file+datetree ,(expand-file-name "journal.org" my-gtd-dir))
					   ,(capture!default nil capture!defaults->entry-template 'file+datetree) ) ) )
		(should (eq (nth length0 org-capture-templates) template))
		(should (valid-org-capture-template? template))
		(should (good-org-capture-template? template))
		(should (equal template expected-template)) ) ) ) )
      (setq org-org-capture-templates save-org-capture-templates) ) ) )

;; let's add a second one
(ert-deftest capture!-file+headline-2 ()
  (let ( (save-org-capture-templates org-capture-templates) )
    (unwind-protect
	(progn
	  (setq org-capture-templates '())
	  (let ( (length0 (length org-capture-templates)) )
	    ;; put in a template we don't care about
	    (capture! "J" "Journal" 'file+datetree "journal.org")
	    ;; put in the template we care about
	    (capture! "t" "Todos" 'file+headline "todos.org" "Todos")
	    (let ( (length1 (length org-capture-templates)) )
	      ;; there should now be two more entries in org-capture-templates
	      (should (= (+ 2 length0) length1))
	      (let ( (expected-template `( "t" "Todos" entry
					   (file+headline ,(expand-file-name "todos.org" my-gtd-dir)
							  "Todos" )
					   ,(capture!default nil capture!defaults->entry-template 'file+headline) )) )
		(should (equal (nth (- length1 1) org-capture-templates) expected-template)) ) ) ) )
      (setq org-org-capture-templates save-org-capture-templates) ) ) )

;; let's change one!
(ert-deftest capture!-file+headline-2 ()
  (let ( (save-org-capture-templates org-capture-templates) )
    (unwind-protect
	(progn
	  (setq org-capture-templates '())
	  (let ( (length0 (length org-capture-templates)) )
	    ;; put in two templates
	    (capture! "J" "Journal" 'file+datetree "journal.org")
	    (capture! "t" "Test" 'file+headline "todos.org" "Test")
	    (let* ( (length1 (length org-capture-templates))
		    (template2 (nth (- length1 1) org-capture-templates)) )
	      (should (= (+ 2 length0) length1))
	      ;; put in the template we care about
	      (capture! "t" "Todos" 'file+headline "todos.org" "Todos")
	      ;; the length should not have changed!
	      (should (= length1 (length org-capture-templates)))
	      (let ( (expected-template `( "t" "Todos" entry
					   (file+headline ,(expand-file-name "todos.org" my-gtd-dir)
							  "Todos" )
					   ,(capture!default nil capture!defaults->entry-template 'file+headline) )) )
		;; the content should have updated
		(should (equal template2 expected-template))
		;; the object should be the same
		(should (eq template2 (nth (- length1 1) org-capture-templates)))  ) ) ) )
      (setq org-org-capture-templates save-org-capture-templates) ) ) )

;; ** may org-capture files -- soon to be obsolete

(defconst gtd-new-org (expand-file-name "new.org" my-gtd-dir))
(defconst gtd-todos-org (expand-file-name "todos.org" my-gtd-dir))
(defconst gtd-pity-org (expand-file-name "pity.org" my-gtd-dir))
(defconst gtd-someday-org (expand-file-name "someday.org" my-gtd-dir))
(defconst gtd-bookmarks-org (expand-file-name "bookmarks.org" my-gtd-dir))
(defconst gtd-contacts-org (expand-file-name "contacts.org" my-gtd-dir))
(defconst gtd-journal-org (expand-file-name "journal.org" my-gtd-dir))
(defconst gtd-ideas-org (expand-file-name "ideas.org" my-gtd-dir))
(defconst gtd-loel-org (expand-file-name "loel.org" my-gtd-dir))
(defconst gtd-landmark-org (expand-file-name "landmark.org" my-gtd-dir))
(defconst gtd-hacking-org (expand-file-name "hacking.org" my-gtd-dir))
(defconst gtd-projects-org (expand-file-name "projects.org" my-gtd-dir))
(defconst gtd-wicci-org (expand-file-name "wicci.org" my-gtd-dir))
(defconst gtd-misc-org (expand-file-name "misc.org" my-gtd-dir))

;; ** my old org-capture-templates definition

;; Questions:
;; - What's the difference between the <description> and the <node-string>?
;;   - <comment> is maybe a poor name?
;; - What can go in the 

(setq org-capture-templates
	`(
	  ;; <keys> <description> <type> <target> <entry-template-string> . (<option>...)
	  ;; target says where to put the entry
          ;; target = (<target-type> <usually-a-filename> ...)
	  ;; examples of two kinds of targets
	  ;; target = (file+headline path-to-orgmode-file orgmode-node)
	  ;; target = (file+datetree orgmode-file)
 ;; ( "t" "Todo [inbox]" entry (file+headline ,gtd-inbox-org "Tasks") "** TODO %i%?" )
	  ( "t" "Todos" entry (file+headline ,gtd-todos-org "Todos")
	    "** TODO %i%? \n %U" )
	  ( "b" "Bookmarks" entry (file+headline ,gtd-bookmarks-org "Bookmarks")
	    "** %?\nEntered %U\n  %i\n  %a" )
	  ( "c" "Contacts" entry (file+headline ,gtd-contacts-org "Contacts")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "i" "Ideas" entry (file+headline ,gtd-ideas-org "Ideas")
	    "** %?\nEntered %U\n  %i\n  %a" )
	  ( "n" "New" entry (file+headline ,gtd-new-org "New")
	    "** %?\nEntered %U\n  %i\n  %a" )
	  ( "l" "LOEL" entry (file+headline ,gtd-loel-org "LOEL")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "L" "Landmark" entry (file+headline ,gtd-landmark-org "Landmark")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "h" "Hacking" entry (file+headline ,gtd-hacking-org "Hacking")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "p" "Projects" entry (file+headline ,gtd-projects-org "Projects")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "w" "Wicci" entry (file+headline ,gtd-wicci-org "Wicci")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "m" "Misc" entry (file+headline ,gtd-misc-org "Miscellany")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "J" "Journal" entry (file+datetree ,gtd-journal-org)
	    "** %?\nEntered %U\n  %i\n  %a" )
	  ( "P" "Pity" entry (file+headline ,gtd-pity-org "Pities")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ( "S" "Someday" entry (file+headline ,gtd-someday-org "Someday")
	    "** %?\nEntered %U\n  %i\n  %a\n  %x" )
	  ) )

;; Let's create a procedure (capture) which
;; - adds items to org-capture-templates
;; - optionally to org-agenda-files
;; - optionally to org-refile-targets
;; - with defaults for common values
;; - checking that files exist
;; - is idempotent, allowing reloads!
;; elisp doesn't have keyworld arguments, so
;; use &rest to introduce an alist!
;; or
;; (require 'cl-lib)
;; (cl-defun print-name (&key first (last "?"))

;; There's some confusion about org-refile-targets
;; Initially none of these worked.  Then the first
;; one started working.  I may have needed to put
;; in a couple of levels of headings.
;; I would definitely like more flexibility and/or
;; to be able to file things to a deeper level!

(setq org-refile-targets `( ; (,gtd-gtd-org :maxlevel . 3)
                           (,gtd-someday-org :level . 1)
                           (,gtd-todos-org :maxlevel . 2)
                           (,gtd-bookmarks-org :level . 1)
                           (,gtd-journal-org :maxlevel . 4)
                           (,gtd-ideas-org :maxlevel . 4)
                           (,gtd-misc-org :maxlevel . 2)
))
