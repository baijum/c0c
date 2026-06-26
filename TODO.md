# c0c TODO

## Standard Libraries

### file library
- [x] Runtime: `file_read`, `file_close`, `file_eof`, `file_readline` in c0rt.c
- [x] Compiler: `file_t` opaque type + function signatures registered
- Done: `#use <file>` works end-to-end

### args library
- [x] Runtime: `args_flag`, `args_int`, `args_string`, `args_parse` in c0rt.c
- [x] Compiler: function signatures registered (pointer parameter types)
- Done: `#use <args>` works end-to-end

### parse library
- [x] `parse_bool(string s)` and `parse_int(string s, int base)`
- Done: structs + functions in c0rt.c, signatures in stdlib.sld

### string library
- [x] `string_to_chararray` and `string_from_chararray`
- Done: runtime + compiler registration

### conio library
- [x] All 7 functions: print, println, printint, printbool, printchar, readline, eof

### `#use` directives
- [x] `#use <conio>`, `#use <string>`, `#use <parse>`, `#use <file>`, `#use <args>`
- [x] Only link libraries that are actually imported
- [ ] `#use "filename"` — file inclusion (blocked by VM bytecode limit)

## Runtime Safety

- [x] NULL-checked pointer dereference (all paths through `c0_deref`)
- [ ] Garbage collection (uses `calloc` with no GC)

## Compiler Features

### Contracts
- [x] `@requires`, `@ensures`, `@assert`, `@loop_invariant`
- [x] `\result` in `@ensures` — saves return value, checks postcondition
- [x] `\length(expr)` in contracts — emits `c0_array_length`

### Error handling
- [x] Error messages include line and column numbers
- [ ] Include source filename in errors (blocked by VM bytecode limit)
- [ ] Error recovery — report multiple errors (blocked by VM bytecode limit)

### Not yet implemented
- [ ] `#use "filename"` file inclusion
- [ ] Multiple source file compilation
- [ ] Struct equality error message improvement
- [ ] Array element type annotation on AST

## Optimization
- [ ] `-O1`/`-O2`, `-g`, `-S` flags

## Testing
- [x] 29 integration tests (including runtime safety, contracts, all libraries)
- [x] 53 type checker tests
- [x] 35 lexer tests
- [x] `--no-check` contract suppression test
- [x] Expected-error test infrastructure
- [x] Cross-compilation emit-c test
- [x] GitHub Actions CI workflow
- [ ] Cross-compilation binary execution (needs QEMU)

## VM Bytecode Limit

The kaappi VM limits per-function bytecode to 1MB (`MAX_CODE_BYTES` in
`bytecode_file.zig`). This prevents adding more code to the compiler's
`.sld` library files. Features marked "blocked by VM bytecode limit"
need this constant raised in the kaappi interpreter.
