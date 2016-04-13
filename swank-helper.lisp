(in-package swank/ccl)

(defun poll-streams (streams timeout)
  (let* ((swank-helper:*descriptor-handlers* (copy-list swank-helper:*descriptor-handlers*))
	 (active-fds '())
	 (fd-stream-alist
	   (loop for s in streams
		 for fd = (ccl:stream-device s (ccl:stream-direction s))
		 collect (cons fd s)
		 do (swank-helper:add-fd-handler fd :input
						#'(lambda (fd)
						    (push fd active-fds))))))
    (swank-helper::serve-event timeout)
    (loop for fd in active-fds collect (cdr (assoc fd fd-stream-alist)))))

(defimplementation wait-for-input (streams &optional timeout)
  (assert (member timeout '(nil t)))
  (loop
    (cond ((check-slime-interrupts) (return :interrupt))
	  (timeout (return (poll-streams streams 0)))
	  (t
	   (when-let (ready (poll-streams streams 0.2))
	     (return ready))))))

