(define-library (c0c stdlib)
  (import (scheme base) (srfi 69))
  (export register-library-funcs! register-libraries-for!
          known-library? library-func? mangle)
  (begin

    (define conio-signatures
      (list
        (cons "print" (cons '(ty-void) (list '(ty-string))))
        (cons "println" (cons '(ty-void) (list '(ty-string))))
        (cons "printint" (cons '(ty-void) (list '(ty-int))))
        (cons "printbool" (cons '(ty-void) (list '(ty-bool))))
        (cons "printchar" (cons '(ty-void) (list '(ty-char))))
        (cons "readline" (cons '(ty-string) '()))
        (cons "eof" (cons '(ty-bool) '()))))

    (define string-signatures
      (list
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

    (define parse-signatures
      (list
        (cons "parse_bool"
              (cons '(ty-ptr (ty-struct "parsed_bool"))
                    (list '(ty-string))))
        (cons "parse_int"
              (cons '(ty-ptr (ty-struct "parsed_int"))
                    (list '(ty-string) '(ty-int))))))

    (define all-libraries
      (list (cons "conio" conio-signatures)
            (cons "string" string-signatures)
            (cons "parse" parse-signatures)
            (cons "file" '())
            (cons "args" '())))

    (define all-signatures
      (append conio-signatures string-signatures))

    (define library-names
      (let ((ht (make-hash-table string=? string-hash)))
        (for-each (lambda (entry) (hash-table-set! ht (car entry) #t))
          all-signatures)
        (for-each (lambda (entry) (hash-table-set! ht (car entry) #t))
          parse-signatures)
        (for-each (lambda (name) (hash-table-set! ht name #t))
          '("string_from_chararray" "string_to_chararray"
            "c0_array_length" "file_read" "file_close"
            "file_eof" "file_readline"
            "args_flag" "args_int" "args_string" "args_parse"))
        ht))


    (define (register-library-funcs! funcs)
      (for-each
        (lambda (entry)
          (hash-table-set! funcs (car entry) (cdr entry)))
        all-signatures))

    (define (register-libraries-for! funcs used-libs)
      (for-each
        (lambda (lib-name)
          (let ((entry (assoc lib-name all-libraries)))
            (when entry
              (for-each
                (lambda (sig)
                  (hash-table-set! funcs (car sig) (cdr sig)))
                (cdr entry)))))
        used-libs))

    (define (known-library? name)
      (assoc name all-libraries))

    (define (library-func? name)
      (hash-table-exists? library-names name))

    (define (mangle name)
      (if (library-func? name)
          name
          (string-append "_c0_" name)))))
