%{
#include <bits/stdc++.h>
#include "symbol_info.h"
#include "ast.h"
#include "symbol_table.h"
#include "y.tab.h"
using namespace std;

extern FILE* logOut;
extern FILE* errOut;
extern int error_count;
int line_count = 1;

void unknown_token(const char* text) {
    fprintf(errOut, "Line# %d: Unrecognized character %s\n", line_count, text);
    error_count++;
}
%}

%option noyywrap

DIGIT   [0-9]
LETTER  [a-zA-Z_]
ID      {LETTER}({LETTER}|{DIGIT})*
WS      [ \t]+

%%

"//".*                     { /* single line comment: ignore */ }
"/*"([^*]|\*+[^*/])*\*+"/" {
                              for (int i = 0; yytext[i]; i++) if (yytext[i] == '\n') line_count++;
                            }

"if"                        { yylval.symbol = new SymbolInfo(yytext, "IF"); return IF; }
"else"                       { yylval.symbol = new SymbolInfo(yytext, "ELSE"); return ELSE; }
"for"                        { yylval.symbol = new SymbolInfo(yytext, "FOR"); return FOR; }
"while"                      { yylval.symbol = new SymbolInfo(yytext, "WHILE"); return WHILE; }
"return"                     { yylval.symbol = new SymbolInfo(yytext, "RETURN"); return RETURN; }
"int"                        { yylval.symbol = new SymbolInfo(yytext, "INT"); return INT; }
"float"                      { yylval.symbol = new SymbolInfo(yytext, "FLOAT"); return FLOAT; }
"void"                       { yylval.symbol = new SymbolInfo(yytext, "VOID"); return VOID; }

{DIGIT}+"."{DIGIT}+          { yylval.symbol = new SymbolInfo(yytext, "CONST_FLOAT"); return CONST_FLOAT; }
{DIGIT}+                     { yylval.symbol = new SymbolInfo(yytext, "CONST_INT"); return CONST_INT; }

{ID}                         { yylval.symbol = new SymbolInfo(yytext, "ID"); return ID; }

"++"                         { yylval.symbol = new SymbolInfo(yytext, "INCOP"); return INCOP; }
"--"                         { yylval.symbol = new SymbolInfo(yytext, "DECOP"); return DECOP; }

"+"|"-"                      { yylval.symbol = new SymbolInfo(yytext, "ADDOP"); return ADDOP; }
"*"|"/"|"%"                  { yylval.symbol = new SymbolInfo(yytext, "MULOP"); return MULOP; }

"<"|">"|"<="|">="|"=="|"!="  { yylval.symbol = new SymbolInfo(yytext, "RELOP"); return RELOP; }
"&&"|"||"                    { yylval.symbol = new SymbolInfo(yytext, "LOGICOP"); return LOGICOP; }
"!"                          { yylval.symbol = new SymbolInfo(yytext, "NOT"); return NOT; }
"="                          { yylval.symbol = new SymbolInfo(yytext, "ASSIGNOP"); return ASSIGNOP; }

"("                          { yylval.symbol = new SymbolInfo(yytext, "LPAREN"); return LPAREN; }
")"                          { yylval.symbol = new SymbolInfo(yytext, "RPAREN"); return RPAREN; }
"{"                          { yylval.symbol = new SymbolInfo(yytext, "LCURL"); return LCURL; }
"}"                          { yylval.symbol = new SymbolInfo(yytext, "RCURL"); return RCURL; }
"["                          { yylval.symbol = new SymbolInfo(yytext, "LTHIRD"); return LTHIRD; }
"]"                          { yylval.symbol = new SymbolInfo(yytext, "RTHIRD"); return RTHIRD; }
","                          { yylval.symbol = new SymbolInfo(yytext, "COMMA"); return COMMA; }
";"                          { yylval.symbol = new SymbolInfo(yytext, "SEMICOLON"); return SEMICOLON; }

\n                           { line_count++; }
{WS}                         { /* ignore whitespace */ }
\r                           { /* ignore carriage return */ }

.                            { unknown_token(yytext); }

%%
