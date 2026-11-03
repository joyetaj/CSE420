#!/bin/bash
# Build and run script for the CSE420 Intermediate Code Generation assignment
# Usage: ./script.sh <input_file.c>

if [ -z "$1" ]; then
    echo "Usage: $0 <input_file.c>"
    exit 1
fi

INPUT_FILE=$1
STUDENT_ID=22201080

echo "Generating parser from ${STUDENT_ID}.y ..."
bison -d -o y.tab.c ${STUDENT_ID}.y

echo "Generating lexer from ${STUDENT_ID}.l ..."
flex -o lex.yy.c ${STUDENT_ID}.l

echo "Compiling ..."
g++ -std=c++17 -w -o compiler y.tab.c lex.yy.c -lfl

if [ $? -ne 0 ]; then
    echo "Compilation failed."
    exit 1
fi

echo "Running compiler on ${INPUT_FILE} ..."
./compiler "${INPUT_FILE}"

echo "Done. See log.txt, error.txt and code.txt for output."
