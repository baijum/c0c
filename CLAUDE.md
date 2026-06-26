# c0c — C0 Compiler

C0-to-native compiler written in Kaappi Scheme. Compiles CMU's safe C subset
to native binaries via C codegen and `zig cc`.

## Build & Run

```bash
./c0c hello.c0 -o hello          # compile to native binary
./c0c hello.c0 -o hello --emit-c # stop after C emission (writes hello.c)
./c0c hello.c0 --target x86_64-linux -o hello  # cross-compile
./c0c hello.c0 --no-check -o hello             # disable contract assertions
```

The `./c0c` wrapper invokes kaappi with `--no-jit --lib-path lib` and passes
`--runtime runtime` automatically. If `kaappi` is not on PATH, set `KAAPPI=`:

```bash
KAAPPI=/path/to/kaappi ./c0c hello.c0 -o hello
```

## Tests

```bash
# Integration tests — compiles and runs 10 C0 programs
bash tests/run-tests.sh
# or with explicit kaappi path:
KAAPPI=/path/to/kaappi bash tests/run-tests.sh

# Lexer unit tests (30 tests, JIT-safe)
kaappi --lib-path lib tests/test-lexer.scm

# Type checker unit tests (37 tests, needs --no-jit)
kaappi --no-jit --lib-path lib tests/test-checker.scm
```

Every change should pass all three test suites before committing.

## Architecture

```
C0 source → Lexer → Parser → Checker → Codegen → .c file → zig cc → binary
                                                      ↑
                                                  c0rt.c linked in
```

Pipeline entry point: `driver.sld:compile-c0-to-c` calls lex → parse → check → emit
in sequence. The CLI (`c0c.scm`) writes the emitted C to a temp file and invokes
`zig cc -O0 -fwrapv -std=c11` via FFI `system()`.

## File Map

| File | Lines | What it does |
|------|-------|-------------|
| `lib/c0c/lexer.sld` | 352 | Tokenizer. Closure-based (make-lexer returns `(next-fn peek-fn)`). Handles all C0 tokens including multi-char operators (`<<=`, `->`, `&&`) and `//@annotation` comments. |
| `lib/c0c/parser.sld` | 492 | Recursive descent with Pratt precedence climbing for expressions. Produces tagged-list AST. Tracks known typedefs for declaration/expression disambiguation. |
| `lib/c0c/checker.sld` | 555 | Type checker. Scope-stack environment, definedness analysis (assignment-before-use), return-on-all-paths, break/continue in loops. Registers library function signatures in `register-library-funcs!`. |
| `lib/c0c/codegen.sld` | 388 | Emits C code. Accumulates string chunks in a list (not a string port — that crashes Kaappi on large programs). Tracks `var-types` hash table for correct array element casts. |
| `lib/c0c/driver.sld` | 14 | Wires lex→parse→check→emit. Thin glue. |
| `c0c.scm` | 81 | CLI. Parses args, calls `compile-c0-to-c`, writes .c file, invokes `zig cc` via `ffi-open`/`ffi-fn` on libc's `system()`. |
| `runtime/c0rt.h` | 53 | Runtime API: array ops, safe arithmetic, NULL checks, conio, string library. |
| `runtime/c0rt.c` | 167 | Runtime implementation. `main()` calls `_c0_main()`. |
| `c0c` | 8 | Shell wrapper — sets `--no-jit`, `--lib-path`, `--runtime` automatically. |

## Data Representations

### Tokens: `(tag value line col)`

Tags are symbols: `kw-int`, `kw-return`, `ident`, `int-lit`, `string-lit`,
`char-lit`, `op-plus`, `op-lshift-eq`, `anno-assert`, `lparen`, `semi`, `eof`, etc.

Accessors: `tok-tag`, `tok-val`, `tok-line`, `tok-col` (exported from lexer).

### AST: tagged lists with source location

**Types:** `(ty-int)`, `(ty-bool)`, `(ty-char)`, `(ty-string)`, `(ty-void)`,
`(ty-ptr <type>)`, `(ty-arr <type>)`, `(ty-struct <name>)`, `(ty-name <alias>)`.

**Expressions:** `(e-int val ln col)`, `(e-var name ln col)`,
`(e-binop op lhs rhs ln col)`, `(e-call name args ln col)`,
`(e-index arr idx ln col)`, `(e-field expr name ln col)`,
`(e-alloc type ln col)`, `(e-alloc-array type count ln col)`, etc.

**Statements:** `(s-decl type name init ln col)`, `(s-assign lhs op rhs ln col)`,
`(s-return expr ln col)`, `(s-block stmts ln col)`, `(s-if cond then else ln col)`,
`(s-while cond body ln col)`, `(s-for init cond step body ln col)`,
`(s-assert expr ln col)`, `(s-requires expr ln col)`, etc.

**Top-level:** `(g-func ret-type name params body ln col)` (body is `#f` for
forward declarations), `(g-typedef type name ln col)`,
`(g-struct-def name fields ln col)`, `(g-struct-decl name ln col)`.

**Program:** `(program (list-of-gdecls))`.

Assignment operators use `asgn-*` symbols: `asgn`, `asgn-plus`, `asgn-minus`,
`asgn-star`, `asgn-slash`, `asgn-percent`, `asgn-amp`, `asgn-pipe`,
`asgn-caret`, `asgn-lshift`, `asgn-rshift`. (Bare `|` is not a valid Scheme
symbol character, so `'|=` cannot be used.)

Binary operator names in the AST: `plus`, `minus`, `star`, `slash`, `percent`,
`amp`, `pipe`, `caret`, `lshift`, `rshift`, `lt`, `le`, `gt`, `ge`, `eq-eq`,
`ne`, `amp-amp`, `pipe-pipe`.

Unary operators: `neg`, `lognot`, `bitnot`, `deref`.

### Checker state (module-level mutables, reset per `check-program` call)

- `funcs` — hash table: function name → `(ret-type . param-types)`
- `structs` — hash table: struct name → `((type name) ...)`
- `typedefs` — hash table: alias → resolved type
- `env` — list of hash tables (scope stack): variable name → type
- `defined` — hash table: variable name → `#t` (definitely assigned)
- `in-loop` — boolean
- `current-ret-type` — type of the function being checked

`check-stmt` returns `#t` if the statement definitely returns on all paths.

### Codegen state

- `chunks` — list of strings (reversed), joined at end via `join-chunks`
- `var-types` — hash table: variable name → declared type (for array element casts)
- `emit-contracts` — boolean (controlled by `--no-check`)
- `library-funcs` — hash table of names that should NOT be mangled

## C Code Generation Rules

- User function `foo` → `_c0_foo` in emitted C. Library functions are not mangled.
- `int` → `int32_t`, `bool` → `bool`, `string` → `c0_string`, `T[]` → `c0_array*`
- Division/modulo → `c0_idiv(a, b)` / `c0_imod(a, b)` (checks div-by-zero + INT32_MIN/-1)
- Shifts → `c0_ishl(a, b)` / `c0_ishr(a, b)` (masks shift amount to 5 bits)
- Array access `a[i]` → `(*(elem_type*)c0_array_sub(a, i))` (bounds-checked)
- Pointer deref `*p` → `(*(p))` (no NULL check in codegen; runtime crash on NULL)
- `alloc(T)` → `(T*)c0_alloc(sizeof(T))`
- `alloc_array(T, n)` → `c0_alloc_array(sizeof(T), n)`
- Contract annotations → `c0_assert(expr, "s-assert failed at line N")`
- Compiled with `zig cc -O0 -fwrapv -std=c11` (`-fwrapv` makes signed overflow defined)

## Kaappi Quirks to Know

- **No JIT for large programs.** The `--no-jit` flag is required when compiling
  C0 programs with more than ~30 statements. The JIT has a bug with larger
  compiled Scheme closures. The `./c0c` wrapper passes `--no-jit` automatically.

- **No `#\nul`.** Use `#\null` (two l's). `#\nul` triggers a reader error.

- **No `|` in symbols.** `|` starts an escaped identifier in R7RS. Use
  `asgn-pipe` instead of `'|=`. Pipes inside *strings* (`"|="`) are fine.

- **No `symbol-hash`.** SRFI-69 provides `string-hash` but not `symbol-hash`.
  Use `(make-hash-table eq?)` for symbol-keyed tables.

- **No `cadar` in `(scheme base)`.** Use `(cadr (car x))` instead, or import
  `(scheme cxr)`.

- **`string->number` ignores `#x` prefix.** Use `(string->number hex-str 16)`
  instead of `(string->number (string-append "#x" hex-str))`.

- **`command-line` includes the script.** `(command-line)` returns
  `("kaappi" "script.scm" args...)`. Use `(cddr (command-line))` to get
  user-provided arguments.

- **FFI only at top level.** `ffi-open` and `ffi-fn` work at the REPL and in
  top-level scripts but are not available inside `define-library`. Move FFI
  calls to `c0c.scm` (the CLI), not into `.sld` library files.

- **`open-output-string` crashes on large output.** The codegen accumulates
  strings in a list (`chunks`) and joins them with `join-chunks` using
  `for-each`/`write-string`. Do NOT use `(apply string-append ...)` on large
  lists — it causes stack overflow.

## How to Add a New C0 Feature

1. **Lexer** (`lexer.sld`): add token tag to `scan-token` dispatch and to
   `keyword-table` if it's a keyword.

2. **Parser** (`parser.sld`): add parsing in the appropriate grammar rule
   (`parse-stmt`, `parse-expr`, `parse-gdecl`, etc.). Produce a new AST node.

3. **Checker** (`checker.sld`): add type-checking logic in `check-expr` or
   `check-stmt`. If it's a new type, update `resolve-type`. If it's a new
   library function, add to `register-library-funcs!`.

4. **Codegen** (`codegen.sld`): add emission in `emit-expr`, `emit-stmt`, or
   `emit-gdecl`. Map the AST node to the correct C code.

5. **Runtime** (`c0rt.h` + `c0rt.c`): if the feature needs runtime support
   (new safe operation, new library function), add it here.

6. **Tests**: add a `.c0` program in `tests/programs/`, add it to
   `tests/run-tests.sh`, and add checker accept/reject cases to
   `tests/test-checker.scm` if type rules are involved.

## C0 Language Reference

The full C0 specification is in `CMU-CS-10-145.pdf` (Rob Arnold's thesis).

Key differences from C: no unions, no casts, no pointer arithmetic, no sizeof,
no goto/switch/do-while, no floats, no unsigned types, no address-of (`&`),
no explicit free (garbage-collected), no assignments in expressions,
bounds-checked arrays, NULL-checked pointers (at runtime).

## What's Not Yet Implemented

- `#use <lib>` directives (conio/string are always available)
- `file` library (file_read, file_close, file_eof, file_readline)
- `args` library (args_flag, args_int, args_string, args_parse)
- `parse` library (parse_int, parse_bool)
- `string_to_chararray` / `string_from_chararray` (declared in runtime but
  not yet implemented in c0rt.c)
- Garbage collection (uses `calloc` with no GC — long-running programs leak)
- `\result` in `@ensures` annotations
- Multiple source file compilation
- Error recovery (compiler aborts on first error)
