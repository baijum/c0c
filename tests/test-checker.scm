(import (scheme base) (scheme write)
        (c0c lexer) (c0c parser) (c0c checker))

(define pass 0)
(define fail 0)

(define (check-accepts name code)
  (let* ((lex (make-lexer (open-input-string code) "<test>"))
         (ast (parse-program lex)))
    (guard (exn (#t
                 (set! fail (+ fail 1))
                 (display "  FAIL: ") (display name)
                 (display " (should accept but rejected)\n")))
      (check-program ast)
      (set! pass (+ pass 1))
      (display "  PASS: ") (display name) (newline))))

(define (check-rejects name code)
  (let* ((lex (make-lexer (open-input-string code) "<test>"))
         (ast (parse-program lex)))
    (guard (exn (#t
                 (set! pass (+ pass 1))
                 (display "  PASS: ") (display name) (newline)))
      (check-program ast)
      (set! fail (+ fail 1))
      (display "  FAIL: ") (display name)
      (display " (should reject but accepted)\n"))))

(display "=== Type Checker Tests ===\n")

(display "Accepts valid programs:\n")

(check-accepts "simple main"
  "int main() { return 0; }")

(check-accepts "arithmetic"
  "int main() { int x = 1 + 2; return x; }")

(check-accepts "bool comparison"
  "int main() { bool b = 3 < 5; return 0; }")

(check-accepts "pointer alloc"
  "int main() { int* p = alloc(int); *p = 42; return *p; }")

(check-accepts "array alloc"
  "int main() { int[] a = alloc_array(int, 5); a[0] = 1; return a[0]; }")

(check-accepts "null to pointer"
  "int main() { int* p = NULL; return 0; }")

(check-accepts "function call"
  "int add(int a, int b) { return a + b; }
   int main() { return add(1, 2); }")

(check-accepts "void function"
  "void foo() { return; }
   int main() { foo(); return 0; }")

(check-accepts "while loop"
  "int main() { int i = 0; while (i < 10) { i++; } return i; }")

(check-accepts "for loop with break"
  "int main() { for (int i = 0; i < 10; i++) { if (i == 5) break; } return 0; }")

(check-accepts "ternary"
  "int main() { int x = true ? 1 : 2; return x; }")

(check-accepts "struct"
  "struct pt { int x; int y; };
   int main() { struct pt* p = alloc(struct pt); p->x = 1; return p->x; }")

(display "\nRejects invalid programs:\n")

(check-rejects "add int and bool"
  "int main() { int x = 1 + true; return 0; }")

(check-rejects "if with int condition"
  "int main() { if (42) { return 1; } return 0; }")

(check-rejects "while with int condition"
  "int main() { while (1) { break; } return 0; }")

(check-rejects "wrong return type"
  "int main() { return true; }")

(check-rejects "undeclared variable"
  "int main() { return x; }")

(check-rejects "undeclared function"
  "int main() { return foo(); }")

(check-rejects "wrong arg count"
  "int add(int a, int b) { return a + b; }
   int main() { return add(1); }")

(check-rejects "wrong arg type"
  "int foo(int x) { return x; }
   int main() { return foo(true); }")

(check-rejects "deref non-pointer"
  "int main() { int x = 5; return *x; }")

(check-rejects "index non-array"
  "int main() { int x = 5; return x[0]; }")

(check-rejects "break outside loop"
  "int main() { break; return 0; }")

(check-rejects "continue outside loop"
  "int main() { continue; return 0; }")

(check-rejects "void variable"
  "int main() { void x; return 0; }")

(check-rejects "logical and with ints"
  "int main() { int x = 1 && 2; return 0; }")

(check-rejects "assign type mismatch"
  "int main() { int x = 0; x = true; return 0; }")

(check-rejects "comparison of bool"
  "int main() { bool b = true < false; return 0; }")

(display "\nDefinedness analysis:\n")

(check-rejects "use before assign"
  "int main() { int x; return x; }")

(check-accepts "assign then use"
  "int main() { int x; x = 5; return x; }")

(check-accepts "init in decl counts as assign"
  "int main() { int x = 10; return x; }")

(check-rejects "use in one branch only"
  "int main() { int x; if (true) { x = 1; } return x; }")

(check-accepts "assign in both branches"
  "int main() { int x; if (true) { x = 1; } else { x = 2; } return x; }")

(display "\nReturn checking:\n")

(check-rejects "missing return"
  "int foo() { int x = 5; }")

(check-accepts "return in both if branches"
  "int foo(bool b) { if (b) { return 1; } else { return 0; } }")

(check-rejects "return only in one branch"
  "int foo(bool b) { if (b) { return 1; } }")

(check-accepts "void function no return needed"
  "void foo() { int x = 1; }")

(newline)
(display "Results: ")
(display pass) (display " passed, ")
(display fail) (display " failed\n")
(when (> fail 0) (exit 1))
