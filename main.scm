;;;; -*- Scheme48 -*-


;;--------------------------------------------------------------------
;; Variables.

(define app-name #f)

;;--------------------------------------------------------------------
;; Procedures.

(define (make-app-dir-name name)
  (string-append
   (home-dir)
   "/bin/."
   name))

(define (make-app-image-name app-dir name)
  (string-append app-dir "/" name))

(define (create-app-dir dir)
  (create-directory dir))

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
      ;; SEEK doesn't handle buffered ports.
      (lambda () (set-port-buffering output-port bufpol/none))
      (lambda () (begin
		   (seek output-port 0)
		   (display string output-port)))
      (lambda () (close output-port)))))

(define (deploy-app name)
  (begin
    (let* ((app-dir-name (make-app-dir-name name))
	   (app-image-name (make-app-image-name app-dir-name name)))
      (begin
	(create-app-dir app-dir-name)
	(copy-vm-to-app-dir app-dir-name)
	(dump-app-image app-image-name)))))
