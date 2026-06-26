# c0c TODO

## Standard Libraries

### All libraries implemented
- [x] **conio**: print, println, printint, printbool, printchar, readline, eof
- [x] **string**: all 11 functions + string_to_chararray, string_from_chararray
- [x] **parse**: parse_bool, parse_int (base 8/10/16)
- [x] **file**: file_read, file_close, file_eof, file_readline
- [x] **args**: args_flag, args_int, args_string, args_parse

### `#use` directives
- [x] `#use <conio>`, `#use <string>`, `#use <parse>`, `#use <file>`, `#use <args>`
- [x] `#use "filename"` — file inclusion via preprocessor in c0c.scm
- [x] Only link libraries that are actually imported

## Runtime Safety
- [x] NULL-checked pointer dereference (all paths through `c0_deref`)
- [ ] Garbage collection (uses `calloc` with no GC)

## Compiler Features

### Contracts
- [x] `@requires`, `@ensures`, `@assert`, `@loop_invariant`
- [x] `\result` in `@ensures` — saves return value, checks postcondition at return
- [x] `\length(expr)` in contracts — emits `c0_array_length`

### Error handling
- [x] Error messages include line and column numbers
- [x] Source filename in error messages
- [x] Error recovery — continues checking after per-declaration errors

### Not yet implemented
- [ ] Multiple source file compilation (via CLI, not `#use`)
- [ ] Struct equality error message improvement
- [ ] Array element type annotation on AST

## Optimization
- [ ] `-O1`/`-O2`, `-g`, `-S` flags

## Testing
- [x] 30 integration tests
- [x] 53 type checker tests
- [x] 35 lexer tests
- [x] Runtime safety abort tests (NULL, bounds, div-by-zero, mod-by-zero, overflow)
- [x] `--no-check` contract suppression test
- [x] Expected-error test infrastructure
- [x] Cross-compilation emit-c test
- [x] `#use "filename"` file inclusion test
- [x] GitHub Actions CI workflow
- [ ] Cross-compilation binary execution (needs QEMU)
