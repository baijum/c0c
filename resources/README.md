# Resources

Reference documents for the C0 language that this compiler targets.

| File | Title | Authors | Year |
|------|-------|---------|------|
| `c0-language-thesis.pdf` | C0, an Imperative Programming Language for Novice Computer Scientists | Rob Arnold | 2010 |
| `c0-language-reference.pdf` | C0 Reference (15-122: Principles of Imperative Computation) | Frank Pfenning | 2011 |
| `concurrent-c0-design.pdf` | Design and Implementation of Concurrent C0 | Max Willsey, Rokhini Prabhu, Frank Pfenning | 2016 |

## c0-language-thesis.pdf

CMU Master's thesis (CMU-CS-10-145) defining the C0 language. Covers the full
language specification including types, expressions, statements, contracts, memory
model, and standard libraries. This is the primary reference for the c0c compiler.

## c0-language-reference.pdf

Concise language reference card from CMU's 15-122 course. Covers types (int, bool,
char, string, arrays, pointers, structs), contracts, functions, and commands. Useful
as a quick lookup for syntax and semantics.

## concurrent-c0-design.pdf

Paper on Concurrent C0 (CC0), an extension of C0 with session-typed message passing
for concurrent programming. Describes spawning processes, channel communication,
and session types. Not directly implemented by c0c but useful background on the C0
ecosystem.
