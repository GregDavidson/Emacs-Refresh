;; * My Emacs Utility Functions -*- lexical-binding: t; -*-

;; ** Requires
;; cl-lib and ert are now part of standard gnu emacs,
;; you just need to import their symbols.
(require 'cl-lib)
(require 'ert)

;; ** Places as First-Class Values

(defmacro place (aplace)
  "create a function value from a generalized place expression which can be used to set or get the value at that place"
  (gv-letplace (getter setter) aplace
    `(lambda (&rest new-val)
       (if new-val
	   ,(funcall setter '(car new-val))
	 ,getter ) ) ) )

(ert-deftest place-var ()
  (let ( (ref1 (let ( (var 0) ) (place var)))
	 (ref2 (let ( (var 0) ) (place var))) )
    (should (= (funcall ref1) 0))
    (should (= (funcall ref2) 0))
    (funcall ref1 1)
    (funcall ref2 -1)
    (should (= (funcall ref1) 1))
    (should (= (funcall ref2) -1))
    ) )

(ert-deftest place-list ()
  (let ( (list1 '(1 2 3)) )
    (let ( (ref1 (place (cl-first list1)))
	   (ref2 (place (nth 1 list1)))
	   (ref3 (place (caddr list1))) )
    (should (= (funcall ref1) 1))
    (should (= (funcall ref2) 2))
    (should (= (funcall ref3) 3))
    (funcall ref1 0)
    (funcall ref2 1)
    (funcall ref3 2)
    (should (equal list1 '(0 1 2)))
    ) ) )

;; ** (condense-context)

;; We expect context to express some dynamic context for a debugging
;; or error report, from the &rest argument of some function.  We
;; expect the first element to be a context list for that function
;; with possible additional elements providing names and/or values
;; giving more context.  If this is the case, pull the additional
;; elements into the context list, otherwise just return the content
;; as a list.  ==> Transform context into a simple(r) list!
(cl-defun condense-context (context)
  "return any context as a singleton by wrapping it and/or folding its cdr elements into its car"
  (cond
   ;; return an empty list as such
   ( (null context) context )
   ;; if context is not a list, return it wrapped!
   ( (atom context) (list context) )
   ;; we now know that it's a non-empty list
   ;; if the first element is not a sublist, we're done
   ( (atom (car context)) context )
   ;; the first element is a sublist
   ( t ; fold it's cdr into its car
     (append (car context) (cdr context))
     ) ) )
     
(ert-deftest condense-test ()
  (should (null (condense-context nil)))
  (should (equal (condense-context "org-capture.el") '("org-capture.el")))
  (should (equal (condense-context '("org-capture.el")) '("org-capture.el")))
  (should (equal (condense-context '("org-capture.el" some-function))
		 '("org-capture.el" some-function) ))
  (should (equal (condense-context '("org-capture.el" some-function 'var-name))
		 '("org-capture.el" some-function 'var-name) ))
  )

;; ** after-keys

;; Helpful in designing a cl-defun parameter list
;; using &rest and one or more &key arguments.
;; Note that keywords and following values which
;; are not specified by an &key argument will be
;; silently discarded.

;; especially intended for returning the rest of a list
;; after an initial part consisting of alternating keywords and values
;; or the list following the keyworld :done.

(defun after-keys (lst)
  "return list tail following keyword/value elements or :done"
  (while (and (consp lst)
	      (keywordp (car lst))
	      (not (eq (car lst) :done)) )
    (pop lst) (pop lst) )
  (if (eq (car lst) :done)
      (cdr lst)
    lst ))

(ert-deftest after-keys-test ()
  (should (equal (after-keys nil) nil))
  (should (equal (after-keys '(1 2 3)) '(1 2 3)))
  (should (equal (after-keys '(:done)) nil))
  (should (equal (after-keys '(:done :done)) '(:done)))
  (should (equal (after-keys '(:done 1 2 3)) '(1 2 3)))
  (should (equal (after-keys '(:done :a 1 2 3)) '(:a 1 2 3)))
  (should (equal (after-keys '(1 :done 2 3)) '(1 :done 2 3)))
  (should (equal (after-keys '(:a 1 2 3)) '(2 3)))
  (should (equal (after-keys '(:a 1 :b 2 :c 3)) nil))
)
    

;; ** (my) needs (contense-context) and (after-alist)

(cl-defun foo (type-predicate value
			      &rest context
			      &key (error 'error) &allow-other-keys
			      )
  (format "type %s value %s error %s rest %S tail %S"
	  type-predicate value error context (after-keys context) ) )

(foo 'stringp 'hello :error 'format "org-capture.el")
  
;; version with workaround for Common Lisp &rest &key infelicity
(cl-defun my (type-predicate value &rest context
			     &key (error 'error) &allow-other-keys
)
  "like cl-the but with a better error message"
  (if (funcall type-predicate value)
      value
    (let ( (message "expected type %S but got %S")
	   (context (condense-context (after-keys context))) ; updated context
	   (args (list type-predicate value)) )
      ;; update message and args if context non-null
      (let ( (message (if (null context) message (concat "In %S " message)))
	     (args (if (null context) args (cons context args))) )
	;; throw an error with the current message and any contextI included
	(apply error message args) ) ) ) )

(ert-deftest my-test ()
  (should (eq 'hello (my 'symbolp 'hello)))
  
  (should-error (my 'stringp 'hello))
  (should-error (my 'stringp 'hello "org-capture.el"))
  (should-error (my 'stringp 'hello "org-capture.el" 'funny))
  (should-error (my 'stringp 'hello '("org-capture.el" funny)))
  (should-error (my 'stringp 'hello '("org-capture.el" funny) 'foo))
  (should-error (my 'stringp 'hello '("org-capture.el" funny) 'foo 5 'bar))

  ;; but what message to all of those errors display?
  (should (equal (my 'stringp 'hello :error 'format)
		 "expected type stringp but got hello" ))
  (should (equal (my 'stringp 'hello :error 'format "org-capture.el")
		 "In (\"org-capture.el\") expected type stringp but got hello" ))
  (should (equal (my 'stringp 'hello :error 'format "org-capture.el" 'funny)
		 "In (\"org-capture.el\" funny) expected type stringp but got hello" ))
  (should (equal (my 'stringp 'hello :error 'format '("org-capture.el" funny) 'foo)
		 "In (\"org-capture.el\" funny foo) expected type stringp but got hello" ))
  (should (equal (my 'stringp 'hello :error 'format '("org-capture.el" funny) 'foo 5 'bar)
		 "In (\"org-capture.el\" funny foo 5 bar) expected type stringp but got hello" ))
  )

;; ** (enlist) - enlist if all non-nil, error otherwise!

;; I'm very proud of this function!
(cl-defun non-null-enlist (names &rest items)
  "return list of items, all must be non-nil; otherwise return nil and complain about nil items by name"
  (if (cl-notany #'null items)
      items
    (error "%s error: expected all %S non-nil in %S"
	   'non-null-enlist names items) ) )

;; ** File and Directory Testing Functions

(defun file-true-attributes (f)
  "returns attributes of file's truename or nil"
  (file-attributes (file-truename f)) )

(defun file-exists? (f)
  "file-true-attributes not nil"
  (file-true-attributes f) )

(defun directory-exists? (d)
  "ninth element of file-true-attributes begins with d - not portable!!"
  (let ( (attrs (file-true-attributes d)) )
    (and attrs (= (aref (cl-ninth attrs) 0) ?d)) ) )

(ert-deftest directory-exists?-org-directory ()
  (should (directory-exists? org-directory)) )
