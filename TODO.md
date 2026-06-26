# c0c TODO

## Standard Libraries

### All libraries implemented
- [x] **conio**: print, println, printint, printbool, printchar, readline, eof
- [x] **string**: all 11 functions + string_to_chararray, string_from_chararray
- [x] **parse**: parse_bool, parse_int (base 8/10/16)
- [x] **file**: file_read, file_close, file_eof, file_readline (with file_t opaque type)
- [x] **args**: args_flag, args_int, args_string, args_parse

### `#use` directives
- [x] `#use <conio>`, `#use <string>`, `#use <parse>`, `#use <file>`, `#use <args>`
- [x] `#use "filename"` — file inclusion via preprocessor in c0c.scm
- [x] Only link libraries that are actually imported

## Runtime Safety

### NULL-checked pointer dereference
- [x] Codegen: emit `*((T*)c0_deref(p))` for pointer reads
- [x] Codegen: emit `*((T*)c0_deref(p)) = expr` for pointer writes
- [x] Codegen: emit `((T*)c0_deref(p))->field` for struct field access

### Garbage collection
- [ ] Integrate Boehm GC (`GC_malloc` instead of `calloc`)
- [ ] Alternatively, implement a simple mark-and-sweep in c0rt.c
- Currently uses `calloc` with no collection — long-running programs leak

## Compiler Features

### Contracts
- [x] `@requires`, `@ensures`, `@assert`, `@loop_invariant`
- [x] `\result` in `@ensures` — saves return value, checks postcondition at return
- [x] `\length(expr)` in contracts — emits `c0_array_length`
- [x] `\old(e)` in `@ensures` — captures value at function entry, uses saved variable in postcondition check

### Error handling
- [x] Error messages include line and column numbers
- [x] Source filename in error messages
- [x] Error recovery — continues checking after per-declaration errors
- [ ] Show the source line with a caret pointing to the error column
- [ ] Distinguish errors from warnings

### Multiple source files
- [ ] Accept multiple `.c0` files on the command line
- [ ] Compile each to C, link together with a single `zig cc` invocation
- [ ] Check for duplicate function/struct/typedef definitions across files

### Struct equality and copy
- [ ] C0 does not allow `==` or `=` on struct values (only pointers)
- [ ] The checker enforces this, but the error message could be more specific

### Array element type in codegen
- [ ] Currently infers array element type from `var-types` hash table
- [ ] Fails for array expressions that aren't simple variables (e.g. `f()[i]`)
- [ ] With the type checker, annotate the AST with resolved types instead

## Optimization

### Compilation flags
- [ ] Support `-O1`/`-O2` for optimized builds (needs careful handling of C UB)
- [ ] Support `-g` for debug info in compiled binaries
- [ ] Support `-S` to emit assembly

### Compiled output size
- [ ] Strip debug symbols by default for release builds
- [ ] Consider `-Oz` for size-optimized binaries

## Testing

### Test coverage
- [x] Runtime safety: NULL deref, array OOB, div-by-zero, mod-by-zero, INT32_MIN/-1
- [x] `--no-check` suppresses contract assertions
- [x] Expected-error tests (compile should fail with specific error)
- [x] `#use "filename"` file inclusion
- [ ] Test error messages for all type checker rejections
- [ ] Cross-compilation binary execution (needs QEMU or Docker)

### Test infrastructure
- [x] Runtime-abort tests (`run_abort_test`)
- [x] Expected-error tests (`run_error_test`)
- [x] Cross-compilation emit-c test (`run_cross_test`)
- [x] `--no-check` test (`run_nocheck_test`)
- [x] CI workflow (`.github/workflows/ci.yml`)

### Test counts
- 31 integration tests
- 54 type checker tests
- 35 lexer tests
- 120 total
