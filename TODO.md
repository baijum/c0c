# c0c TODO — All Major Features Complete

## Standard Libraries — All Implemented
- [x] **conio**: print, println, printint, printbool, printchar, readline, eof
- [x] **string**: all 13 functions including chararray conversion
- [x] **parse**: parse_bool, parse_int
- [x] **file**: file_read, file_close, file_eof, file_readline
- [x] **args**: args_flag, args_int, args_string, args_parse

## Directives
- [x] `#use <lib>` for all 5 libraries
- [x] `#use "filename"` file inclusion

## Runtime Safety
- [x] NULL-checked pointer dereference
- [x] Garbage collection via Boehm GC (`--gc` flag)

## Contracts
- [x] `@requires`, `@ensures`, `@assert`, `@loop_invariant`
- [x] `\result`, `\length(e)`, `\old(e)`

## Error Handling
- [x] Source filename, line, column in errors
- [x] Source line display with caret at error column
- [x] Error recovery across declarations
- [x] Errors vs warnings (`check-error` vs `check-warn`)
- [x] Specific struct equality error message

## Compilation
- [x] Multiple source files on CLI
- [x] Forward declarations emitted for all functions
- [x] `-O0`/`-O1`/`-O2`/`-Oz`, `-g`, `-S`
- [x] Auto-strip symbols for optimized non-debug builds
- [x] Cross-compilation with `--target`
- [x] `--gc` for Boehm GC garbage collection

## Testing
- [x] 33 integration, 70 checker, 35 lexer = 138 total
- [x] Cross-compilation binary format test (ELF 64-bit)
- [x] Expected-error, --no-check, multi-file tests
- [x] CI workflow

## Future Improvements
- [ ] Array element type annotation on AST (fixes `f()[i]` codegen edge case)
- [ ] `\old(e)` type inference for non-variable expressions
- [ ] GC_INIT() call in main for full Boehm GC compliance
