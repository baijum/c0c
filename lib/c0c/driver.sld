(define-library (c0c driver)
  (import (scheme base) (scheme file) (scheme write)
          (c0c lexer) (c0c parser) (c0c checker) (c0c codegen))
  (export compile-c0-to-c set-lib-hook!)
  (begin

    (define (compile-c0-to-c source-path . opts)
      (let* ((no-check (and (pair? opts) (car opts)))
             (port (open-input-file source-path))
             (lex (make-lexer port source-path))
             (ast (parse-program lex)))
        (close-input-port port)
        (check-program ast)
        (emit-c-program ast no-check)))))
