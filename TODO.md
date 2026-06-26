# c0c TODO

## Standard Libraries

### file library
- [x] Runtime: `file_read`, `file_close`, `file_eof`, `file_readline` implemented in c0rt.c
- [ ] Compiler: register `file_t` opaque type and function signatures
- Blocked: kaappi VM bytecode size limit prevents adding registration code to checker.sld

### args library
- [ ] `void args_flag(string name, bool *ptr)` — register boolean flag
- [ ] `void args_int(string name, int *ptr)` — register int switch
- [ ] `void args_string(string name, string *ptr)` — register string switch
- [ ] `string[] args_parse()` — parse command-line arguments
- Requires pointer-to-pointer support in the type checker

### parse library
- [x] `struct parsed_bool *parse_bool(string s)` — parse "true"/"false"
- [x] `struct parsed_int *parse_int(string s, int base)` — parse integer (base 8/10/16)
- Done: structs + functions in c0rt.c, signatures in stdlib.sld, checker registers structs

### string library
- [x] `string_to_chararray` and `string_from_chararray` — runtime + compiler registration
- Done: implemented in c0rt.c, signatures registered via checker hook

### conio library
- [x] `printbool`, `printchar`, `eof` — runtime implementation in c0rt.c/h

### `#use` directives
- [x] Parse `#use <conio>`, `#use <string>`, `#use <parse>`
- [x] Only link libraries that are actually imported
- [ ] `#use "filename"` — file inclusion (blocked by VM bytecode limit)

## Runtime Safety

### NULL-checked pointer dereference
- [x] All pointer dereferences and arrow accesses route through `c0_deref`

### Garbage collection
- [ ] Integrate Boehm GC or implement mark-and-sweep in c0rt.c
- Currently uses `calloc` with no collection

## Compiler Features

### `\result` in `@ensures`
- [x] Lexer: `\result` tokenized as `bs-result`
- [x] Parser: produces `e-result` AST node
- [x] Checker: returns current function return type
- [x] Codegen: saves return value to `_c0_result`, checks ensures, then returns

### `\length(e)` in contracts
- [x] Lexer: `\length` tokenized as `bs-length`
- [x] Parser: produces `e-length` AST node with expression argument
- [x] Checker: validates argument, returns int type
- [x] Codegen: emits `c0_array_length(expr)`

### Error recovery
- [ ] Continue parsing after first error to report multiple errors
- [ ] Synchronize at statement boundaries

### Error messages
- [ ] Include source filename in error messages
- [ ] Show source line with caret at error column

### Multiple source files
- [ ] Accept multiple `.c0` files on the command line

### Struct equality and copy
- [ ] More specific error message for struct `==`/`=` attempts

### Array element type in codegen
- [ ] Annotate AST with resolved types (currently infers from var-types hash)

## Optimization

- [ ] `-O1`/`-O2` for optimized builds
- [ ] `-g` for debug info
- [ ] `-S` to emit assembly

## Testing

### Test coverage
- [x] NULL dereference, array out-of-bounds, division by zero, INT32_MIN / -1
- [x] Modulo by zero abort
- [x] `--no-check` suppresses contract assertions
- [x] Expected-error tests (compile should fail with specific error)
- [ ] Test cross-compilation (needs QEMU or Docker)

### Test infrastructure
- [x] Runtime-abort tests
- [x] Expected-error tests (`run_error_test` in run-tests.sh)
- [x] CI workflow (`.github/workflows/ci.yml`)
