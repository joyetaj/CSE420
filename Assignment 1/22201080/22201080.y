/* CSE420 Lab 1 - Parser
 * Student ID: 22201080
 *
 * Grammar rules follow Lab1_C_Syntax_Analyzer_Grammar.pdf.
 * Every action rebuilds the matched source text by joining the
 * children's ->name text (SymbolInfo) with a space - it never
 * hardcodes anything from a particular input file.
 */

%code requires {
#include "symbol_info.h"
#define YYSTYPE SymbolInfo*
}

%{
#include <stdio.h>
#include <stdlib.h>
#include "symbol_info.h"

int yylex(void);
int yyparse(void);
void yyerror(const char *msg);

extern FILE *yyin;
extern int currentLine;

FILE *logFile;

void printRule(const char *production, SymbolInfo *sym) {
    fprintf(logFile, "Line %d: %s\n", currentLine, production);
    fprintf(logFile, "%s\n\n", sym->name);
}
%}

%token IF ELSE FOR WHILE DO VOID SWITCH DEFAULT GOTO RETURN
%token BREAK INT CHAR FLOAT DOUBLE CONTINUE CASE PRINTLN
%token ID CONST_INT CONST_FLOAT
%token ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT
%token LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD
%token COMMA COLON SEMICOLON

%nonassoc IFX
%nonassoc ELSE
%right UMINUS

%%

start : program
      {
          $$ = $1;
          printRule("start : program", $$);
      }
      ;

program : program unit
        {
            $$ = newSymbolInfof("program", "%s %s", $1->name, $2->name);
            printRule("program : program unit", $$);
        }
        | unit
        {
            $$ = newSymbolInfof("program", "%s", $1->name);
            printRule("program : unit", $$);
        }
        ;

unit : variable_decl
     {
         $$ = $1;
         printRule("unit : variable_decl", $$);
     }
     | func_definition
     {
         $$ = $1;
         printRule("unit : func_definition", $$);
     }
     ;

func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement
                 {
                     $$ = newSymbolInfof("func_definition", "%s %s %s %s %s %s",
                                         $1->name, $2->name, $3->name, $4->name, $5->name, $6->name);
                     printRule("func_definition : type_specifier ID LPAREN param_list RPAREN compound_statement", $$);
                 }
                 | type_specifier ID LPAREN RPAREN compound_statement
                 {
                     $$ = newSymbolInfof("func_definition", "%s %s %s %s %s",
                                         $1->name, $2->name, $3->name, $4->name, $5->name);
                     printRule("func_definition : type_specifier ID LPAREN RPAREN compound_statement", $$);
                 }
                 ;

param_list : param_list COMMA type_specifier ID
           {
               $$ = newSymbolInfof("param_list", "%s%s %s %s", $1->name, $2->name, $3->name, $4->name);
               printRule("param_list : param_list COMMA type_specifier ID", $$);
           }
           | param_list COMMA type_specifier
           {
               $$ = newSymbolInfof("param_list", "%s%s %s", $1->name, $2->name, $3->name);
               printRule("param_list : param_list COMMA type_specifier", $$);
           }
           | type_specifier ID
           {
               $$ = newSymbolInfof("param_list", "%s %s", $1->name, $2->name);
               printRule("param_list : type_specifier ID", $$);
           }
           | type_specifier
           {
               $$ = newSymbolInfof("param_list", "%s", $1->name);
               printRule("param_list : type_specifier", $$);
           }
           ;

compound_statement : LCURL statements RCURL
                    {
                        $$ = newSymbolInfof("compound_statement", "%s%s%s", $1->name, $2->name, $3->name);
                        printRule("compound_statement : LCURL statements RCURL", $$);
                    }
                    | LCURL RCURL
                    {
                        $$ = newSymbolInfof("compound_statement", "%s%s", $1->name, $2->name);
                        printRule("compound_statement : LCURL RCURL", $$);
                    }
                    ;

variable_decl : type_specifier declaration_list SEMICOLON
              {
                  $$ = newSymbolInfof("variable_decl", "%s %s%s", $1->name, $2->name, $3->name);
                  printRule("variable_decl : type_specifier declaration_list SEMICOLON", $$);
              }
              ;

type_specifier : INT
                {
                    $$ = $1;
                    printRule("type_specifier : INT", $$);
                }
                | FLOAT
                {
                    $$ = $1;
                    printRule("type_specifier : FLOAT", $$);
                }
                | VOID
                {
                    $$ = $1;
                    printRule("type_specifier : VOID", $$);
                }
                | CHAR
                {
                    $$ = $1;
                    printRule("type_specifier : CHAR", $$);
                }
                ;

declaration_list : declaration_list COMMA ID
                  {
                      $$ = newSymbolInfof("declaration_list", "%s%s%s", $1->name, $2->name, $3->name);
                      printRule("declaration_list : declaration_list COMMA ID", $$);
                  }
                  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
                  {
                      $$ = newSymbolInfof("declaration_list", "%s%s%s%s%s%s",
                                          $1->name, $2->name, $3->name, $4->name, $5->name, $6->name);
                      printRule("declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$);
                  }
                  | ID
                  {
                      $$ = $1;
                      printRule("declaration_list : ID", $$);
                  }
                  | ID LTHIRD CONST_INT RTHIRD
                  {
                      $$ = newSymbolInfof("declaration_list", "%s%s%s%s", $1->name, $2->name, $3->name, $4->name);
                      printRule("declaration_list : ID LTHIRD CONST_INT RTHIRD", $$);
                  }
                  ;

statements : statement
           {
               $$ = $1;
               printRule("statements : statement", $$);
           }
           | statements statement
           {
               $$ = newSymbolInfof("statements", "%s%s", $1->name, $2->name);
               printRule("statements : statements statement", $$);
           }
           ;

statement : variable_decl
          {
              $$ = $1;
              printRule("statement : variable_decl", $$);
          }
          | expression_statement
          {
              $$ = $1;
              printRule("statement : expression_statement", $$);
          }
          | compound_statement
          {
              $$ = $1;
              printRule("statement : compound_statement", $$);
          }
          | FOR LPAREN expression_statement expression_statement expression RPAREN statement
          {
              $$ = newSymbolInfof("statement", "%s%s%s%s%s%s%s",
                                  $1->name, $2->name, $3->name, $4->name, $5->name, $6->name, $7->name);
              printRule("statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement", $$);
          }
          | IF LPAREN expression RPAREN statement %prec IFX
          {
              $$ = newSymbolInfof("statement", "%s%s%s%s%s", $1->name, $2->name, $3->name, $4->name, $5->name);
              printRule("statement : IF LPAREN expression RPAREN statement", $$);
          }
          | IF LPAREN expression RPAREN statement ELSE statement
          {
              $$ = newSymbolInfof("statement", "%s%s%s%s%s%s%s",
                                  $1->name, $2->name, $3->name, $4->name, $5->name, $6->name, $7->name);
              printRule("statement : IF LPAREN expression RPAREN statement ELSE statement", $$);
          }
          | WHILE LPAREN expression RPAREN statement
          {
              $$ = newSymbolInfof("statement", "%s%s%s%s%s", $1->name, $2->name, $3->name, $4->name, $5->name);
              printRule("statement : WHILE LPAREN expression RPAREN statement", $$);
          }
          | PRINTLN LPAREN ID RPAREN SEMICOLON
          {
              $$ = newSymbolInfof("statement", "%s%s%s%s%s", $1->name, $2->name, $3->name, $4->name, $5->name);
              printRule("statement : PRINTLN LPAREN ID RPAREN SEMICOLON", $$);
          }
          | RETURN expression SEMICOLON
          {
              $$ = newSymbolInfof("statement", "%s %s%s", $1->name, $2->name, $3->name);
              printRule("statement : RETURN expression SEMICOLON", $$);
          }
          ;

expression_statement : SEMICOLON
                      {
                          $$ = $1;
                          printRule("expression_statement : SEMICOLON", $$);
                      }
                      | expression SEMICOLON
                      {
                          $$ = newSymbolInfof("expression_statement", "%s%s", $1->name, $2->name);
                          printRule("expression_statement : expression SEMICOLON", $$);
                      }
                      ;

variable : ID
         {
             $$ = $1;
             printRule("variable : ID", $$);
         }
         | ID LTHIRD expression RTHIRD
         {
             $$ = newSymbolInfof("variable", "%s%s%s%s", $1->name, $2->name, $3->name, $4->name);
             printRule("variable : ID LTHIRD expression RTHIRD", $$);
         }
         ;

expression : logic_expression
           {
               $$ = $1;
               printRule("expression : logic_expression", $$);
           }
           | variable ASSIGNOP logic_expression
           {
               $$ = newSymbolInfof("expression", "%s%s%s", $1->name, $2->name, $3->name);
               printRule("expression : variable ASSIGNOP logic_expression", $$);
           }
           ;

logic_expression : rel_expression
                  {
                      $$ = $1;
                      printRule("logic_expression : rel_expression", $$);
                  }
                  | rel_expression LOGICOP rel_expression
                  {
                      $$ = newSymbolInfof("logic_expression", "%s%s%s", $1->name, $2->name, $3->name);
                      printRule("logic_expression : rel_expression LOGICOP rel_expression", $$);
                  }
                  ;

rel_expression : simple_expression
               {
                   $$ = $1;
                   printRule("rel_expression : simple_expression", $$);
               }
               | simple_expression RELOP simple_expression
               {
                   $$ = newSymbolInfof("rel_expression", "%s%s%s", $1->name, $2->name, $3->name);
                   printRule("rel_expression : simple_expression RELOP simple_expression", $$);
               }
               ;

simple_expression : term
                   {
                       $$ = $1;
                       printRule("simple_expression : term", $$);
                   }
                   | simple_expression ADDOP term
                   {
                       $$ = newSymbolInfof("simple_expression", "%s%s%s", $1->name, $2->name, $3->name);
                       printRule("simple_expression : simple_expression ADDOP term", $$);
                   }
                   ;

term : unary_expression
     {
         $$ = $1;
         printRule("term : unary_expression", $$);
     }
     | term MULOP unary_expression
     {
         $$ = newSymbolInfof("term", "%s%s%s", $1->name, $2->name, $3->name);
         printRule("term : term MULOP unary_expression", $$);
     }
     ;

unary_expression : ADDOP unary_expression %prec UMINUS
                  {
                      $$ = newSymbolInfof("unary_expression", "%s%s", $1->name, $2->name);
                      printRule("unary_expression : ADDOP unary_expression", $$);
                  }
                  | NOT unary_expression
                  {
                      $$ = newSymbolInfof("unary_expression", "%s%s", $1->name, $2->name);
                      printRule("unary_expression : NOT unary_expression", $$);
                  }
                  | factor_info
                  {
                      $$ = $1;
                      printRule("unary_expression : factor_info", $$);
                  }
                  ;

factor_info : factor
            {
                $$ = $1;
                printRule("factor_info : factor", $$);
            }
            ;

factor : variable
       {
           $$ = $1;
           printRule("factor : variable", $$);
       }
       | ID LPAREN argument_list RPAREN
       {
           $$ = newSymbolInfof("factor", "%s%s%s%s", $1->name, $2->name, $3->name, $4->name);
           printRule("factor : ID LPAREN argument_list RPAREN", $$);
       }
       | LPAREN expression RPAREN
       {
           $$ = newSymbolInfof("factor", "%s%s%s", $1->name, $2->name, $3->name);
           printRule("factor : LPAREN expression RPAREN", $$);
       }
       | CONST_INT
       {
           $$ = $1;
           printRule("factor : CONST_INT", $$);
       }
       | CONST_FLOAT
       {
           $$ = $1;
           printRule("factor : CONST_FLOAT", $$);
       }
       | variable INCOP
       {
           $$ = newSymbolInfof("factor", "%s%s", $1->name, $2->name);
           printRule("factor : variable INCOP", $$);
       }
       | variable DECOP
       {
           $$ = newSymbolInfof("factor", "%s%s", $1->name, $2->name);
           printRule("factor : variable DECOP", $$);
       }
       ;

argument_list : arguments
              {
                  $$ = $1;
                  printRule("argument_list : arguments", $$);
              }
              |
              {
                  $$ = newSymbolInfo("", "argument_list");
                  printRule("argument_list : ", $$);
              }
              ;

arguments : arguments COMMA logic_expression
          {
              $$ = newSymbolInfof("arguments", "%s%s%s", $1->name, $2->name, $3->name);
              printRule("arguments : arguments COMMA logic_expression", $$);
          }
          | logic_expression
          {
              $$ = $1;
              printRule("arguments : logic_expression", $$);
          }
          ;

%%

void yyerror(const char *msg) {
    fprintf(logFile, "Line %d: Syntax Error - %s\n", currentLine, msg);
}

int main(int argc, char *argv[]) {
    if (argc < 2) {
        printf("Usage: %s <input_file>\n", argv[0]);
        return 1;
    }

    yyin = fopen(argv[1], "r");
    if (yyin == NULL) {
        printf("Cannot open input file %s\n", argv[1]);
        return 1;
    }

    logFile = fopen("22201080_log.txt", "w");
    if (logFile == NULL) {
        printf("Cannot open log file\n");
        fclose(yyin);
        return 1;
    }

    yyparse();

    fprintf(logFile, "Total Lines: %d\n", currentLine);

    fclose(yyin);
    fclose(logFile);
    return 0;
}
