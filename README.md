# CSE420: Compiler Design

Student ID: **22201080**

Coursework for CSE420 (Compiler Design). Each assignment extends a compiler front end for a C-like subset, built with Flex and Bison.

## Structure

| Assignment | Focus | Folder |
|---|---|---|
| 1 | Lexical analysis and parsing with Flex/Bison | [`Assignment 1/22201080`](Assignment%201/22201080) |
| 2 | Symbol table and scope table | [`Assignment 2/22201080`](Assignment%202/22201080) |
| 3 | Semantic analysis with error reporting | [`Assignment 3/22201080`](Assignment%203/22201080) |
| 4 | Intermediate code generation (three-address code, AST) | [`Assignment 4/22201080`](Assignment%204/22201080) |

## Build and run

Requires `flex`, `bison` (or `yacc`) and `g++`. From inside an assignment folder:

```bash
chmod +x script.sh
./script.sh            # Assignments 1-3
./script.sh input.c    # Assignment 4 takes the input file as an argument
```

Output is written to `22201080_log.txt` (and `22201080_error.txt` where applicable). Generated files are git-ignored.
