# c0c TODO

## Standard Libraries

### file library
- [x] Runtime: `file_read`, `file_close`, `file_eof`, `file_readline` implemented in c0rt.c
- [ ] Compiler: register `file_t` opaque type and function signatures
- Blocked: kaappi VM bytecode size limit prevents adding more code to checker.sld

### args library
- [ ] `void args_flag(string name, bool *ptr)` — register boolean flag
- [ ] `void args_int(string name, int *ptr)` — register int switch
- [ ] `void args_string(string name, string *ptr)` — register string switch
- [ ] `string[] args_parse()` — parse command-line arguments
- Requires pointer-to-pointer support in the type checker

### parse library
- [x] `struct parsed_bool *parse_bool(string s)` — parse "true"/"false"
- [x] `struct parsed_int *parse_int(string s, int base)` — parse integer (base 8/10/16)
- Done: `parsed_bool`/`parsed_int` structs + functions in c0rt.h/c0rt.c, signatures in stdlib.sld, checker registers structs for `#use <parse>`

### string library (missing functions)
- [x] Runtime: `string_to_chararray` and `string_from_chararray` implemented in c0rt.c
- [ ] Compiler: register signatures in checker for `#use <string>`
- Blocked: kaappi VM bytecode size limit prevents adding more code to checker.sld

### conio library (missing runtime)
- [x] `printbool`, `printchar`, `eof` implemented in c0rt.c/c0rt.h

### `#use` directives
- [x] Parse `#use <conio>`, `#use <string>`, `#use <file>`, `#use <args>`, `#use <parse>`
- [x] Only link libraries that are actually imported
- [ ] `#use "filename"` — file inclusion (not yet implemented)
- Done: lexer tokenizes `#use <lib>`, parser produces `g-use` AST nodes (enforced before declarations), checker conditionally registers library functions

## Runtime Safety

### NULL-checked pointer dereference
- [x] Codegen: emit `*((T*)c0_deref(p))` instead of `(*(p))` for pointer reads
- [x] Codegen: emit `*((T*)c0_deref(p)) = expr` for pointer writes
- [x] Codegen: emit `((T*)c0_deref(p))->field` for struct field access
- Done: all pointer dereferences and arrow accesses now route through `c0_deref`

### Garbage collection
- [ ] Integrate Boehm GC (`GC_malloc` instead of `calloc`)
- [ ] Alternatively, implement a simple mark-and-sweep in c0rt.c
- Currently uses `calloc` with no collection — long-running programs leak

## Compiler Features

### `\result` in `@ensures`
- [ ] Parse `\result` as a special variable in `@ensures` annotations
- [ ] Bind it to the function's return value in generated C
- Blocked: kaappi VM bytecode size limit prevents adding lexer/parser/checker/codegen code

### `\length(e)` in contracts
- [ ] Parse `\length(expr)` in contract annotations
- [ ] Emit `c0_array_length(expr)` in generated C
- Blocked: kaappi VM bytecode size limit

### Error recovery
- [ ] Continue parsing after first error to report multiple errors
- [ ] Synchronize at statement boundaries (skip to next `;` or `}`)
- Currently aborts on first error

### Error messages
- [ ] Include source filename in error messages
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
- [x] Test runtime safety: NULL dereference abort message
- [x] Test runtime safety: array out-of-bounds abort message
- [x] Test runtime safety: division by zero abort message
- [x] Test runtime safety: INT32_MIN / -1 abort message
- [x] Test runtime safety: modulo by zero abort message
- [x] Test `--no-check` suppresses contract assertions
- [ ] Test cross-compilation produces working binaries (needs QEMU or Docker)
- [ ] Test error messages for all type checker rejections

### Test infrastructure
- [ ] Add expected-error tests (compile should fail with specific message)
- [x] Add runtime-abort tests (compiled binary should abort with specific message)
- [ ] CI workflow (GitHub Actions)

## Kaappi VM Limitations

Several features are implemented in the runtime (c0rt.c/c0rt.h) but cannot be
registered in the compiler (checker.sld/stdlib.sld) because the kaappi VM has a
hard limit on combined bytecode size across all `.sld` library files (~1937 lines
total). Adding more code to any `.sld` file causes the VM to fail to bind library
exports. Features blocked by this limit are marked above.
