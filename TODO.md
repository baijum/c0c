# c0c TODO

## Bugs (Correctness)

- [x] Compound assignment `/=`, `%=`, `<<=`, `>>=` now route through safe runtime functions
- [x] Negation overflow: `c0_ineg` aborts on INT32_MIN
- [x] Variable shadowing rejected across all scopes
- [x] Char comparisons (`<`, `<=`, `>`, `>=`) accepted
- [x] Leading-zero decimal literals rejected
- [x] Missing escape sequences `\v`, `\f`, `\a`, `\?` added
- [ ] Heap-allocated string/array fields get NULL instead of `""`/empty-array
  (known deviation from spec; same behavior as reference cc0 compiler)

## Implemented Features

- [x] `--check=0|1|2` granular contract levels
- [x] `=>` implication operator in contracts
- [x] `-t` typecheck-only mode
- [x] Static warnings for library precondition violations
- [x] `/*@ ... @*/` multi-line contract annotations

## Future Features

### C0VM bytecode backend [~800-1200 lines]
- Emit `.bc0` bytecode instead of C code (new `--emit-bc0` flag)
- C0VM is a stack machine with ~35 opcodes
- Enables browser execution, sandboxed execution, step-through debugging
- New `codegen-bc0.sld` (~400 lines) + `c0vm.sld` interpreter (~400 lines)

### Choice types (tagged unions) [~300 lines]
- C0 has no unions or enums — fills a real gap for data modeling
- Syntax: `choice shape { Circle(int radius); Square(int side); };`
- Pattern matching via `switch` on choice values
- All compiler phases need changes

### Futures (`future`/`await`) [~300 lines]
- Fork/join parallelism via pthreads
- `future_t f = future(expr)` + `int result = await(f)`
- Runtime: pthread_create + result struct with mutex/condvar

## Completed

All items below are implemented and tested (140 tests passing):

- 5 standard libraries, `#use <lib>` and `#use "filename"` directives
- NULL-checked pointers, Boehm GC (`--gc`)
- Contracts: `@requires`, `@ensures`, `@assert`, `@loop_invariant`
- Contract variables: `\result`, `\length(e)`, `\old(e)`, `=>` operator
- `--check=0|1|2` granular levels, `-t` typecheck-only
- Error handling: filename, line, caret, recovery, warnings, static checks
- Multi-file compilation, forward declarations
- `-O0/-O1/-O2/-Oz`, `-g`, `-S`, `--target`, auto-strip
- Safe compound assignments, negation overflow, shadowing rejection
- `/*@ ... @*/` multi-line annotations
- 33 integration + 72 checker + 35 lexer = 140 tests, CI workflow
