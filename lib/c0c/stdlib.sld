(define-library (c0c stdlib)
  (import (scheme base) (srfi 69))
  (export register-library-funcs! library-func? mangle)
  (begin

    (define library-signatures
      (list
        (cons "print" (cons '(ty-void) (list '(ty-string))))
        (cons "println" (cons '(ty-void) (list '(ty-string))))
        (cons "printint" (cons '(ty-void) (list '(ty-int))))
        (cons "readline" (cons '(ty-string) '()))
        (cons "string_length" (cons '(ty-int) (list '(ty-string))))
        (cons "string_charat" (cons '(ty-char)
                                    (list '(ty-string) '(ty-int))))
        (cons "string_sub" (cons '(ty-string)
                                 (list '(ty-string) '(ty-int) '(ty-int))))
        (cons "string_join" (cons '(ty-string)
                                  (list '(ty-string) '(ty-string))))
        (cons "string_compare" (cons '(ty-int)
                                     (list '(ty-string) '(ty-string))))
        (cons "string_equal" (cons '(ty-bool)
                                   (list '(ty-string) '(ty-string))))
        (cons "string_fromint" (cons '(ty-string) (list '(ty-int))))
        (cons "string_frombool" (cons '(ty-string) (list '(ty-bool))))
        (cons "string_fromchar" (cons '(ty-string) (list '(ty-char))))
        (cons "char_ord" (cons '(ty-int) (list '(ty-char))))
        (cons "char_chr" (cons '(ty-char) (list '(ty-int))))))

    (define library-names
      (let ((ht (make-hash-table string=? string-hash)))
        (for-each (lambda (entry) (hash-table-set! ht (car entry) #t))
          library-signatures)
        (for-each (lambda (name) (hash-table-set! ht name #t))
          '("string_from_chararray" "string_to_chararray"
            "c0_array_length"))
        ht))

    (define (register-library-funcs! funcs)
      (for-each
        (lambda (entry)
          (hash-table-set! funcs (car entry) (cdr entry)))
        library-signatures))

    (define (library-func? name)
      (hash-table-exists? library-names name))

    (define (mangle name)
      (if (library-func? name)
          name
          (string-append "_c0_" name)))))
