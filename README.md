# c0c — C0 Compiler

A compiler for [C0](https://c0.cs.cmu.edu/), CMU's safe subset of C, written
in [Kaappi](https://kaappi-lang.org/) Scheme. Compiles C0 source to native
binaries via C codegen and `zig cc`.

## Quick Start

```
./c0c hello.c0 -o hello
./hello
```

Requires `kaappi` and `zig` on PATH.

## Usage

```
c0c <file.c0> [options]

Options:
  -o <file>        Output binary name (default: a.out)
  --emit-c         Stop after C emission (writes <output>.c)
  --target <T>     Cross-compile target (e.g. x86_64-linux, aarch64-linux)
  --no-check       Disable runtime contract checks
```

## Cross-compilation

```
./c0c hello.c0 -o hello-linux --target x86_64-linux
```

Produces a statically-linked binary for the target platform using zig's
built-in cross-compilation.

## C0 Language

C0 is a statically-typed imperative language — a safe subset of C with:

- Types: `int`, `bool`, `char`, `string`, `void`, pointers (`T*`), arrays (`T[]`), structs
- `alloc(T)` and `alloc_array(T, n)` for heap allocation (garbage-collected)
- Bounds-checked array access, NULL-checked pointer dereference
- No undefined behavior: safe division, shift masking, no pointer arithmetic
- Contract annotations: `//@assert`, `//@requires`, `//@ensures`, `//@loop_invariant`
- `typedef` for type aliases
- Standard libraries: `print`, `println`, `printint`, `readline`, string operations

## Example

```c
struct node {
  int val;
  struct node* next;
};

int list_sum(struct node* head) {
  int sum = 0;
  struct node* cur = head;
  while (cur != NULL) {
    sum += cur->val;
    cur = cur->next;
  }
  return sum;
}

int main() {
  struct node* a = alloc(struct node);
  a->val = 10;
  a->next = NULL;

  struct node* b = alloc(struct node);
  b->val = 20;
  b->next = a;

  printint(list_sum(b));
  println("");
  return 0;
}
```

## Architecture

```
C0 source → Lexer → Parser → Type Checker → C Codegen → zig cc → binary
                                                          ↑
                                                    c0rt.c (runtime)
```

The compiler is ~1,900 lines of Scheme across 5 libraries:

| File | Lines | Role |
|------|-------|------|
| `lib/c0c/lexer.sld` | 352 | Tokenizer |
| `lib/c0c/parser.sld` | 492 | Recursive descent parser with precedence climbing |
| `lib/c0c/checker.sld` | 555 | Type checker, definedness analysis, return-path checking |
| `lib/c0c/codegen.sld` | 388 | C code emitter with safe runtime calls |
| `lib/c0c/driver.sld` | 14 | Pipeline orchestration |

The C runtime (`runtime/c0rt.c`, 167 lines) provides bounds-checked arrays,
NULL-checked dereference, safe integer arithmetic, and the conio/string
standard libraries.

## Testing

```
# Integration tests (10 C0 programs compiled and run)
bash tests/run-tests.sh

# Lexer unit tests (30 tests)
kaappi --lib-path lib tests/test-lexer.scm

# Type checker tests (37 tests)
kaappi --no-jit --lib-path lib tests/test-checker.scm
```

## License

MIT
