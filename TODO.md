# c0c TODO

## Bugs (Correctness)

### Compound assignment safety bypass [HIGH]
- `x /= y` emits raw C `/=` instead of `x = c0_idiv(x, y)`
- `x %= y` emits raw C `%=` instead of `x = c0_imod(x, y)`
- `x <<= y` emits raw C `<<=` instead of `x = c0_ishl(x, y)`
- `x >>= y` emits raw C `>>=` instead of `x = c0_ishr(x, y)`
- Effect: div-by-zero crashes silently, INT_MIN/-1 not caught, shifts not masked
- Fix: in codegen `s-assign`, detect `/=`, `%=`, `<<=`, `>>=` and emit as
  `lhs = c0_idiv(lhs, rhs)` etc. instead of `lhs /= rhs`
- File: `lib/c0c/codegen.sld` in `emit-stmt` case `s-assign`

### Negation overflow not caught [MEDIUM]
- `-(-2147483648)` silently wraps to -2147483648 instead of aborting
- The C0 spec says negation that overflows must raise a runtime error
- Fix: add `c0_ineg(int32_t a)` to `c0rt.c` that checks `a == INT32_MIN`
  and aborts; emit `c0_ineg(expr)` instead of `(-(expr))` in codegen
- Files: `runtime/c0rt.c`, `lib/c0c/codegen.sld`

### Variable shadowing allowed [MEDIUM]
- C0 spec: "Two variables of the same name may not have overlapping scopes"
- Currently only checks current scope, not outer scopes
- `int x = 1; { int x = 2; }` should be rejected but is accepted
- Fix: in checker `declare-var!`, walk all scopes in `env`, not just `(car env)`
- File: `lib/c0c/checker.sld` in `declare-var!`

### Char comparisons rejected [MEDIUM]
- `'a' < 'b'` is rejected with "comparison requires int operands"
- The C0 spec allows `<`, `<=`, `>`, `>=` on char values (ordered by ASCII)
- Fix: add `(eq? (car rl) 'ty-char) (eq? (car rr) 'ty-char)` check to the
  `lt le gt ge` case in `check-expr`
- File: `lib/c0c/checker.sld` in `check-expr` binop case

### Leading-zero decimal literals accepted [LOW]
- `007` is parsed as decimal 7 instead of being rejected
- C0 spec: "first digit is not 0" for decimal literals (avoids octal confusion)
- Fix: in lexer `scan-number`, reject digits starting with 0 followed by
  more digits (0 alone and 0x... are fine)
- File: `lib/c0c/lexer.sld` in `scan-number`

### Missing escape sequences [LOW]
- `\v`, `\f`, `\a`, `\?` not recognized in strings/chars
- These are valid C0 escape sequences per the reference grammar
- Fix: add cases to `scan-escape` in the lexer
- File: `lib/c0c/lexer.sld` in `scan-escape`

### Heap-allocated string/array fields get wrong defaults [LOW]
- `alloc(struct S)` where S has a `string` field: field gets NULL instead of `""`
- `alloc(struct S)` where S has a `T[]` field: field gets NULL instead of empty array
- C0 spec requires `""` and zero-length array as defaults
- Fix: would require codegen to emit per-field initialization after `c0_alloc`,
  or a runtime helper that handles typed initialization
- Files: `lib/c0c/codegen.sld`, possibly `runtime/c0rt.c`

## New Features

### Granular contract levels (`--check=0/1/2`) [HIGH, ~20 lines]
- Currently `--no-check` is binary (all or nothing)
- Proposed: `--check=0` (none), `--check=1` (requires/ensures only),
  `--check=2` (all including loop_invariant and assert)
- Matches CMU's `cc0` compiler which has `-d` flags for contract levels
- Lets users keep precondition checks in production while skipping expensive
  loop invariants
- File: `c0c.scm` (flag parsing), `lib/c0c/codegen.sld` (check level per stmt)

### `=>` implication operator in contracts [HIGH, ~15 lines]
- The C0 grammar specifies `=>` as a binary operator (logical implication)
- Precedence: between `||` and `?:` (lowest binary operator)
- Semantics: `a => b` is equivalent to `!a || b`
- Useful in contracts: `//@requires n > 0 => arr != NULL;`
- Lexer: recognize `=>` as `op-implies`
- Parser: add to precedence table at level 2 (below `||` at 3)
- Codegen: emit `(!(a) || (b))`
- Files: `lib/c0c/lexer.sld`, `lib/c0c/parser.sld`, `lib/c0c/codegen.sld`

### Typecheck-only mode (`-t` flag) [HIGH, ~5 lines]
- Stop after type checking, don't emit C or compile
- Useful for IDE integration (fast feedback without compilation)
- Exit 0 if type-correct, non-zero with error messages if not
- File: `c0c.scm` (add flag, skip codegen/zig cc when set)

### C0VM bytecode backend [MEDIUM, ~800-1200 lines]
- Emit `.bc0` bytecode instead of C code (new `--emit-bc0` flag)
- C0VM is a stack machine with ~35 opcodes (iadd, isub, imul, idiv, vload,
  vstore, if_cmplt, goto, invokestatic, new, newarray, aaddf, aadds, etc.)
- `.bc0` format: magic, int pool, string pool, function pool, native pool
- Enables:
  - **Browser execution** via Kaappi WASM playground (no zig cc needed)
  - **Sandboxed execution** of untrusted code (student submissions)
  - **Step-through debugging** and instruction-level tracing
  - **CMU compatibility** with their C0VM tooling
- Implementation: new `codegen-bc0.sld` (~400 lines) for bytecode emission,
  new `c0vm.sld` (~400 lines) for interpreter, label backpatching for jumps
- Existing pipeline (lexer/parser/checker) stays unchanged

### Choice types (tagged unions) [MEDIUM, ~300 lines]
- C0 has no unions or enums — a real gap for data modeling
- Inspired by CC0's `choice` types, but purely sequential (no concurrency)
- Syntax: `choice shape { Circle(int radius); Square(int side); };`
- Pattern matching: `switch (s) { case Circle(r): ... case Square(s): ... }`
- Codegen: C tagged struct with int tag + union body
- Files: all compiler phases (lexer keyword, parser grammar, checker
  exhaustiveness, codegen tagged union emission)

### Futures (`future`/`await`) [MEDIUM, ~300 lines]
- Simplest useful concurrency model — fork/join parallelism
- `future_t f = future(expr)` spawns computation in a new pthread
- `int result = await(f)` blocks until the result is ready
- Runtime: pthread_create + result struct with mutex/condvar
- No channels, no session types, no linear types needed
- Example: `future_t f1 = future(fib(n-1)); return await(f1) + fib(n-2);`
- Files: `runtime/c0rt.c` (~100 lines), checker (~100 lines), codegen (~100 lines)

### Static warnings for library preconditions [LOW, ~100 lines]
- Catch obvious violations at compile time instead of runtime:
  - `string_charat(s, -1)` — literal negative index
  - `string_sub(s, 5, 3)` — literal start > end
  - `c0_idiv(x, 0)` — literal zero divisor
  - `alloc_array(int, -1)` — literal negative count
- Implement as special cases in checker's `e-call` handling for known
  library functions with constant arguments
- File: `lib/c0c/checker.sld` in `check-expr` e-call case

### Multi-line contract annotations (`/*@ ... @*/`) [LOW, ~30 lines]
- Currently only `//@ ...` single-line annotations are supported
- The C0 spec also allows `/*@ ... @*/` block annotations
- Useful for long contracts that span multiple lines
- Fix: in lexer's `skip-block-comment`, detect `@` after `/*` and parse
  as a multi-line annotation
- File: `lib/c0c/lexer.sld`

## Completed

All items below are implemented and tested (138 tests passing):

- 5 standard libraries (conio, string, parse, file, args)
- `#use <lib>` and `#use "filename"` directives
- NULL-checked pointer dereference, Boehm GC (`--gc`)
- Contracts: `@requires`, `@ensures`, `@assert`, `@loop_invariant`
- Contract variables: `\result`, `\length(e)`, `\old(e)`
- Error handling: filename, line, column, source caret, error recovery, warnings
- Compilation: multi-file, forward declarations, `-O0/-O1/-O2/-Oz`, `-g`, `-S`
- Cross-compilation with `--target`, auto-strip symbols
- Struct equality error message, 70 checker rejection tests
- CI workflow, cross-compilation binary format test
