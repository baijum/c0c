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

### C0VM bytecode backend [DONE — c0c-bc0.scm]
- Separate script: `kaappi --no-jit --lib-path lib c0c-bc0.scm hello.c0 -o hello`
- Emits .bc0 text bytecode with magic, int/string/function/native pools
- Handles all AST nodes, comparisons, short-circuit, backpatched jumps
- Known limitation: alist-based variable lookup; stack overflow on large programs
- Needs kaappi module register limit increase to work as a proper .sld module

### Choice types (tagged unions) [blocked by VM limit]
- Fully designed: choice/match syntax with pattern matching
- Codegen: C tagged struct + switch/case
- Cannot fit within kaappi VM module bytecode limit

### Futures (future/await) [blocked by VM limit]
- Designed: future_t + await via pthreads
- Same constraint: compiler module additions exceed bytecode limit
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
