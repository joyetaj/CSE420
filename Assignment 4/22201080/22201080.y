%{
#include <bits/stdc++.h>
#include "symbol_info.h"
#include "ast.h"
#include "symbol_table.h"
using namespace std;

extern int line_count;
extern FILE* yyin;
int yylex(void);
void yyerror(const char* s);

FILE* logOut;
FILE* errOut;
int error_count = 0;

SymbolTable symtab(10);
ProgramNode* astRoot = new ProgramNode();

TempVarManager g_temp_mgr;
LabelManager g_label_mgr;
CodeEmitter g_code;

// currently open function (used while parsing its body)
static FuncNode* current_func = nullptr;

// The type most recently produced by a type_specifier reduction. Since
// "declaration_list" follows "type_specifier" immediately in the grammar
// (var_declaration : type_specifier declaration_list SEMICOLON), this acts
// as a simple inherited attribute for the declarations being built.
static string g_current_decl_type = "int";

static void log_rule(int lineno, const string& rule, const string& text) {
    fprintf(logOut, "\nAt line no: %d %s \n\n%s\n\n", lineno, rule.c_str(), text.c_str());
}

static void semantic_error(int lineno, const string& msg) {
    fprintf(errOut, "Line# %d: %s\n", lineno, msg.c_str());
    error_count++;
}

// Reports an error if a "void" typed expression is being used as if it had
// a value (e.g. as an operand of +, -, ==, or the right side of "=").
static void check_not_void(int lineno, SymbolInfo* s, const string& context) {
    if (s->getvartype() == "void") {
        semantic_error(lineno, "Void value used in " + context);
    }
}

%}

%union {
    SymbolInfo* symbol;
}

%token <symbol> ID CONST_INT CONST_FLOAT
%token <symbol> INT FLOAT VOID
%token <symbol> IF ELSE FOR WHILE RETURN
%token <symbol> ADDOP MULOP RELOP LOGICOP NOT ASSIGNOP INCOP DECOP
%token <symbol> LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON

%type <symbol> start program unit func_declaration func_definition
%type <symbol> parameter_list type_specifier declaration_list var_declaration
%type <symbol> compound_statement statements statement expression_statement
%type <symbol> variable expression logic_expression rel_expression
%type <symbol> simple_expression term unary_expression factor
%type <symbol> argument_list arguments

%%

start : program
    {
        $$ = $1;
        astRoot = (ProgramNode*)$$->get_ast_node();
        log_rule(line_count, "start : program", $$->get_name());
        fprintf(logOut, "\n==== Abstract Syntax Tree ====\n");
        if (astRoot) astRoot->print_tree(logOut, 0);
        fprintf(logOut, "\nSymbol Table\n");
        fprintf(logOut, "%s\n", symtab.print_all_scopes().c_str());
    }
    ;

program : program unit
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "\n" + $2->get_name());
        ProgramNode* prog = (ProgramNode*)$1->get_ast_node();
        if ($2->get_ast_node()) prog->add_unit((StmtNode*)$2->get_ast_node());
        $$->set_ast_node(prog);
        log_rule(line_count, "program : program unit", $$->get_name());
    }
    | unit
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name());
        ProgramNode* prog = new ProgramNode();
        if ($1->get_ast_node()) prog->add_unit((StmtNode*)$1->get_ast_node());
        $$->set_ast_node(prog);
        log_rule(line_count, "program : unit", $$->get_name());
    }
    ;

unit : var_declaration
    {
        $$ = $1;
        log_rule(line_count, "unit : var_declaration", $$->get_name());
    }
    | func_declaration
    {
        $$ = $1;
        log_rule(line_count, "unit : func_declaration", $$->get_name());
    }
    | func_definition
    {
        $$ = $1;
        log_rule(line_count, "unit : func_definition", $$->get_name());
    }
    ;

func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON
    {
        $$ = new SymbolInfo();
        string text = $1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ");";
        $$->set_name(text);
        SymbolInfo* existing = symtab.lookup_current_scope($2->get_name());
        if (existing && !existing->get_is_function()) {
            semantic_error(line_count, "'" + $2->get_name() + "' redeclared as a different kind of symbol");
        } else if (!existing) {
            SymbolInfo* funcSym = new SymbolInfo($2->get_name(), "ID");
            funcSym->set_is_function(true);
            funcSym->set_is_defined(false);
            funcSym->set_data_type($1->get_name());
            funcSym->get_params() = $4->get_params();
            symtab.insert(funcSym);
        }
        $$->set_ast_node(nullptr);
        log_rule(line_count, "func_declaration : type_specifier ID LPAREN parameter_list RPAREN SEMICOLON", text);
    }
    | type_specifier ID LPAREN RPAREN SEMICOLON
    {
        $$ = new SymbolInfo();
        string text = $1->get_name() + " " + $2->get_name() + "();";
        $$->set_name(text);
        SymbolInfo* existing = symtab.lookup_current_scope($2->get_name());
        if (existing && !existing->get_is_function()) {
            semantic_error(line_count, "'" + $2->get_name() + "' redeclared as a different kind of symbol");
        } else if (!existing) {
            SymbolInfo* funcSym = new SymbolInfo($2->get_name(), "ID");
            funcSym->set_is_function(true);
            funcSym->set_is_defined(false);
            funcSym->set_data_type($1->get_name());
            symtab.insert(funcSym);
        }
        $$->set_ast_node(nullptr);
        log_rule(line_count, "func_declaration : type_specifier ID LPAREN RPAREN SEMICOLON", text);
    }
    ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN
    {
        SymbolInfo* existing = symtab.lookup_current_scope($2->get_name());
        if (existing) {
            if (!existing->get_is_function()) {
                semantic_error(line_count, "'" + $2->get_name() + "' redeclared as a different kind of symbol");
            } else if (existing->get_is_defined()) {
                semantic_error(line_count, "Redefinition of function '" + $2->get_name() + "'");
            } else {
                existing->set_is_defined(true);
                existing->get_params() = $4->get_params();
            }
        } else {
            SymbolInfo* funcSym = new SymbolInfo($2->get_name(), "ID");
            funcSym->set_is_function(true);
            funcSym->set_is_defined(true);
            funcSym->set_data_type($1->get_name());
            funcSym->get_params() = $4->get_params();
            symtab.insert(funcSym);
        }

        current_func = new FuncNode($1->get_name(), $2->get_name(), line_count);
        current_func->params = $4->get_params();

        symtab.enter_scope();
        for (auto& p : current_func->params) {
            SymbolInfo* paramSym = new SymbolInfo(p.name, "ID");
            paramSym->set_data_type(p.type);
            symtab.insert(paramSym);
        }
    }
    LCURL statements RCURL
    {
        $$ = new SymbolInfo();
        string text = $1->get_name() + " " + $2->get_name() + "(" + $4->get_name() + ")\n{\n" + $8->get_name() + "\n}";
        $$->set_name(text);

        BlockNode* body = new BlockNode(line_count);
        if ($8->get_ast_node()) body->add_statement((StmtNode*)$8->get_ast_node());
        current_func->body = body;

        fprintf(logOut, "\n%s\n\n", symtab.print_current_scope().c_str());
        symtab.exit_scope();

        $$->set_ast_node(current_func);
        current_func = nullptr;
        log_rule(line_count, "func_definition : type_specifier ID LPAREN parameter_list RPAREN LCURL statements RCURL", text);
    }
    | type_specifier ID LPAREN RPAREN
    {
        SymbolInfo* existing = symtab.lookup_current_scope($2->get_name());
        if (existing) {
            if (!existing->get_is_function()) {
                semantic_error(line_count, "'" + $2->get_name() + "' redeclared as a different kind of symbol");
            } else if (existing->get_is_defined()) {
                semantic_error(line_count, "Redefinition of function '" + $2->get_name() + "'");
            } else {
                existing->set_is_defined(true);
            }
        } else {
            SymbolInfo* funcSym = new SymbolInfo($2->get_name(), "ID");
            funcSym->set_is_function(true);
            funcSym->set_is_defined(true);
            funcSym->set_data_type($1->get_name());
            symtab.insert(funcSym);
        }

        current_func = new FuncNode($1->get_name(), $2->get_name(), line_count);
        symtab.enter_scope();
    }
    LCURL statements RCURL
    {
        $$ = new SymbolInfo();
        string text = $1->get_name() + " " + $2->get_name() + "()\n{\n" + $7->get_name() + "\n}";
        $$->set_name(text);

        BlockNode* body = new BlockNode(line_count);
        if ($7->get_ast_node()) body->add_statement((StmtNode*)$7->get_ast_node());
        current_func->body = body;

        fprintf(logOut, "\n%s\n\n", symtab.print_current_scope().c_str());
        symtab.exit_scope();

        $$->set_ast_node(current_func);
        current_func = nullptr;
        log_rule(line_count, "func_definition : type_specifier ID LPAREN RPAREN LCURL statements RCURL", text);
    }
    ;

parameter_list : parameter_list COMMA type_specifier ID
    {
        $$ = $1;
        $$->add_param($3->get_name(), $4->get_name());
        $$->set_name($1->get_name() + "," + $3->get_name() + " " + $4->get_name());
        log_rule(line_count, "parameter_list : parameter_list COMMA type_specifier ID", $$->get_name());
    }
    | parameter_list COMMA type_specifier
    {
        $$ = $1;
        $$->add_param($3->get_name(), "");
        $$->set_name($1->get_name() + "," + $3->get_name());
        log_rule(line_count, "parameter_list : parameter_list COMMA type_specifier", $$->get_name());
    }
    | type_specifier ID
    {
        $$ = new SymbolInfo();
        $$->add_param($1->get_name(), $2->get_name());
        $$->set_name($1->get_name() + " " + $2->get_name());
        log_rule(line_count, "parameter_list : type_specifier ID", $$->get_name());
    }
    | type_specifier
    {
        $$ = new SymbolInfo();
        $$->add_param($1->get_name(), "");
        $$->set_name($1->get_name());
        log_rule(line_count, "parameter_list : type_specifier", $$->get_name());
    }
    ;

compound_statement : LCURL
    {
        symtab.enter_scope();
    }
    statements RCURL
    {
        $$ = new SymbolInfo();
        $$->set_name("{\n" + $3->get_name() + "\n}");
        BlockNode* block = new BlockNode(line_count);
        if ($3->get_ast_node()) block->add_statement((StmtNode*)$3->get_ast_node());
        fprintf(logOut, "\n%s\n\n", symtab.print_current_scope().c_str());
        symtab.exit_scope();
        $$->set_ast_node(block);
        log_rule(line_count, "compound_statement : LCURL statements RCURL", $$->get_name());
    }
    | LCURL
    {
        symtab.enter_scope();
    }
    RCURL
    {
        $$ = new SymbolInfo();
        $$->set_name("{\n}");
        BlockNode* block = new BlockNode(line_count);
        fprintf(logOut, "\n%s\n\n", symtab.print_current_scope().c_str());
        symtab.exit_scope();
        $$->set_ast_node(block);
        log_rule(line_count, "compound_statement : LCURL RCURL", $$->get_name());
    }
    ;

var_declaration : type_specifier declaration_list SEMICOLON
    {
        $$ = new SymbolInfo();
        string text = $1->get_name() + " " + $2->get_name() + ";";
        $$->set_name(text);
        // declaration_list->ast_node holds a BlockNode collecting DeclNodes
        $$->set_ast_node($2->get_ast_node());
        log_rule(line_count, "var_declaration : type_specifier declaration_list SEMICOLON", text);
    }
    ;

declaration_list : declaration_list COMMA ID
    {
        $$ = $1;
        $$->set_name($1->get_name() + "," + $3->get_name());
        SymbolInfo* varSym = new SymbolInfo($3->get_name(), "ID");
        varSym->set_data_type(g_current_decl_type);
        if (!symtab.insert(varSym)) semantic_error(line_count, "Multiple declaration of '" + $3->get_name() + "'");
        BlockNode* blk = (BlockNode*)$$->get_ast_node();
        blk->add_statement(new DeclNode(g_current_decl_type, $3->get_name(), false, 0, line_count));
        log_rule(line_count, "declaration_list : declaration_list COMMA ID", $$->get_name());
    }
    | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
    {
        $$ = $1;
        $$->set_name($1->get_name() + "," + $3->get_name() + "[" + $5->get_name() + "]");
        SymbolInfo* varSym = new SymbolInfo($3->get_name(), "ID");
        varSym->set_data_type(g_current_decl_type);
        varSym->set_is_array(true);
        varSym->set_array_size(atoi($5->get_name().c_str()));
        if (!symtab.insert(varSym)) semantic_error(line_count, "Multiple declaration of '" + $3->get_name() + "'");
        BlockNode* blk = (BlockNode*)$$->get_ast_node();
        blk->add_statement(new DeclNode(g_current_decl_type, $3->get_name(), true, atoi($5->get_name().c_str()), line_count));
        log_rule(line_count, "declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD", $$->get_name());
    }
    | ID
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name());
        SymbolInfo* varSym = new SymbolInfo($1->get_name(), "ID");
        varSym->set_data_type(g_current_decl_type);
        if (!symtab.insert(varSym)) semantic_error(line_count, "Multiple declaration of '" + $1->get_name() + "'");
        BlockNode* blk = new BlockNode(line_count);
        blk->add_statement(new DeclNode(g_current_decl_type, $1->get_name(), false, 0, line_count));
        $$->set_ast_node(blk);
        log_rule(line_count, "declaration_list : ID", $$->get_name());
    }
    | ID LTHIRD CONST_INT RTHIRD
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "[" + $3->get_name() + "]");
        SymbolInfo* varSym = new SymbolInfo($1->get_name(), "ID");
        varSym->set_data_type(g_current_decl_type);
        varSym->set_is_array(true);
        varSym->set_array_size(atoi($3->get_name().c_str()));
        if (!symtab.insert(varSym)) semantic_error(line_count, "Multiple declaration of '" + $1->get_name() + "'");
        BlockNode* blk = new BlockNode(line_count);
        blk->add_statement(new DeclNode(g_current_decl_type, $1->get_name(), true, atoi($3->get_name().c_str()), line_count));
        $$->set_ast_node(blk);
        log_rule(line_count, "declaration_list : ID LTHIRD CONST_INT RTHIRD", $$->get_name());
    }
    ;

type_specifier : INT
    {
        $$ = new SymbolInfo();
        $$->set_name("int");
        $$->setvartype("int");
        g_current_decl_type = "int";
        log_rule(line_count, "type_specifier : INT", $$->get_name());
    }
    | FLOAT
    {
        $$ = new SymbolInfo();
        $$->set_name("float");
        $$->setvartype("float");
        g_current_decl_type = "float";
        log_rule(line_count, "type_specifier : FLOAT", $$->get_name());
    }
    | VOID
    {
        $$ = new SymbolInfo();
        $$->set_name("void");
        $$->setvartype("void");
        g_current_decl_type = "void";
        log_rule(line_count, "type_specifier : VOID", $$->get_name());
    }
    ;

statements : statement
    {
        $$ = $1;
        log_rule(line_count, "statements : statement", $$->get_name());
    }
    | statements statement
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "\n" + $2->get_name());
        BlockNode* blk = new BlockNode(line_count);
        ASTNode* a1 = $1->get_ast_node();
        ASTNode* a2 = $2->get_ast_node();
        if (dynamic_cast<BlockNode*>(a1)) {
            for (auto s : ((BlockNode*)a1)->statements) blk->add_statement(s);
        } else if (a1) {
            blk->add_statement((StmtNode*)a1);
        }
        if (dynamic_cast<BlockNode*>(a2)) {
            for (auto s : ((BlockNode*)a2)->statements) blk->add_statement(s);
        } else if (a2) {
            blk->add_statement((StmtNode*)a2);
        }
        $$->set_ast_node(blk);
        log_rule(line_count, "statements : statements statement", $$->get_name());
    }
    ;

statement : var_declaration
    {
        $$ = $1;
        log_rule(line_count, "statement : var_declaration", $$->get_name());
    }
    | expression_statement
    {
        $$ = $1;
        log_rule(line_count, "statement : expression_statement", $$->get_name());
    }
    | compound_statement
    {
        $$ = $1;
        log_rule(line_count, "statement : compound_statement", $$->get_name());
    }
    | FOR LPAREN expression_statement expression_statement expression RPAREN statement
    {
        $$ = new SymbolInfo();
        string text = "for(" + $3->get_name() + $4->get_name() + $5->get_name() + ")\n" + $7->get_name();
        $$->set_name(text);
        ExprStmtNode* initS = (ExprStmtNode*)$3->get_ast_node();
        ExprStmtNode* condS = (ExprStmtNode*)$4->get_ast_node();
        ForNode* forN = new ForNode(initS ? initS->expr : nullptr,
                                     condS ? condS->expr : nullptr,
                                     (ExprNode*)$5->get_ast_node(),
                                     (StmtNode*)$7->get_ast_node(), line_count);
        $$->set_ast_node(forN);
        log_rule(line_count, "statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement", text);
    }
    | IF LPAREN expression RPAREN statement
    {
        $$ = new SymbolInfo();
        string text = "if(" + $3->get_name() + ")\n" + $5->get_name();
        $$->set_name(text);
        IfNode* ifN = new IfNode((ExprNode*)$3->get_ast_node(), (StmtNode*)$5->get_ast_node(), nullptr, line_count);
        $$->set_ast_node(ifN);
        log_rule(line_count, "statement : IF LPAREN expression RPAREN statement", text);
    }
    | IF LPAREN expression RPAREN statement ELSE statement
    {
        $$ = new SymbolInfo();
        string text = "if(" + $3->get_name() + ")\n" + $5->get_name() + "\nelse\n" + $7->get_name();
        $$->set_name(text);
        IfNode* ifN = new IfNode((ExprNode*)$3->get_ast_node(), (StmtNode*)$5->get_ast_node(), (StmtNode*)$7->get_ast_node(), line_count);
        $$->set_ast_node(ifN);
        log_rule(line_count, "statement : IF LPAREN expression RPAREN statement ELSE statement", text);
    }
    | WHILE LPAREN expression RPAREN statement
    {
        $$ = new SymbolInfo();
        string text = "while(" + $3->get_name() + ")\n" + $5->get_name();
        $$->set_name(text);
        WhileNode* whileN = new WhileNode((ExprNode*)$3->get_ast_node(), (StmtNode*)$5->get_ast_node(), line_count);
        $$->set_ast_node(whileN);
        log_rule(line_count, "statement : WHILE LPAREN expression RPAREN statement", text);
    }
    | RETURN expression SEMICOLON
    {
        $$ = new SymbolInfo();
        string text = "return " + $2->get_name() + ";";
        $$->set_name(text);
        if (current_func && current_func->return_type == "void" && $2->getvartype() != "void") {
            semantic_error(line_count, "Function '" + current_func->name + "' declared void but returns a value");
        }
        ReturnNode* retN = new ReturnNode((ExprNode*)$2->get_ast_node(), line_count);
        $$->set_ast_node(retN);
        log_rule(line_count, "statement : RETURN expression SEMICOLON", text);
    }
    ;

expression_statement : SEMICOLON
    {
        $$ = new SymbolInfo();
        $$->set_name(";");
        $$->set_ast_node(new ExprStmtNode(nullptr, line_count));
        log_rule(line_count, "expression_statement : SEMICOLON", $$->get_name());
    }
    | expression SEMICOLON
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + ";");
        $$->set_ast_node(new ExprStmtNode((ExprNode*)$1->get_ast_node(), line_count));
        log_rule(line_count, "expression_statement : expression SEMICOLON", $$->get_name());
    }
    ;

variable : ID
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name());
        SymbolInfo* found = symtab.lookup($1->get_name());
        string vtype = found ? found->get_data_type() : "int";
        if (!found) {
            semantic_error(line_count, "Undeclared variable '" + $1->get_name() + "'");
        } else if (found->get_is_function()) {
            semantic_error(line_count, "'" + $1->get_name() + "' is a function, not a variable");
        } else if (found->get_is_array()) {
            semantic_error(line_count, "Array '" + $1->get_name() + "' used without an index");
        }
        $$->setvartype(vtype);
        $$->set_ast_node(new VarNode($1->get_name(), vtype, nullptr, line_count));
        log_rule(line_count, "variable : ID", $$->get_name());
    }
    | ID LTHIRD expression RTHIRD
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "[" + $3->get_name() + "]");
        SymbolInfo* found = symtab.lookup($1->get_name());
        string vtype = found ? found->get_data_type() : "int";
        if (!found) {
            semantic_error(line_count, "Undeclared variable '" + $1->get_name() + "'");
        } else if (!found->get_is_array()) {
            semantic_error(line_count, "'" + $1->get_name() + "' is not an array");
        }
        if ($3->getvartype() == "float") {
            semantic_error(line_count, "Array index for '" + $1->get_name() + "' is not an integer");
        }
        $$->setvartype(vtype);
        $$->set_ast_node(new VarNode($1->get_name(), vtype, (ExprNode*)$3->get_ast_node(), line_count));
        log_rule(line_count, "variable : ID LTHIRD expression RTHIRD", $$->get_name());
    }
    ;

expression : logic_expression
    {
        $$ = $1;
        log_rule(line_count, "expression : logic_expression", $$->get_name());
    }
    | variable ASSIGNOP logic_expression
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "=" + $3->get_name());
        $$->setvartype($1->getvartype());
        check_not_void(line_count, $3, "assignment");
        AssignNode* assignNode = new AssignNode((VarNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), $1->getvartype(), line_count);
        $$->set_ast_node(assignNode);
        log_rule(line_count, "expression : variable ASSIGNOP logic_expression", $$->get_name());
    }
    ;

logic_expression : rel_expression
    {
        $$ = $1;
        log_rule(line_count, "logic_expression : rel_expression", $$->get_name());
    }
    | rel_expression LOGICOP rel_expression
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
        $$->setvartype("int");
        check_not_void(line_count, $1, "a logical expression");
        check_not_void(line_count, $3, "a logical expression");
        BinaryOpNode* binOp = new BinaryOpNode($2->get_name(), (ExprNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), "int", line_count);
        $$->set_ast_node(binOp);
        log_rule(line_count, "logic_expression : rel_expression LOGICOP rel_expression", $$->get_name());
    }
    ;

rel_expression : simple_expression
    {
        $$ = $1;
        log_rule(line_count, "rel_expression : simple_expression", $$->get_name());
    }
    | simple_expression RELOP simple_expression
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
        $$->setvartype("int");
        check_not_void(line_count, $1, "a relational expression");
        check_not_void(line_count, $3, "a relational expression");
        BinaryOpNode* binOp = new BinaryOpNode($2->get_name(), (ExprNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), "int", line_count);
        $$->set_ast_node(binOp);
        log_rule(line_count, "rel_expression : simple_expression RELOP simple_expression", $$->get_name());
    }
    ;

simple_expression : term
    {
        $$ = $1;
        log_rule(line_count, "simple_expression : term", $$->get_name());
    }
    | simple_expression ADDOP term
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
        $$->setvartype($1->getvartype());
        check_not_void(line_count, $1, "an arithmetic expression");
        check_not_void(line_count, $3, "an arithmetic expression");
        BinaryOpNode* binOp = new BinaryOpNode($2->get_name(), (ExprNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), $1->getvartype(), line_count);
        $$->set_ast_node(binOp);
        log_rule(line_count, "simple_expression : simple_expression ADDOP term", $$->get_name());
    }
    ;

term : unary_expression
    {
        $$ = $1;
        log_rule(line_count, "term : unary_expression", $$->get_name());
    }
    | term MULOP unary_expression
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + $2->get_name() + $3->get_name());
        $$->setvartype($1->getvartype());
        check_not_void(line_count, $1, "an arithmetic expression");
        check_not_void(line_count, $3, "an arithmetic expression");
        BinaryOpNode* binOp = new BinaryOpNode($2->get_name(), (ExprNode*)$1->get_ast_node(), (ExprNode*)$3->get_ast_node(), $1->getvartype(), line_count);
        $$->set_ast_node(binOp);
        log_rule(line_count, "term : term MULOP unary_expression", $$->get_name());
    }
    ;

unary_expression : ADDOP unary_expression
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + $2->get_name());
        $$->setvartype($2->getvartype());
        UnaryOpNode* unOp = new UnaryOpNode($1->get_name(), (ExprNode*)$2->get_ast_node(), $2->getvartype(), line_count);
        $$->set_ast_node(unOp);
        log_rule(line_count, "unary_expression : ADDOP unary_expression", $$->get_name());
    }
    | NOT unary_expression
    {
        $$ = new SymbolInfo();
        $$->set_name("!" + $2->get_name());
        $$->setvartype("int");
        UnaryOpNode* unOp = new UnaryOpNode("!", (ExprNode*)$2->get_ast_node(), "int", line_count);
        $$->set_ast_node(unOp);
        log_rule(line_count, "unary_expression : NOT unary_expression", $$->get_name());
    }
    | factor
    {
        $$ = $1;
        log_rule(line_count, "unary_expression : factor", $$->get_name());
    }
    ;

factor : variable
    {
        $$ = $1;
        log_rule(line_count, "factor : variable", $$->get_name());
    }
    | ID LPAREN argument_list RPAREN
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "(" + $3->get_name() + ")");
        SymbolInfo* funcSym = symtab.lookup($1->get_name());
        string rtype = "int";
        if (!funcSym) {
            semantic_error(line_count, "Undeclared function '" + $1->get_name() + "'");
        } else if (!funcSym->get_is_function()) {
            semantic_error(line_count, "'" + $1->get_name() + "' is not a function");
        } else {
            rtype = funcSym->get_data_type();
            size_t given = $3->get_args().size();
            size_t expected = funcSym->get_params().size();
            // A single lone type-only parameter (e.g. "int func(void-less proto)")
            // with no arguments passed is treated as zero expected args.
            if (!(expected == 1 && funcSym->get_params()[0].name.empty() && given == 0)) {
                if (given != expected) {
                    semantic_error(line_count, "Function '" + $1->get_name() + "' expects " +
                        std::to_string(expected) + " argument(s) but " + std::to_string(given) + " given");
                }
            }
        }
        $$->setvartype(rtype);
        FuncCallNode* callNode = new FuncCallNode($1->get_name(), rtype, line_count);
        for (auto a : $3->get_args()) callNode->add_arg(a);
        $$->set_ast_node(callNode);
        log_rule(line_count, "factor : ID LPAREN argument_list RPAREN", $$->get_name());
    }
    | LPAREN expression RPAREN
    {
        $$ = $2;
        $$->set_name("(" + $2->get_name() + ")");
        log_rule(line_count, "factor : LPAREN expression RPAREN", $$->get_name());
    }
    | CONST_INT
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name());
        $$->setvartype("int");
        $$->set_ast_node(new ConstNode($1->get_name(), "int", line_count));
        log_rule(line_count, "factor : CONST_INT", $$->get_name());
    }
    | CONST_FLOAT
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name());
        $$->setvartype("float");
        $$->set_ast_node(new ConstNode($1->get_name(), "float", line_count));
        log_rule(line_count, "factor : CONST_FLOAT", $$->get_name());
    }
    | variable INCOP
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "++");
        $$->setvartype($1->getvartype());
        $$->set_ast_node(new IncDecNode("++", (VarNode*)$1->get_ast_node(), line_count));
        log_rule(line_count, "factor : variable INCOP", $$->get_name());
    }
    | variable DECOP
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name() + "--");
        $$->setvartype($1->getvartype());
        $$->set_ast_node(new IncDecNode("--", (VarNode*)$1->get_ast_node(), line_count));
        log_rule(line_count, "factor : variable DECOP", $$->get_name());
    }
    ;

argument_list : arguments
    {
        $$ = $1;
        log_rule(line_count, "argument_list : arguments", $$->get_name());
    }
    |
    {
        $$ = new SymbolInfo();
        $$->set_name("");
        log_rule(line_count, "argument_list : ", $$->get_name());
    }
    ;

arguments : arguments COMMA logic_expression
    {
        $$ = $1;
        $$->set_name($1->get_name() + "," + $3->get_name());
        $$->add_arg((ExprNode*)$3->get_ast_node());
        log_rule(line_count, "arguments : arguments COMMA logic_expression", $$->get_name());
    }
    | logic_expression
    {
        $$ = new SymbolInfo();
        $$->set_name($1->get_name());
        $$->add_arg((ExprNode*)$1->get_ast_node());
        log_rule(line_count, "arguments : logic_expression", $$->get_name());
    }
    ;

%%

void yyerror(const char* s) {
    fprintf(errOut, "Line# %d: Syntax error - %s\n", line_count, s);
    error_count++;
}

int main(int argc, char** argv) {
    if (argc < 2) {
        fprintf(stderr, "Usage: %s <input.c>\n", argv[0]);
        return 1;
    }
    yyin = fopen(argv[1], "r");
    if (!yyin) {
        fprintf(stderr, "Could not open input file %s\n", argv[1]);
        return 1;
    }

    logOut = fopen("log.txt", "w");
    errOut = fopen("error.txt", "w");

    fprintf(logOut, "==== Pass 1: Parsing input and building AST ====\n");

    yyparse();

    fclose(yyin);

    fprintf(logOut, "\n==== Pass 2: Generating Three-Address Code from AST ====\n");
    fprintf(logOut, "Generating Three-Address Code...\n");
    if (astRoot) astRoot->generate_code();
    g_code.write_to_file("code.txt");
    fprintf(logOut, "Three-Address Code Generation Complete\n");

    fprintf(logOut, "\nTotal lines: %d\n", line_count);
    fprintf(logOut, "Total errors: %d\n", error_count);
    fclose(logOut);

    fprintf(errOut, "Total errors: %d\n", error_count);
    fclose(errOut);

    return 0;
}
