# c0c TODO

## Standard Libraries

### file library
- [ ] `file_t file_read(string path)` — open file for reading
- [ ] `void file_close(file_t f)` — close file handle
- [ ] `bool file_eof(file_t f)` — check end-of-file
- [ ] `string file_readline(file_t f)` — read line from file
- Requires adding `file_t` as an opaque type (pointer to runtime struct)
- Runtime: implement in c0rt.c using `fopen`/`fclose`/`fgets`

### args library
- [ ] `void args_flag(string name, bool *ptr)` — register boolean flag
- [ ] `void args_int(string name, int *ptr)` — register int switch
- [ ] `void args_string(string name, string *ptr)` — register string switch
- [ ] `string[] args_parse()` — parse command-line arguments
- Requires pointer-to-pointer support in the type checker

### parse library
- [ ] `struct parsed_bool *parse_bool(string s)` — parse "true"/"false"
- [ ] `struct parsed_int *parse_int(string s, int base)` — parse integer (base 8/10/16)
- Runtime: implement `parsed_bool` and `parsed_int` structs in c0rt.h

### string library (missing functions)
- [ ] `c0_array* string_to_chararray(c0_string s)` — convert string to char[]
- [ ] `c0_string string_from_chararray(c0_array* a)` — convert char[] to string

### `#use` directives
- [ ] Parse `#use <conio>`, `#use <string>`, `#use <file>`, `#use <args>`, `#use <parse>`
- [ ] Only link libraries that are actually imported
- Currently all conio and string functions are always available

## Runtime Safety

### NULL-checked pointer dereference
- [ ] Codegen: emit `*((T*)c0_deref(p))` instead of `(*(p))` for pointer reads
- [ ] Codegen: emit `*((T*)c0_deref(p)) = expr` for pointer writes
- [ ] Codegen: emit `((T*)c0_deref(p))->field` for struct field access
- Currently raw dereference segfaults on NULL instead of printing a clean error

### Garbage collection
- [ ] Integrate Boehm GC (`GC_malloc` instead of `calloc`)
- [ ] Alternatively, implement a simple mark-and-sweep in c0rt.c
- Currently uses `calloc` with no collection — long-running programs leak

## Compiler Features

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

### `\result` in `@ensures`
- [ ] Parse `\result` as a special variable in `@ensures` annotations
- [ ] Bind it to the function's return value in generated C
- Requires codegen to emit a temporary for the return value

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
- [ ] Test runtime safety: NULL dereference abort message
- [ ] Test runtime safety: array out-of-bounds abort message
- [ ] Test runtime safety: division by zero abort message
- [ ] Test runtime safety: INT32_MIN / -1 abort message
- [ ] Test `--no-check` suppresses contract assertions
- [ ] Test cross-compilation produces working binaries (needs QEMU or Docker)
- [ ] Test error messages for all type checker rejections

### Test infrastructure
- [ ] Add expected-error tests (compile should fail with specific message)
- [ ] Add runtime-abort tests (compiled binary should abort with specific message)
- [ ] CI workflow (GitHub Actions)
