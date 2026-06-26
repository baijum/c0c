(define-library (c0c codegen-util)
  (import (scheme base) (scheme write))
  (export binop->c-str assign-op->c-str zero-init join-chunks)
  (begin

    (define (binop->c-str op)
      (case op
        ((plus) "+") ((minus) "-") ((star) "*")
        ((amp) "&") ((pipe) "|") ((caret) "^")
        ((amp-amp) "&&") ((pipe-pipe) "||")
        ((lt) "<") ((le) "<=") ((gt) ">") ((ge) ">=")
        ((eq-eq) "==") ((ne) "!=")
        (else (error "c0c codegen: unknown binop" op))))

    (define (assign-op->c-str op)
      (case op
        ((asgn) "=") ((asgn-plus) "+=") ((asgn-minus) "-=") ((asgn-star) "*=")
        ((asgn-slash) "/=") ((asgn-percent) "%=") ((asgn-amp) "&=") ((asgn-pipe) "|=")
        ((asgn-caret) "^=") ((asgn-lshift) "<<=") ((asgn-rshift) ">>=")
        (else (error "c0c codegen: unknown assign op" op))))

    (define (zero-init ty)
      (case (car ty)
        ((ty-int) "0")
        ((ty-bool) "false")
        ((ty-char) "'\\0'")
        ((ty-string) "\"\"")
        ((ty-ptr) "NULL")
        ((ty-arr) "NULL")
        ((ty-void) "")
        (else "0")))

    (define (join-chunks lst)
      (let ((port (open-output-string)))
        (for-each (lambda (s) (write-string s port)) lst)
        (get-output-string port)))))
