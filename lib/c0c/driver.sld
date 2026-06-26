(define-library (c0c driver)
  (import (scheme base) (scheme file) (scheme write)
          (c0c lexer) (c0c parser) (c0c checker) (c0c codegen))
  (export compile-c0-to-c set-lib-hook! set-check-file!)
  (begin

    (define (compile-c0-to-c source-path . opts)
      (let* ((no-check (and (pair? opts) (car opts)))
             (src-text (and (pair? opts) (pair? (cdr opts)) (cadr opts)))
             (port (if src-text
                       (open-input-string src-text)
                       (open-input-file source-path)))
             (lex (make-lexer port source-path))
             (ast (parse-program lex)))
        (when (not src-text) (close-input-port port))
        (set-check-file! source-path)
        (check-program ast)
        (emit-c-program ast no-check)))))
