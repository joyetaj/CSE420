#!/bin/bash

bison -d -y 22201080.y
echo 'Generated the parser C file as well as the header file'
flex 22201080.l
echo 'Generated the scanner C file'
g++ -w -o parser y.tab.c lex.yy.c -lfl
echo 'All ready, running'

INPUT_FILE="${1:-input.c}"
./parser "$INPUT_FILE"

echo 'logfile'
cat 22201080_log.txt
