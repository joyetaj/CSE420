%{
#include <stdio.h>
#include <stdlib.h>
#include "symbol_info.h"
#include "y.tab.h"

int currentLine = 1;
extern FILE *logFile;

void printToken(const char *tokenName, const char *lexeme) {
    fprintf(logFile, "Line %d\tToken <%s>\tLexeme: %s\n", currentLine, tokenName, lexeme);
}

void printLexError(const char *msg, const char *lexeme) {
    fprintf(logFile, "Line %d\tLexical Error: %s (%s)\n", currentLine, msg, lexeme);
}
%}

DIGIT   [0-9]
LETTER  [a-zA-Z_]

INT_LIT   {DIGIT}+
EXP_PART  [eE][+-]?{DIGIT}+
FLOAT_LIT ({DIGIT}+"."{DIGIT}+{EXP_PART}?)|("."{DIGIT}+{EXP_PART}?)|({DIGIT}+{EXP_PART})
BAD_FLOAT {DIGIT}+("."{DIGIT}+){2,}

IDENT     {LETTER}({LETTER}|{DIGIT})*
BAD_IDENT {DIGIT}+{LETTER}({LETTER}|{DIGIT})*

%%

"if"       { yylval = newSymbolInfo(yytext, "IF");    printToken("IF", yytext);    return IF; }
"else"     { yylval = newSymbolInfo(yytext, "ELSE");  printToken("ELSE", yytext);  return ELSE; }
"for"      { yylval = newSymbolInfo(yytext, "FOR");   printToken("FOR", yytext);   return FOR; }
"while"    { yylval = newSymbolInfo(yytext, "WHILE"); printToken("WHILE", yytext); return WHILE; }
"do"       { yylval = newSymbolInfo(yytext, "DO");    printToken("DO", yytext);    return DO; }
"break"    { yylval = newSymbolInfo(yytext, "BREAK"); printToken("BREAK", yytext); return BREAK; }
"int"      { yylval = newSymbolInfo(yytext, "INT");   printToken("INT", yytext);   return INT; }
"char"     { yylval = newSymbolInfo(yytext, "CHAR");  printToken("CHAR", yytext);  return CHAR; }
"float"    { yylval = newSymbolInfo(yytext, "FLOAT"); printToken("FLOAT", yytext); return FLOAT; }
"double"   { yylval = newSymbolInfo(yytext, "DOUBLE");printToken("DOUBLE", yytext);return DOUBLE; }
"continue" { yylval = newSymbolInfo(yytext, "CONTINUE"); printToken("CONTINUE", yytext); return CONTINUE; }
"case"     { yylval = newSymbolInfo(yytext, "CASE");  printToken("CASE", yytext);  return CASE; }
"void"     { yylval = newSymbolInfo(yytext, "VOID");  printToken("VOID", yytext);  return VOID; }
"switch"   { yylval = newSymbolInfo(yytext, "SWITCH");printToken("SWITCH", yytext);return SWITCH; }
"default"  { yylval = newSymbolInfo(yytext, "DEFAULT");printToken("DEFAULT", yytext);return DEFAULT; }
"goto"     { yylval = newSymbolInfo(yytext, "GOTO");  printToken("GOTO", yytext);  return GOTO; }
"return"   { yylval = newSymbolInfo(yytext, "RETURN");printToken("RETURN", yytext);return RETURN; }
"printf"   { yylval = newSymbolInfo(yytext, "PRINTLN");printToken("PRINTLN", yytext);return PRINTLN; }

{BAD_FLOAT}  { printLexError("too many decimal points", yytext); }
{FLOAT_LIT}  { yylval = newSymbolInfo(yytext, "CONST_FLOAT"); printToken("CONST_FLOAT", yytext); return CONST_FLOAT; }
{INT_LIT}    { yylval = newSymbolInfo(yytext, "CONST_INT");   printToken("CONST_INT", yytext);   return CONST_INT; }

"++" { yylval = newSymbolInfo(yytext, "INCOP");    printToken("INCOP", yytext);    return INCOP; }
"--" { yylval = newSymbolInfo(yytext, "DECOP");    printToken("DECOP", yytext);    return DECOP; }
"+"  { yylval = newSymbolInfo(yytext, "ADDOP");    printToken("ADDOP", yytext);    return ADDOP; }
"-"  { yylval = newSymbolInfo(yytext, "ADDOP");    printToken("ADDOP", yytext);    return ADDOP; }
"*"  { yylval = newSymbolInfo(yytext, "MULOP");    printToken("MULOP", yytext);    return MULOP; }
"/"  { yylval = newSymbolInfo(yytext, "MULOP");    printToken("MULOP", yytext);    return MULOP; }
"%"  { yylval = newSymbolInfo(yytext, "MULOP");    printToken("MULOP", yytext);    return MULOP; }
"<=" { yylval = newSymbolInfo(yytext, "RELOP");    printToken("RELOP", yytext);    return RELOP; }
">=" { yylval = newSymbolInfo(yytext, "RELOP");    printToken("RELOP", yytext);    return RELOP; }
"==" { yylval = newSymbolInfo(yytext, "RELOP");    printToken("RELOP", yytext);    return RELOP; }
"!=" { yylval = newSymbolInfo(yytext, "RELOP");    printToken("RELOP", yytext);    return RELOP; }
"<"  { yylval = newSymbolInfo(yytext, "RELOP");    printToken("RELOP", yytext);    return RELOP; }
">"  { yylval = newSymbolInfo(yytext, "RELOP");    printToken("RELOP", yytext);    return RELOP; }
"="  { yylval = newSymbolInfo(yytext, "ASSIGNOP"); printToken("ASSIGNOP", yytext); return ASSIGNOP; }
"&&" { yylval = newSymbolInfo(yytext, "LOGICOP");  printToken("LOGICOP", yytext);  return LOGICOP; }
"||" { yylval = newSymbolInfo(yytext, "LOGICOP");  printToken("LOGICOP", yytext);  return LOGICOP; }
"!"  { yylval = newSymbolInfo(yytext, "NOT");      printToken("NOT", yytext);      return NOT; }
"("  { yylval = newSymbolInfo(yytext, "LPAREN");   printToken("LPAREN", yytext);   return LPAREN; }
")"  { yylval = newSymbolInfo(yytext, "RPAREN");   printToken("RPAREN", yytext);   return RPAREN; }
"{"  { yylval = newSymbolInfo(yytext, "LCURL");    printToken("LCURL", yytext);    return LCURL; }
"}"  { yylval = newSymbolInfo(yytext, "RCURL");    printToken("RCURL", yytext);    return RCURL; }
"["  { yylval = newSymbolInfo(yytext, "LTHIRD");   printToken("LTHIRD", yytext);   return LTHIRD; }
"]"  { yylval = newSymbolInfo(yytext, "RTHIRD");   printToken("RTHIRD", yytext);   return RTHIRD; }
","  { yylval = newSymbolInfo(yytext, "COMMA");    printToken("COMMA", yytext);    return COMMA; }
":"  { yylval = newSymbolInfo(yytext, "COLON");    printToken("COLON", yytext);    return COLON; }
";"  { yylval = newSymbolInfo(yytext, "SEMICOLON");printToken("SEMICOLON", yytext);return SEMICOLON; }

{BAD_IDENT} { printLexError("identifier cannot start with a digit", yytext); }
{IDENT}     { yylval = newSymbolInfo(yytext, "ID"); printToken("ID", yytext); return ID; }

\n        { currentLine++; }
[ \t\r]+  { /* skip whitespace */ }

.  { printLexError("unrecognized character", yytext); }

%%

int yywrap(void) {
    return 1;
}
