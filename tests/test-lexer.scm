(import (scheme base) (scheme write) (c0c lexer))

(define pass 0)
(define fail 0)

(define (check name expected actual)
  (if (equal? expected actual)
      (begin (set! pass (+ pass 1))
             (display "  PASS: ") (display name) (newline))
      (begin (set! fail (+ fail 1))
             (display "  FAIL: ") (display name) (newline)
             (display "    expected: ") (write expected) (newline)
             (display "    actual:   ") (write actual) (newline))))

(define (lex-all str)
  (let ((lex (make-lexer (open-input-string str) "<test>")))
    (let loop ((toks '()))
      (let ((t (lexer-next lex)))
        (if (eq? (tok-tag t) 'eof)
            (reverse toks)
            (loop (cons t toks)))))))

(define (lex-tags str)
  (map tok-tag (lex-all str)))

(define (lex-vals str)
  (map tok-val (lex-all str)))

(display "=== Lexer Tests ===\n")

(display "Keywords:\n")
(check "int keyword" '(kw-int) (lex-tags "int"))
(check "return keyword" '(kw-return) (lex-tags "return"))
(check "true keyword" '(kw-true) (lex-tags "true"))
(check "NULL keyword" '(kw-NULL) (lex-tags "NULL"))
(check "alloc_array keyword" '(kw-alloc-array) (lex-tags "alloc_array"))

(display "Identifiers:\n")
(check "simple ident" '(ident) (lex-tags "foo"))
(check "ident value" '("foo") (lex-vals "foo"))
(check "ident with underscore" '("my_var") (lex-vals "my_var"))

(display "Integer literals:\n")
(check "decimal" '(42) (lex-vals "42"))
(check "hex" '(255) (lex-vals "0xFF"))
(check "zero" '(0) (lex-vals "0"))

(display "String literals:\n")
(check "simple string" '("hello") (lex-vals "\"hello\""))
(check "escape in string" '("a\nb") (lex-vals "\"a\\nb\""))

(display "Char literals:\n")
(check "simple char" '(#\a) (lex-vals "'a'"))
(check "newline escape" '(#\newline) (lex-vals "'\\n'"))

(display "Operators:\n")
(check "plus" '(op-plus) (lex-tags "+"))
(check "plus-eq" '(op-plus-eq) (lex-tags "+="))
(check "plus-plus" '(op-plus-plus) (lex-tags "++"))
(check "arrow" '(op-arrow) (lex-tags "->"))
(check "lshift" '(op-lshift) (lex-tags "<<"))
(check "lshift-eq" '(op-lshift-eq) (lex-tags "<<="))
(check "eq-eq" '(op-eq-eq) (lex-tags "=="))
(check "amp-amp" '(op-amp-amp) (lex-tags "&&"))

(display "Punctuation:\n")
(check "parens" '(lparen rparen) (lex-tags "()"))
(check "braces" '(lbrace rbrace) (lex-tags "{}"))
(check "semi" '(semi) (lex-tags ";"))

(display "Comments:\n")
(check "line comment" '(int-lit) (lex-tags "42 // ignore this"))
(check "block comment" '(int-lit int-lit) (lex-tags "1 /* skip */ 2"))

(display "Full statement:\n")
(check "return 0;"
  '(kw-return int-lit semi)
  (lex-tags "return 0;"))

(check "function call"
  '(ident lparen int-lit rparen semi)
  (lex-tags "printint(42);"))

(newline)
(display "Results: ")
(display pass) (display " passed, ")
(display fail) (display " failed\n")
(when (> fail 0) (exit 1))
