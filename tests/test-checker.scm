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

(check-rejects "unary neg on bool"
  "int main() { int x = -true; return 0; }")

(check-rejects "logical not on int"
  "int main() { bool b = !42; return 0; }")

(check-rejects "ternary with int condition"
  "int main() { int x = 42 ? 1 : 2; return 0; }")

(check-rejects "ternary branches differ"
  "int main() { int x = true ? 1 : true; return 0; }")

(check-rejects "array index must be int"
  "int main() { int[] a = alloc_array(int, 5); int x = a[true]; return 0; }")

(check-rejects "alloc_array count must be int"
  "int main() { int[] a = alloc_array(int, true); return 0; }")

(check-accepts "char comparison"
  "int main() { bool b = 'a' < 'z'; return 0; }")

(check-rejects "variable shadowing"
  "int main() { int x = 1; { int x = 2; } return 0; }")

(check-accepts "implication operator in contract"
  "int foo(int n, int[] a)\n//@requires n > 0 => a != NULL;\n{ return 0; }")

(check-rejects "struct as local variable"
  "struct pt { int x; };\nint main() { struct pt p; return 0; }")

(check-rejects "struct equality"
  "struct pt { int x; };\nint main() { struct pt* a = alloc(struct pt); struct pt* b = alloc(struct pt); bool eq = (*a == *b); return 0; }")

(check-rejects "assignment target must be lvalue"
  "int main() { 42 = 1; return 0; }")

(check-rejects "compound assign requires int"
  "int main() { bool b = true; b += 1; return 0; }")

(check-rejects "postop requires int"
  "int main() { bool b = true; b++; return 0; }")

(check-rejects "for condition must be bool"
  "int main() { for (int i = 0; 1; i++) {} return 0; }")

(check-rejects "field access on non-pointer"
  "int main() { int x = 5; int y = x->foo; return 0; }")

(check-rejects "field on non-struct pointer"
  "int main() { int* p = alloc(int); int y = p->foo; return 0; }")

(check-rejects "no such field"
  "struct pt { int x; };\nint main() { struct pt* p = alloc(struct pt); int y = p->z; return 0; }")

(check-rejects "variable already declared"
  "int main() { int x = 1; int x = 2; return 0; }")

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

(display "\n#use directives:\n")

(check-accepts "#use conio allows printint"
  "#use <conio>\nint main() { printint(42); return 0; }")

(check-accepts "#use string allows string_length"
  "#use <string>\nint main() { int n = string_length(\"hi\"); return 0; }")

(check-accepts "#use conio and string"
  "#use <conio>\n#use <string>\nint main() { printint(string_length(\"hi\")); return 0; }")

(check-rejects "printint without #use conio"
  "int main() { printint(42); return 0; }")

(check-rejects "string_length without #use string"
  "int main() { int n = string_length(\"hi\"); return 0; }")

(check-rejects "#use conio does not give string funcs"
  "#use <conio>\nint main() { int n = string_length(\"hi\"); return 0; }")

(check-rejects "unknown library"
  "#use <unknown>\nint main() { return 0; }")

(check-accepts "#use parse allows parse_int"
  "#use <parse>\nint main() { struct parsed_int* p = parse_int(\"42\", 10); return 0; }")

(check-accepts "#use parse allows parse_bool"
  "#use <parse>\nint main() { struct parsed_bool* p = parse_bool(\"true\"); return 0; }")

(check-accepts "#use parse allows field access on result"
  "#use <conio>\n#use <parse>\nint main() { struct parsed_int* p = parse_int(\"1\", 10); if (p != NULL) { printint(p->result); } return 0; }")

(check-rejects "parse_int without #use parse"
  "int main() { struct parsed_int* p = parse_int(\"42\", 10); return 0; }")

(check-rejects "parse_bool without #use parse"
  "int main() { struct parsed_bool* p = parse_bool(\"true\"); return 0; }")

(check-accepts "#use string allows string_to_chararray"
  "#use <string>\nint main() { char[] a = string_to_chararray(\"hi\"); return 0; }")

(check-accepts "#use string allows string_from_chararray"
  "#use <string>\nint main() { char[] a = string_to_chararray(\"hi\"); string s = string_from_chararray(a); return 0; }")

(display "\nContract special variables:\n")

(check-accepts "\\result in @ensures"
  "int foo(int x)\n//@ensures \\result >= 0;\n{ return x; }")

(check-accepts "\\length in @requires"
  "int sum(int[] a, int n)\n//@requires n == \\length(a);\n{ return 0; }")

(check-accepts "\\old in @ensures"
  "int inc(int x)\n//@ensures \\result == \\old(x) + 1;\n{ return x + 1; }")

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
