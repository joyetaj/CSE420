#!/bin/bash

yacc -d -y --debug --verbose 22201080.y
echo 'Generated the parser C file as well the header file'
g++ -w -c -o y.o y.tab.c
echo 'Generated the parser object file'
flex 22201080.l
echo 'Generated the scanner C file'
g++ -fpermissive -w -c -o l.o lex.yy.c
# if the above command doesn't work try g++ -fpermissive -w -c -o l.o lex.yy.c
echo 'Generated the scanner object file'
g++ y.o l.o
echo 'All ready, running'
./a.exe input.c
echo ''
echo '======================================'
echo '          LOG FILE OUTPUT'
echo '======================================'
cat 22201080_log.txt

echo ''
echo ''
echo '======================================'
echo '         ERROR FILE OUTPUT'
echo '======================================'
cat 22201080_error.txt
