
(defpackage #:swank-helper
  (:use #:cl #:ccl)
  (:export #:*descriptor-handlers*
	   #:add-fd-handler
	   #:remove-fd-handler))

(in-package :swank-helper)

(defstruct (handler
	    (:constructor make-handler (descriptor direction function))
	    (:copier nil))
  (direction nil :type (member :input :output))
  (descriptor 0)
  (function nil :type function))

(defvar *descriptor-handlers* nil)

(defun add-fd-handler (fd direction function)
  (unless (member direction '(:input :output))
    (error 'simple-type-error
	   :format-control "Invalid direction ~S, must be either :INPUT or :OUTPUT."
	   :format-arguments (list direction)
	   :datum direction
	   :expected-type '(member :input :output)))
  (let ((handler (make-handler fd
			       direction
			       function)))
    (push handler *descriptor-handlers*)
    handler))

(defun remove-fd-handler (handler)
  (setf *descriptor-handlers* (delete handler *descriptor-handlers*)))

(defun serve-event (seconds)
  (rlet ((rfd :fd_set)
	 (wfd :fd_set)
	 (timeval :timeval))
    (ccl::fd-zero rfd)
    (ccl::fd-zero wfd)
    (let ((maxfd 0))
      (dolist (handler *descriptor-handlers*)
	(let ((fd (handler-descriptor handler)))
	  (ecase (handler-direction handler)
	    (:input (ccl::fd-set fd rfd))
	    (:output (ccl::fd-set fd wfd)))
	  (when (> fd maxfd)
	    (setf maxfd fd))))
      (multiple-value-bind (sec usec)
	  (floor seconds)
	(setf (pref timeval :timeval.tv_sec) sec
	      (pref timeval :timeval.tv_usec) (floor (* usec 1e6)))
	(let ((retval (#_select (1+ maxfd) rfd wfd (%null-ptr) timeval)))
	  (cond ((zerop retval) nil)
		((minusp retval) nil) 
		((plusp retval)
		 (dolist (handler *descriptor-handlers*)
		   (let ((fd (handler-descriptor handler)))
		     (when (ecase (handler-direction handler)
			     (:input (ccl::fd-is-set fd rfd))
			     (:output (ccl::fd-is-set fd wfd)))
		       (funcall (handler-function handler) (handler-descriptor handler)))))
		 t)))))))


