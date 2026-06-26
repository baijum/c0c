# c0c — C0 Compiler

A compiler for [C0](https://c0.cs.cmu.edu/), CMU's safe subset of C, written
in [Kaappi](https://kaappi-lang.org/) Scheme. Compiles C0 source to native
binaries via C codegen and `zig cc`.

## Quick Start

```
./c0c hello.c0 -o hello
./hello
```

Requires `kaappi` (v0.6.3+) and `zig` on PATH.

## Usage

```
c0c <file.c0> [file2.c0 ...] [options]

Options:
  -o <file>        Output binary name (default: a.out)
  --emit-c         Stop after C emission (writes <output>.c)
  --target <T>     Cross-compile (e.g. x86_64-linux, aarch64-linux)
  --no-check       Disable runtime contract checks
  -O0|-O1|-O2|-Oz  Optimization level (default: -O0)
  -g               Include debug symbols
  -S               Emit assembly (.s) instead of binary
  --gc             Enable garbage collection (Boehm GC)
  --runtime <dir>  Path to c0c runtime directory
```

## Features

### Language

All C0 language features from the [CMU specification](https://c0.cs.cmu.edu/):

- Types: `int`, `bool`, `char`, `string`, `void`, pointers (`T*`), arrays (`T[]`), structs, `typedef`
- `alloc(T)` and `alloc_array(T, n)` for heap allocation
- Bounds-checked arrays, NULL-checked pointer dereference
- Safe division, modulo, and shift operations (no undefined behavior)
- Contract annotations: `//@assert`, `//@requires`, `//@ensures`, `//@loop_invariant`
- Special contract variables: `\result`, `\length(e)`, `\old(e)`

### Standard Libraries

| Library | Directive | Functions |
|---------|-----------|-----------|
| conio | `#use <conio>` | print, println, printint, printbool, printchar, readline, eof |
| string | `#use <string>` | string_length, string_charat, string_sub, string_join, string_compare, string_equal, string_fromint, string_frombool, string_fromchar, char_ord, char_chr, string_to_chararray, string_from_chararray |
| parse | `#use <parse>` | parse_bool, parse_int |
| file | `#use <file>` | file_read, file_close, file_eof, file_readline |
| args | `#use <args>` | args_flag, args_int, args_string, args_parse |

### Compilation

- Multiple source files: `./c0c lib.c0 main.c0 -o prog`
- File inclusion: `#use "helpers.c0"` in source
- Cross-compilation to any zig-supported target
- Optimization levels with `-fwrapv` for safe integer semantics
- Debug symbols and assembly output

### Error Messages

```
tests/programs/err-type-mismatch.c0:2: type mismatch in declaration of x
  int x = true;
      ^
```

Errors include source filename, line number, the source line, and a caret
pointing to the error column. The compiler continues past errors to report
multiple issues.

## Example

```c
#use <conio>

int factorial(int n)
//@requires n >= 0;
//@ensures \result >= 1;
{
  int r = 1;
  for (int i = 1; i <= n; i++)
  //@loop_invariant r >= 1;
  {
    r *= i;
  }
  return r;
}

int main() {
  printint(factorial(10));
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

The compiler is ~2,000 lines of Scheme across 7 libraries, plus a 400-line
C runtime:

| File | Lines | Role |
|------|------:|------|
| `lib/c0c/lexer.sld` | 395 | Tokenizer with `\result`/`\length`/`\old` support |
| `lib/c0c/parser.sld` | 497 | Recursive descent with Pratt precedence climbing |
| `lib/c0c/checker.sld` | 578 | Type checker, definedness, error recovery, source caret |
| `lib/c0c/codegen.sld` | 404 | C emitter with ensures-at-return, `\old` captures |
| `lib/c0c/stdlib.sld` | 95 | Library registry and name mangling |
| `lib/c0c/codegen-util.sld` | 36 | Operator mappings and helpers |
| `lib/c0c/driver.sld` | 18 | Pipeline orchestration |
| `c0c.scm` | 139 | CLI, preprocessor, `zig cc` invocation |
| `runtime/c0rt.c` | 332 | Runtime: arrays, arithmetic, strings, file I/O, args, GC |
| `runtime/c0rt.h` | 74 | Runtime API |

## Testing

```bash
# Integration tests (33 programs compiled and run)
bash tests/run-tests.sh

# Lexer unit tests (35 tests)
kaappi --lib-path lib tests/test-lexer.scm

# Type checker tests (70 tests)
kaappi --no-jit --lib-path lib tests/test-checker.scm
```

138 tests total covering all language features, runtime safety, contract
enforcement, cross-compilation, multi-file compilation, and error rejection.

## Garbage Collection

Pass `--gc` to enable Boehm GC. Requires `libgc` installed:

```bash
brew install bdw-gc       # macOS
apt install libgc-dev     # Ubuntu/Debian

./c0c program.c0 -o program --gc
```

Without `--gc`, the runtime uses `malloc`/`calloc` with no collection.

## C0 Language Reference

The full C0 specification is in `resources/c0-language-thesis.pdf`
(Rob Arnold's thesis, CMU-CS-10-145).

Key differences from C: no unions, no casts, no pointer arithmetic, no sizeof,
no goto/switch/do-while, no floats, no unsigned types, no address-of (`&`),
no explicit free, no assignments in expressions. Arrays are bounds-checked
and pointers are NULL-checked at runtime.

## License

MIT
