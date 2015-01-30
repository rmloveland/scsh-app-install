;;;; main.scm --- Deploy Scsh `apps' to users.        -*- Scheme48 -*-

;;; OVERVIEW
;;
;; This package allows you to deploy Scsh command-line apps to
;; users. At a high level, it does the following:
;;
;; 1. Dump a static UNIX executable into ~/bin/.<appname>
;;
;; 2. Link the executable into the user's ~/bin/<appname>
;;
;; We bother with this indirection so that you can use the .<appname>
;; directory to store any other files that might be needed by your
;; application.

;;--------------------------------------------------------------------
;; Procedures.

(define (make-user-bin-dir-name)
  (string-append
   (home-dir)
   "/bin"))

(define (make-app-dir-name name)
  (string-append
   (make-user-bin-dir-name)
   "/."
   name))

(define (make-app-image-name app-dir name)
  (string-append app-dir "/" name))

(define (create-app-dir dir)
  (if (not (file-exists? dir))
      (create-directory dir)))

(define (copy-vm-to-app-dir dir)
  (run (cp /usr/local/lib/scsh/scshvm ,dir)))

(define (dump-app-image image)
  (begin (dump-scsh-program main image)
	 (prepend-shebang-lines-to-image image)))

(define (prepend-shebang-lines-to-image image)
  (let* ((output-port (open-file image open/write))
	 (string #<<EOF
#!scshvm \
-o scshvm -i

EOF
))
    (dynamic-wind
      ;; We need to turn off buffering because Scsh's implementation
      ;; of SEEK can't handle buffered I/O ports.
      (lambda () (set-port-buffering output-port bufpol/none))
      (lambda () (begin
		   (seek output-port 0)
		   (display string output-port)))
      (lambda () (close output-port)))))

(define (make-user-binary-name app-name)
  (string-append (make-user-bin-dir-name) "/" app-name))

(define (link-app-image-as-user-binary app-image-name user-binary-name)
  (run (ln -s ,app-image-name ,user-binary-name)))

(define (set-file-executable! f)
  (set-file-mode 
   f
   (bitwise-ior 755 (file-mode f))))

(define set-user-binary-executable! set-file-executable!)

(define (deploy-app name)
  (let* ((app-dir-name (make-app-dir-name name))
	 (app-image-name (make-app-image-name app-dir-name name))
	 (user-binary-name (make-user-binary-name name)))
    (begin
      (create-app-dir app-dir-name)
      ;; Don't bother with the below step: Apple doesn't allow
      ;; creating statically linked binaries. What a pain.
      ;; (copy-vm-to-app-dir app-dir-name)
      (dump-app-image app-image-name)
      (link-app-image-as-user-binary app-image-name user-binary-name)
      (set-user-binary-executable! user-binary-name))))
