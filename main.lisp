(uiop:define-package #:update-sources
  (:nicknames #:update-sources/main)
  (:use #:cl)
  (:local-nicknames (#:sh #:inferior-shell))
  (:export #:main))

(in-package #:update-sources/main)

(defun main-aux (&rest args)
  (sh:run `(echo foo bar ,@args)))

(defun main ()
  (apply #'main-aux (uiop:command-line-arguments)))
