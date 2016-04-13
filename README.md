# Swank-Helper
swank-helper is just helper library for ClozureCL(a.k.a ccl).
It's only support to ccl

## Why?
currently, slime/swank support communicate style `:spawn` on ccl.
When you eval expression in lisp buffer, everytime spawn new worker thread.
so If you eval to `(random 10)` in lisp buffer, everytime return same value.

## Implementation
I just implementation simple serve-event(many part of code, comming from clasp.lisp in SWANK).
but you should use it for swank-helper only. I don't test to serve-event for general usage.

## Usage
just clone this library to local project of your Quicklisp.
then run `(ql:register-local-projects)` in ccl's repl.
next, copy to follow code into your `.swank.lisp` file.
```cl	
    (in-package :swank)
    #+ccl
	(progn 
      (require :swank-helper)
      (setf *communication-style* nil))
```

