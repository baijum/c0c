#define _POSIX_C_SOURCE 200809L
#include "c0rt.h"

void c0_abort(const char* msg) {
    fprintf(stderr, "c0 runtime error: %s\n", msg);
    abort();
}

void c0_assert(bool cond, const char* msg) {
    if (!cond) c0_abort(msg);
}

void* c0_alloc(size_t size) {
    void* p = calloc(1, size);
    if (!p) c0_abort("out of memory");
    return p;
}

void* c0_deref(void* ptr) {
    if (!ptr) c0_abort("NULL pointer dereference");
    return ptr;
}

c0_array* c0_alloc_array(int32_t elt_size, int32_t count) {
    if (count < 0) c0_abort("negative array size");
    c0_array* arr = calloc(1, sizeof(c0_array) + (size_t)count * (size_t)elt_size);
    if (!arr) c0_abort("out of memory");
    arr->count = count;
    arr->elt_size = elt_size;
    return arr;
}

void* c0_array_sub(c0_array* arr, int32_t idx) {
    if (!arr) c0_abort("NULL array");
    if (idx < 0 || idx >= arr->count) {
        fprintf(stderr, "c0 runtime error: array index %d out of bounds (size %d)\n",
                idx, arr->count);
        abort();
    }
    return arr->data + (size_t)idx * (size_t)arr->elt_size;
}

int32_t c0_array_length(c0_array* arr) {
    if (!arr) c0_abort("NULL array");
    return arr->count;
}

int32_t c0_idiv(int32_t a, int32_t b) {
    if (b == 0) c0_abort("division by zero");
    if (a == INT32_MIN && b == -1) c0_abort("integer overflow in division");
    return a / b;
}

int32_t c0_imod(int32_t a, int32_t b) {
    if (b == 0) c0_abort("modulo by zero");
    if (a == INT32_MIN && b == -1) c0_abort("integer overflow in modulo");
    return a % b;
}

int32_t c0_ishl(int32_t a, int32_t b) {
    int32_t shift = b & 0x1F;
    return (int32_t)((uint32_t)a << shift);
}

int32_t c0_ishr(int32_t a, int32_t b) {
    int32_t shift = b & 0x1F;
    return a >> shift;
}

void print(c0_string s) {
    if (!s) c0_abort("NULL string in print");
    fputs(s, stdout);
}

void println(c0_string s) {
    if (!s) c0_abort("NULL string in println");
    puts(s);
}

void printint(int32_t i) {
    printf("%d", i);
}

void printbool(bool b) {
    fputs(b ? "true" : "false", stdout);
}

void printchar(char c) {
    putchar(c);
}

bool eof(void) {
    return feof(stdin) != 0;
}

c0_string readline(void) {
    char buf[1024];
    if (!fgets(buf, sizeof(buf), stdin)) return "";
    size_t len = strlen(buf);
    if (len > 0 && buf[len - 1] == '\n') buf[--len] = '\0';
    if (len > 0 && buf[len - 1] == '\r') buf[--len] = '\0';
    char* s = malloc(len + 1);
    if (!s) c0_abort("out of memory");
    memcpy(s, buf, len + 1);
    return s;
}

int32_t string_length(c0_string s) {
    if (!s) c0_abort("NULL string");
    return (int32_t)strlen(s);
}

char string_charat(c0_string s, int32_t idx) {
    if (!s) c0_abort("NULL string");
    int32_t len = (int32_t)strlen(s);
    if (idx < 0 || idx >= len) c0_abort("string index out of bounds");
    return s[idx];
}

c0_string string_sub(c0_string s, int32_t start, int32_t end) {
    if (!s) c0_abort("NULL string");
    int32_t len = (int32_t)strlen(s);
    if (start < 0 || end < start || end > len) c0_abort("invalid substring range");
    int32_t sublen = end - start;
    char* r = malloc((size_t)sublen + 1);
    if (!r) c0_abort("out of memory");
    memcpy(r, s + start, (size_t)sublen);
    r[sublen] = '\0';
    return r;
}

c0_string string_join(c0_string a, c0_string b) {
    if (!a) c0_abort("NULL string");
    if (!b) c0_abort("NULL string");
    size_t la = strlen(a), lb = strlen(b);
    char* r = malloc(la + lb + 1);
    if (!r) c0_abort("out of memory");
    memcpy(r, a, la);
    memcpy(r + la, b, lb + 1);
    return r;
}

int32_t string_compare(c0_string a, c0_string b) {
    if (!a || !b) c0_abort("NULL string");
    return strcmp(a, b);
}

bool string_equal(c0_string a, c0_string b) {
    if (!a || !b) c0_abort("NULL string");
    return strcmp(a, b) == 0;
}

c0_string string_fromint(int32_t i) {
    char buf[16];
    snprintf(buf, sizeof(buf), "%d", i);
    return strdup(buf);
}

c0_string string_frombool(bool b) {
    return b ? "true" : "false";
}

c0_string string_fromchar(char c) {
    char* s = malloc(2);
    if (!s) c0_abort("out of memory");
    s[0] = c;
    s[1] = '\0';
    return s;
}

int32_t char_ord(char c) { return (int32_t)(unsigned char)c; }
char char_chr(int32_t n) {
    if (n < 0 || n > 127) c0_abort("char_chr: out of ASCII range");
    return (char)n;
}

static int c0_argc = 0;
static char** c0_argv = NULL;

struct c0_arg_reg { char type; c0_string name; void* ptr; };
static struct c0_arg_reg c0_args[64];
static int c0_nargs = 0;

void args_flag(c0_string name, bool* ptr) {
    if (c0_nargs >= 64) c0_abort("too many registered args");
    c0_args[c0_nargs++] = (struct c0_arg_reg){ 'b', name, ptr };
}

void args_int(c0_string name, int32_t* ptr) {
    if (c0_nargs >= 64) c0_abort("too many registered args");
    c0_args[c0_nargs++] = (struct c0_arg_reg){ 'i', name, ptr };
}

void args_string(c0_string name, c0_string* ptr) {
    if (c0_nargs >= 64) c0_abort("too many registered args");
    c0_args[c0_nargs++] = (struct c0_arg_reg){ 's', name, ptr };
}

c0_array* args_parse(void) {
    int pos_count = 0;
    c0_string* pos_args = malloc(sizeof(c0_string) * (size_t)(c0_argc + 1));
    if (!pos_args) c0_abort("out of memory");
    for (int i = 1; i < c0_argc; i++) {
        char* arg = c0_argv[i];
        if (arg[0] == '-') {
            char* name = arg + 1;
            int found = 0;
            for (int j = 0; j < c0_nargs; j++) {
                if (strcmp(c0_args[j].name, name) == 0) {
                    found = 1;
                    if (c0_args[j].type == 'b') {
                        *(bool*)c0_args[j].ptr = true;
                    } else if (i + 1 < c0_argc) {
                        i++;
                        if (c0_args[j].type == 'i') {
                            *(int32_t*)c0_args[j].ptr = (int32_t)strtol(c0_argv[i], NULL, 10);
                        } else {
                            *(c0_string*)c0_args[j].ptr = c0_argv[i];
                        }
                    }
                    break;
                }
            }
            if (!found) pos_args[pos_count++] = arg;
        } else {
            pos_args[pos_count++] = arg;
        }
    }
    c0_array* arr = c0_alloc_array(sizeof(c0_string), pos_count);
    for (int i = 0; i < pos_count; i++)
        *(c0_string*)(arr->data + (size_t)i * sizeof(c0_string)) = pos_args[i];
    free(pos_args);
    c0_nargs = 0;
    return arr;
}

struct c0_file { FILE* fp; };

file_t file_read(c0_string path) {
    if (!path) c0_abort("NULL string in file_read");
    FILE* fp = fopen(path, "r");
    if (!fp) c0_abort("file_read: cannot open file");
    file_t f = malloc(sizeof(struct c0_file));
    if (!f) c0_abort("out of memory");
    f->fp = fp;
    return f;
}

void file_close(file_t f) {
    if (!f) c0_abort("NULL file in file_close");
    fclose(f->fp);
    f->fp = NULL;
}

bool file_eof(file_t f) {
    if (!f) c0_abort("NULL file in file_eof");
    return feof(f->fp) != 0;
}

c0_string file_readline(file_t f) {
    if (!f) c0_abort("NULL file in file_readline");
    char buf[1024];
    if (!fgets(buf, sizeof(buf), f->fp)) return "";
    size_t len = strlen(buf);
    if (len > 0 && buf[len - 1] == '\n') buf[--len] = '\0';
    if (len > 0 && buf[len - 1] == '\r') buf[--len] = '\0';
    char* s = malloc(len + 1);
    if (!s) c0_abort("out of memory");
    memcpy(s, buf, len + 1);
    return s;
}

c0_array* string_to_chararray(c0_string s) {
    if (!s) c0_abort("NULL string in string_to_chararray");
    int32_t len = (int32_t)strlen(s);
    c0_array* arr = c0_alloc_array(sizeof(char), len);
    memcpy(arr->data, s, (size_t)len);
    return arr;
}

c0_string string_from_chararray(c0_array* a) {
    if (!a) c0_abort("NULL array in string_from_chararray");
    char* s = malloc((size_t)a->count + 1);
    if (!s) c0_abort("out of memory");
    memcpy(s, a->data, (size_t)a->count);
    s[a->count] = '\0';
    return s;
}

struct parsed_bool* parse_bool(c0_string s) {
    if (!s) c0_abort("NULL string in parse_bool");
    if (strcmp(s, "true") != 0 && strcmp(s, "false") != 0) return NULL;
    struct parsed_bool* p = malloc(sizeof(struct parsed_bool));
    if (!p) c0_abort("out of memory");
    p->result = (strcmp(s, "true") == 0);
    return p;
}

struct parsed_int* parse_int(c0_string s, int32_t base) {
    if (!s) c0_abort("NULL string in parse_int");
    if (base != 8 && base != 10 && base != 16) return NULL;
    if (*s == '\0') return NULL;
    char* endptr;
    long val = strtol(s, &endptr, base);
    if (*endptr != '\0') return NULL;
    if (val < INT32_MIN || val > INT32_MAX) return NULL;
    struct parsed_int* p = malloc(sizeof(struct parsed_int));
    if (!p) c0_abort("out of memory");
    p->result = (int32_t)val;
    return p;
}

int main(int argc, char** argv) {
    c0_argc = argc;
    c0_argv = argv;
    return _c0_main();
}
