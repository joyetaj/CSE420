#!/bin/bash
# script.sh - CSE420 Lab 1
# Student ID: 22201080

set -e

echo "Generating parser from grammar..."
bison -d -y 22201080.y

echo "Generating scanner..."
flex 22201080.l

echo "Compiling..."
gcc lex.yy.c y.tab.c -o parser -lfl

echo "Running parser on input.txt..."
./parser input.txt

echo "Done. See 22201080_log.txt for output."
