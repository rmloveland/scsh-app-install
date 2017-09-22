;;;; main.scm

;;; internal procedures

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

(define (locate-scshvm)
  (let ((o1 "/opt/lib/scsh/scshvm")
        (o2 "/usr/local/lib/scsh/scshvm")
        (scshvm-location #f))
    (cond ((file-exists? o1 (set! scshvm-location o1)))
          ((file-exists? o2 (set! scshvm-location o2)))
          (else (error "Couldn't locate scshvm!")))
    scshvm-location))

(define (copy-vm-to-app-dir dir)
  (let ((scshvm-path (locate-scshvm)))
    (run (cp ,scshvm-path ,dir))))

(define (dump-app-image proc image)
  (begin
    (dump-scsh-program proc image)
    (prepend-shebang-lines-to-image image)))

(define (prepend-shebang-lines-to-image image)
  (let* ((scshvm-path (locate-scshvm))
         (newline-s (list->string '(#\newline)))
         (shebang (string-append "#!" scshvm-path " \\" newline-s
                                 "-h 8000000 -o  " scshvm-path " -i "
                                 newline-s newline-s))
         (tmpdir (getenv "TMPDIR"))
         (shebang-file (string-append tmpdir "scsh-shebang.txt"))
         (image-orig (string-append image ".orig")))
    (run (echo ,shebang) (> ,shebang-file))	; save shebang in temp file
    (run (mv ,image ,image-orig))
    (run (cat ,shebang-file ,image-orig) (> ,image))))

(define (make-user-binary-name app-name)
  (string-append (make-user-bin-dir-name) "/" app-name))

(define (link-app-image-as-user-binary app-image-name user-binary-name)
  (if (file-exists? user-binary-name)
      (run (rm ,user-binary-name)))
  (run (ln -s ,app-image-name ,user-binary-name)))

(define (set-file-executable! f)
  (set-file-mode 
   f
   (bitwise-ior 755 (file-mode f))))

(define set-user-binary-executable! set-file-executable!)

;;; external procedure

(define (install-app! proc name)
  (let* ((app-dir-name (make-app-dir-name name))
	 (app-image-name (make-app-image-name app-dir-name name))
	 (user-binary-name (make-user-binary-name name)))
    (begin
      (create-app-dir app-dir-name)
      (dump-app-image proc app-image-name)
      (link-app-image-as-user-binary app-image-name user-binary-name)
      (set-user-binary-executable! user-binary-name))))

;;; eof
