#ifndef C0RT_H
#define C0RT_H

#include <stdint.h>
#include <stdbool.h>
#include <stddef.h>
#include <stdio.h>
#include <stdlib.h>
#include <string.h>

typedef const char* c0_string;

typedef struct c0_array {
    int32_t count;
    int32_t elt_size;
    char data[];
} c0_array;

c0_array* c0_alloc_array(int32_t elt_size, int32_t count);
void* c0_array_sub(c0_array* arr, int32_t idx);
int32_t c0_array_length(c0_array* arr);

void* c0_alloc(size_t size);
void* c0_deref(void* ptr);

int32_t c0_idiv(int32_t a, int32_t b);
int32_t c0_imod(int32_t a, int32_t b);
int32_t c0_ishl(int32_t a, int32_t b);
int32_t c0_ishr(int32_t a, int32_t b);

void c0_assert(bool cond, const char* msg);
void c0_abort(const char* msg);

void print(c0_string s);
void println(c0_string s);
void printint(int32_t i);
c0_string readline(void);

int32_t string_length(c0_string s);
char string_charat(c0_string s, int32_t idx);
c0_string string_sub(c0_string s, int32_t start, int32_t end);
c0_string string_join(c0_string a, c0_string b);
int32_t string_compare(c0_string a, c0_string b);
bool string_equal(c0_string a, c0_string b);
c0_string string_fromint(int32_t i);
c0_string string_frombool(bool b);
c0_string string_fromchar(char c);
int32_t char_ord(char c);
char char_chr(int32_t n);

int32_t _c0_main(void);

#endif
