%{

#include "symbol_table.h"

#define YYSTYPE symbol_info*

extern FILE *yyin;
int yyparse(void);
int yylex(void);
extern YYSTYPE yylval;

int lines = 1;
int error_count = 0;
ofstream outlog;
ofstream outerror;

symbol_table *table;

string current_type = "";
string current_func_name = "";
string current_func_return_type = "";
vector<pair<string, string>> current_params;
vector<pair<string, string>> current_variables;
int compound_statement_count = 0;

void yyerror(char *s)
{
	outlog<<"At line "<<lines<<" "<<s<<endl<<endl;
}

void log_error(string message)
{
	outerror << "At line no: " << lines << " " << message << endl << endl;
	error_count++;
}

%}

%token IF ELSE FOR WHILE DO BREAK INT CHAR FLOAT DOUBLE VOID RETURN SWITCH CASE DEFAULT CONTINUE PRINTLN ADDOP MULOP INCOP DECOP RELOP ASSIGNOP LOGICOP NOT LPAREN RPAREN LCURL RCURL LTHIRD RTHIRD COMMA SEMICOLON CONST_INT CONST_FLOAT ID

%nonassoc LOWER_THAN_ELSE
%nonassoc ELSE

%%

start : program
	{
		outlog<<"At line no: "<<lines<<" start : program "<<endl<<endl;
		outlog<<"Symbol Table"<<endl<<endl;

		table->print_all_scopes(outlog);

		$$=$1;
	}
	;

program : program unit
	{
		outlog<<"At line no: "<<lines<<" program : program unit "<<endl<<endl;
		outlog<<$1->get_name()+"\n"+$2->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"program");
	}
	| unit
	{
		outlog<<"At line no: "<<lines<<" program : unit "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"program");
	}
	;

unit : var_declaration
	 {
		outlog<<"At line no: "<<lines<<" unit : var_declaration "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"unit");
	 }
     | func_definition
     {
		outlog<<"At line no: "<<lines<<" unit : func_definition "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"unit");
	 }
     ;

func_definition : type_specifier ID LPAREN parameter_list RPAREN
		{
			current_func_name = $2->get_name();
			current_func_return_type = $1->get_name();

			//if function already declared
			symbol_info *existing = table->lookup(new symbol_info(current_func_name, "ID"));
			if (existing != NULL)
			{
				outlog << "At line no: " << lines << " Multiple declaration of function " << current_func_name << endl << endl;
				outerror << "At line no: " << lines << " Multiple declaration of function " << current_func_name << endl << endl;
				error_count++;
			}

			symbol_info *func_symbol = new symbol_info(current_func_name, "ID");
			func_symbol->set_function_info(current_func_return_type, current_params);
			table->insert(func_symbol);

			table->enter_scope(outlog);

			for(auto &param : current_params) {
				if (!param.second.empty()) {
					symbol_info *param_symbol = new symbol_info(param.second, "ID");
					param_symbol->set_variable_info(param.first);
					table->insert(param_symbol);
				}
			}

			compound_statement_count = 0;
		}
		compound_statement
		{
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN parameter_list RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"("+$4->get_name()+")\n"<<$7->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"("+$4->get_name()+")\n"+$7->get_name(),"func_def");

			current_params.clear();
		}
		| type_specifier ID LPAREN RPAREN
		{
			current_func_name = $2->get_name();
			current_func_return_type = $1->get_name();
			current_params.clear();

			// Check if function already declared
			symbol_info *existing = table->lookup(new symbol_info(current_func_name, "ID"));
			if (existing != NULL)
			{
				outlog << "At line no: " << lines << " Multiple declaration of function " << current_func_name << endl << endl;
				outerror << "At line no: " << lines << " Multiple declaration of function " << current_func_name << endl << endl;
				error_count++;
			}

			symbol_info *func_symbol = new symbol_info(current_func_name, "ID");
			func_symbol->set_function_info(current_func_return_type, current_params);
			table->insert(func_symbol);

			table->enter_scope(outlog);

			compound_statement_count = 0;
		}
		compound_statement
		{
			outlog<<"At line no: "<<lines<<" func_definition : type_specifier ID LPAREN RPAREN compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<"()\n"<<$6->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+"()\n"+$6->get_name(),"func_def");
		}
 		;

parameter_list : parameter_list COMMA type_specifier ID
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<" "<<$4->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name()+" "+$4->get_name(),"param_list");

			//Duplicate parameter names checking
			for (auto &param : current_params) {
				if (param.second == $4->get_name()) {
					outlog << "At line no: " << lines << " Multiple declaration of variable "
                   << $4->get_name() << " in parameter of " << current_func_name << endl << endl;
					outerror << "At line no: " << lines << " Multiple declaration of variable "
                   << $4->get_name() << " in parameter of " << current_func_name << endl << endl;
					error_count++;
					break;
				}
			}

			current_params.push_back({$3->get_name(), $4->get_name()});
		}
		| parameter_list COMMA type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : parameter_list COMMA type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"param_list");

			current_params.push_back({$3->get_name(), ""});
		}
 		| type_specifier ID
 		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier ID "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name(),"param_list");

			current_params.clear();
			current_params.push_back({$1->get_name(), $2->get_name()});
		}
		| type_specifier
		{
			outlog<<"At line no: "<<lines<<" parameter_list : type_specifier "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"param_list");

			current_params.clear();
			current_params.push_back({$1->get_name(), ""});
		}
 		;

compound_statement : LCURL
			{
				if(compound_statement_count > 0) {
					table->enter_scope(outlog);
				}
				compound_statement_count++;
			}
			statements RCURL
			{
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL statements RCURL "<<endl<<endl;
				outlog<<"{\n"+$3->get_name()+"\n}"<<endl<<endl;

				$$ = new symbol_info("{\n"+$3->get_name()+"\n}","comp_stmnt");

				compound_statement_count--;
				if(compound_statement_count == 0) {

					table->print_all_scopes(outlog);
					table->exit_scope(outlog);
				} else if(compound_statement_count > 0) {

					table->print_all_scopes(outlog);
					table->exit_scope(outlog);
				}
 		    }
 		    | LCURL
 		    {
				if(compound_statement_count > 0) {
					table->enter_scope(outlog);
				}
				compound_statement_count++;
			}
			RCURL
 		    {
 		    	outlog<<"At line no: "<<lines<<" compound_statement : LCURL RCURL "<<endl<<endl;
				outlog<<"{\n}"<<endl<<endl;

				$$ = new symbol_info("{\n}","comp_stmnt");

				compound_statement_count--;
				if(compound_statement_count == 0) {

					table->print_all_scopes(outlog);
					table->exit_scope(outlog);
				} else if(compound_statement_count > 0) {

					table->print_all_scopes(outlog);
					table->exit_scope(outlog);
				}
 		    }
 		    ;

var_declaration : type_specifier declaration_list SEMICOLON
		 {
			outlog<<"At line no: "<<lines<<" var_declaration : type_specifier declaration_list SEMICOLON "<<endl<<endl;
			outlog<<$1->get_name()<<" "<<$2->get_name()<<";"<<endl<<endl;

			$$ = new symbol_info($1->get_name()+" "+$2->get_name()+";","var_dec");

			//check for void type
			if (current_type == "void") {
				outlog << "At line no: " << lines << " variable type can not be void " << endl << endl;
				outerror << "At line no: " << lines << " variable type can not be void " << endl << endl;
				error_count++;
			}

			for(auto &var : current_variables) {
				symbol_info *temp = new symbol_info(var.first, "ID");
				symbol_info *existing = table->lookup_current_scope(temp);

				if (existing != NULL) {
					outlog << "At line no: " << lines << " Multiple declaration of variable " << var.first << endl << endl;
					outerror << "At line no: " << lines << " Multiple declaration of variable " << var.first << endl << endl;
					error_count++;
					delete temp;
				}
				else {
					symbol_info *var_symbol = new symbol_info(var.first, "ID");
					if(var.second.empty()) {
						var_symbol->set_variable_info(current_type);
					} else {
						var_symbol->set_array_info(current_type, var.second);
					}
					table->insert(var_symbol);
					delete temp;
				}
			}
			current_variables.clear();
		 }
 		 ;

type_specifier : INT
		{
			outlog<<"At line no: "<<lines<<" type_specifier : INT "<<endl<<endl;
			outlog<<"int"<<endl<<endl;

			current_type = "int";
			$$ = new symbol_info("int","type");
	    }
 		| FLOAT
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : FLOAT "<<endl<<endl;
			outlog<<"float"<<endl<<endl;

			current_type = "float";
			$$ = new symbol_info("float","type");
	    }
 		| VOID
 		{
			outlog<<"At line no: "<<lines<<" type_specifier : VOID "<<endl<<endl;
			outlog<<"void"<<endl<<endl;

			current_type = "void";
			$$ = new symbol_info("void","type");
	    }
 		;

declaration_list : declaration_list COMMA ID
		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name(),"dec_list");

			current_variables.push_back({$3->get_name(), ""});
 		  }
 		  | declaration_list COMMA ID LTHIRD CONST_INT RTHIRD
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : declaration_list COMMA ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
 		  	outlog<<$1->get_name()+","<<$3->get_name()<<"["<<$5->get_name()<<"]"<<endl<<endl;

			$$ = new symbol_info($1->get_name()+","+$3->get_name()+"["+$5->get_name()+"]","dec_list");

			current_variables.push_back({$3->get_name(), $5->get_name()});
 		  }
 		  |ID
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"dec_list");

			current_variables.clear();
			current_variables.push_back({$1->get_name(), ""});
 		  }
 		  | ID LTHIRD CONST_INT RTHIRD
 		  {
 		  	outlog<<"At line no: "<<lines<<" declaration_list : ID LTHIRD CONST_INT RTHIRD "<<endl<<endl;
			outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","dec_list");

			current_variables.clear();
			current_variables.push_back({$1->get_name(), $3->get_name()});
 		  }
 		  ;

statements : statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnts");
	   }
	   | statements statement
	   {
	    	outlog<<"At line no: "<<lines<<" statements : statements statement "<<endl<<endl;
			outlog<<$1->get_name()<<"\n"<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"\n"+$2->get_name(),"stmnts");
	   }
	   ;

statement : var_declaration
	  {
	    	outlog<<"At line no: "<<lines<<" statement : var_declaration "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | expression_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : expression_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | compound_statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : compound_statement "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"stmnt");
	  }
	  | FOR LPAREN expression_statement expression_statement expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : FOR LPAREN expression_statement expression_statement expression RPAREN statement "<<endl<<endl;
			outlog<<"for("<<$3->get_name()<<$4->get_name()<<$5->get_name()<<")\n"<<$7->get_name()<<endl<<endl;

			$$ = new symbol_info("for("+$3->get_name()+$4->get_name()+$5->get_name()+")\n"+$7->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement %prec LOWER_THAN_ELSE
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;

			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | IF LPAREN expression RPAREN statement ELSE statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : IF LPAREN expression RPAREN statement ELSE statement "<<endl<<endl;
			outlog<<"if("<<$3->get_name()<<")\n"<<$5->get_name()<<"\nelse\n"<<$7->get_name()<<endl<<endl;

			$$ = new symbol_info("if("+$3->get_name()+")\n"+$5->get_name()+"\nelse\n"+$7->get_name(),"stmnt");
	  }
	  | WHILE LPAREN expression RPAREN statement
	  {
	    	outlog<<"At line no: "<<lines<<" statement : WHILE LPAREN expression RPAREN statement "<<endl<<endl;
			outlog<<"while("<<$3->get_name()<<")\n"<<$5->get_name()<<endl<<endl;

			$$ = new symbol_info("while("+$3->get_name()+")\n"+$5->get_name(),"stmnt");
	  }
	  | PRINTLN LPAREN ID RPAREN SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : PRINTLN LPAREN ID RPAREN SEMICOLON "<<endl<<endl;
			outlog<<"printf("<<$3->get_name()<<");"<<endl<<endl;

			$$ = new symbol_info("printf("+$3->get_name()+");","stmnt");

			symbol_info *var = table->lookup(new symbol_info($3->get_name(), "ID"));
			if (var == NULL) {
				outlog << "At line no: " << lines << " Undeclared variable " << $3->get_name() << endl << endl;
				outerror << "At line no: " << lines << " Undeclared variable " << $3->get_name() << endl << endl;
				error_count++;
			}
	  }
	  | RETURN expression SEMICOLON
	  {
	    	outlog<<"At line no: "<<lines<<" statement : RETURN expression SEMICOLON "<<endl<<endl;
			outlog<<"return "<<$2->get_name()<<";"<<endl<<endl;

			$$ = new symbol_info("return "+$2->get_name()+";","stmnt");
	  }
	  ;

expression_statement : SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : SEMICOLON "<<endl<<endl;
				outlog<<";"<<endl<<endl;

				$$ = new symbol_info(";","expr_stmt");
	        }
			| expression SEMICOLON
			{
				outlog<<"At line no: "<<lines<<" expression_statement : expression SEMICOLON "<<endl<<endl;
				outlog<<$1->get_name()<<";"<<endl<<endl;

				$$ = new symbol_info($1->get_name()+";","expr_stmt");
	        }
			;

variable : ID
      {
	    outlog<<"At line no: "<<lines<<" variable : ID "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"varbl");

		symbol_info* var = table->lookup(new symbol_info($1->get_name(), "ID"));
		if (var == NULL) {
			outlog << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			outerror << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			error_count++;
			$$->set_data_type("error");
		}
		else {
			if (var->is_array()){
				outlog << "At line no: " << lines << " variable is of array type : " << $1->get_name() << endl << endl;
				outerror << "At line no: " << lines << " variable is of array type : " << $1->get_name() << endl << endl;
				error_count++;
				$$->set_data_type("error");
			}
			else if (var->is_function()) {
				$$->set_data_type("error");
			}
			else {
				$$->set_data_type(var->get_data_type());
			}
		}
	 }
	 | ID LTHIRD expression RTHIRD
	 {
	 	outlog<<"At line no: "<<lines<<" variable : ID LTHIRD expression RTHIRD "<<endl<<endl;
		outlog<<$1->get_name()<<"["<<$3->get_name()<<"]"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"["+$3->get_name()+"]","varbl");
		symbol_info *var = table->lookup(new symbol_info($1->get_name(), "ID"));

		if (var == NULL)
		{
			outlog << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			outerror << "At line no: " << lines << " Undeclared variable " << $1->get_name() << endl << endl;
			error_count++;
			$$->set_data_type("error");
		}
		else
		{
			if (!var->is_array())
			{
				outlog << "At line no: " << lines << " variable is not of array type : " << $1->get_name() << endl << endl;
				outerror << "At line no: " << lines << " variable is not of array type : " << $1->get_name() << endl << endl;
				error_count++;
				$$->set_data_type("error");
			}
			else
			{
				string index_type = $3->get_data_type();
				if (index_type != "int" && index_type != "error"){
					outlog << "At line no: " << lines << " array index is not of integer type : " << $1->get_name() << endl << endl;
					outerror << "At line no: " << lines << " array index is not of integer type : " << $1->get_name() << endl << endl;
					error_count++;
				}
				$$->set_data_type(var->get_data_type());
			}
		}
	 }
	 ;
expression : logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"expr");
	   		$$->set_data_type($1->get_data_type());
		 }
	   | variable ASSIGNOP logic_expression
	   {
	    	outlog<<"At line no: "<<lines<<" expression : variable ASSIGNOP logic_expression "<<endl<<endl;
			outlog<<$1->get_name()<<"="<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+"="+$3->get_name(),"expr");

		 	string lhs_type = $1->get_data_type();
			string rhs_type = $3->get_data_type();

			if (lhs_type != "error" && rhs_type != "error") {
				if (lhs_type == "int" && rhs_type == "float"){
					outlog << "At line no: " << lines << " Warning: Assignment of float value into variable of integer type " << endl << endl;
					outerror << "At line no: " << lines << " Warning: Assignment of float value into variable of integer type " << endl << endl;
					error_count++;
				}

				if (rhs_type == "void") {
					outlog << "At line no: " << lines << " operation on void type " << endl << endl;
					outerror << "At line no: " << lines << " operation on void type " << endl << endl;
					error_count++;
					$$->set_data_type("error");
				}
				else {
					$$->set_data_type(lhs_type);
				}
			}
			else {
				$$->set_data_type("error");
			}
		 }
	   ;

logic_expression : rel_expression
	     {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"lgc_expr");
	    	$$->set_data_type($1->get_data_type());
		 }
		 | rel_expression LOGICOP rel_expression
		 {
	    	outlog<<"At line no: "<<lines<<" logic_expression : rel_expression LOGICOP rel_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"lgc_expr");
			$$->set_data_type("int");
		 }
		 ;

rel_expression	: simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"rel_expr");
	    	$$->set_data_type($1->get_data_type());
		}
		| simple_expression RELOP simple_expression
		{
	    	outlog<<"At line no: "<<lines<<" rel_expression : simple_expression RELOP simple_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"rel_expr");
			$$->set_data_type("int");
		}
		;

simple_expression : term
          {
	    	outlog<<"At line no: "<<lines<<" simple_expression : term "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"simp_expr");
	      	$$->set_data_type($1->get_data_type());
		  }
		  | simple_expression ADDOP term
		  {
	    	outlog<<"At line no: "<<lines<<" simple_expression : simple_expression ADDOP term "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"simp_expr");

			string type1 = $1->get_data_type();
			string type2 = $3->get_data_type();

			if (type1 == "error" || type2 == "error") {
				$$->set_data_type("error");
			}
			else if (type1 == "float" || type2 == "float") {
				$$->set_data_type("float");
			}
			else {
				$$->set_data_type("int");
			}
		  }
		  ;

term :	unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"term");
			$$->set_data_type($1->get_data_type());
	 }
     |  term MULOP unary_expression
     {
	    	outlog<<"At line no: "<<lines<<" term : term MULOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<$3->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name()+$3->get_name(),"term");

			string type1 = $1->get_data_type();
			string type2 = $3->get_data_type();
			string op = $2->get_name();

			if (type1 != "error" && type2 != "error") {
				if (op == "%") {
					if (type1 != "int" || type2 != "int") {
						outlog << "At line no: " << lines << " Modulus operator on non integer type " << endl << endl;
						outerror << "At line no: " << lines << " Modulus operator on non integer type " << endl << endl;
						error_count++;
					}

					if ($3->get_name() == "0") {
						outlog << "At line no: " << lines << " Modulus by 0 " << endl << endl;
						outerror << "At line no: " << lines << " Modulus by 0 " << endl << endl;
						error_count++;
					}

					$$->set_data_type("int");
				}
				else if(op == "/") {
					if ($3->get_name() == "0") {
						outlog << "At line no: " << lines << " Division by 0 " << endl << endl;
						outerror << "At line no: " << lines << " Division by 0 " << endl << endl;
						error_count++;
					}

					if (type1 == "float" || type2 == "float") {
						$$->set_data_type("float");
					}
					else {
						$$->set_data_type("int");
					}
				}
				else {
					if (type1 == "float" || type2 == "float") {
						$$->set_data_type("float");
					}
					else {
						$$->set_data_type("int");
					}
				}

				if (type1 == "void" || type2 == "void")
				{
					outlog << "At line no: " << lines << " operation on void type " << endl << endl;
					outerror << "At line no: " << lines << " operation on void type " << endl << endl;
					error_count++;
					$$->set_data_type("error");
				}
			}
			else
			{
				$$->set_data_type("error");
			}
	 }
     ;

unary_expression : ADDOP unary_expression
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : ADDOP unary_expression "<<endl<<endl;
			outlog<<$1->get_name()<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name()+$2->get_name(),"un_expr");
	     	$$->set_data_type($2->get_data_type());
		 }
		 | NOT unary_expression
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : NOT unary_expression "<<endl<<endl;
			outlog<<"!"<<$2->get_name()<<endl<<endl;

			$$ = new symbol_info("!"+$2->get_name(),"un_expr");
	      	$$->set_data_type("int");
		 }
		 | factor
		 {
	    	outlog<<"At line no: "<<lines<<" unary_expression : factor "<<endl<<endl;
			outlog<<$1->get_name()<<endl<<endl;

			$$ = new symbol_info($1->get_name(),"un_expr");
			$$->set_data_type($1->get_data_type());
		 }
		 ;

factor	: variable
    {
	    outlog<<"At line no: "<<lines<<" factor : variable "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type($1->get_data_type());
	}
	| ID LPAREN argument_list RPAREN
	{
	    outlog<<"At line no: "<<lines<<" factor : ID LPAREN argument_list RPAREN "<<endl<<endl;
		outlog<<$1->get_name()<<"("<<$3->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"("+$3->get_name()+")","fctr");

		symbol_info *func = table->lookup(new symbol_info($1->get_name(), "ID"));

		if (func == NULL) {
			outlog << "At line no: " << lines << " Undeclared function: " << $1->get_name() << endl << endl;
			outerror << "At line no: " << lines << " Undeclared function: " << $1->get_name() << endl << endl;
			error_count++;
			$$->set_data_type("error");
		}
		else if (!func->is_function())
		{
			outlog << "At line no: " << lines << " " << $1->get_name() << " is not a function" << endl << endl;
			outerror << "At line no: " << lines << " " << $1->get_name() << " is not a function" << endl << endl;
			error_count++;
			$$->set_data_type("error");
		}
		else
		{
			vector<string> expected_types = func->get_param_types();
			vector<string> arg_types = $3->get_argument_types();

			if (expected_types.size() != arg_types.size())
			{
				outlog << "At line no: " << lines << " Inconsistencies in number of arguments in function call: " << $1->get_name() << endl << endl;
				outerror << "At line no: " << lines << " Inconsistencies in number of arguments in function call: " << $1->get_name() << endl << endl;
				error_count++;
			}
			else
			{
				for(size_t i = 0; i < expected_types.size(); i++)
				{
					if (expected_types[i] != arg_types[i] && arg_types[i] != "error" && expected_types[i] != "error")
					{
						outlog << "At line no: " << lines << " argument " << (i+1) << " type mismatch in function call: " << $1->get_name() << endl << endl;
						outerror << "At line no: " << lines << " argument " << (i+1) << " type mismatch in function call: " << $1->get_name() << endl << endl;
						error_count++;
					}
				}
			}

			$$->set_data_type(func->get_return_type());
		}
	}
	| LPAREN expression RPAREN
	{
	   	outlog<<"At line no: "<<lines<<" factor : LPAREN expression RPAREN "<<endl<<endl;
		outlog<<"("<<$2->get_name()<<")"<<endl<<endl;

		$$ = new symbol_info("("+$2->get_name()+")","fctr");
		$$->set_data_type($2->get_data_type());
	}
	| CONST_INT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_INT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type("int");
	}
	| CONST_FLOAT
	{
	    outlog<<"At line no: "<<lines<<" factor : CONST_FLOAT "<<endl<<endl;
		outlog<<$1->get_name()<<endl<<endl;

		$$ = new symbol_info($1->get_name(),"fctr");
		$$->set_data_type("float");
	}
	| variable INCOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable INCOP "<<endl<<endl;
		outlog<<$1->get_name()<<"++"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"++","fctr");
		$$->set_data_type($1->get_data_type());
	}
	| variable DECOP
	{
	    outlog<<"At line no: "<<lines<<" factor : variable DECOP "<<endl<<endl;
		outlog<<$1->get_name()<<"--"<<endl<<endl;

		$$ = new symbol_info($1->get_name()+"--","fctr");
		$$->set_data_type($1->get_data_type());
	}
	;

argument_list : arguments
			  {
					outlog<<"At line no: "<<lines<<" argument_list : arguments "<<endl<<endl;
					outlog<<$1->get_name()<<endl<<endl;

					$$ = new symbol_info($1->get_name(),"arg_list");
			  		$$->set_argument_types($1->get_argument_types());
			  }
			  |
			  {
					outlog<<"At line no: "<<lines<<" argument_list :  "<<endl<<endl;
					outlog<<""<<endl<<endl;

					$$ = new symbol_info("","arg_list");
					$$->set_argument_types(vector<string>());
			  }
			  ;

arguments : arguments COMMA logic_expression
		  {
				outlog<<"At line no: "<<lines<<" arguments : arguments COMMA logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<","<<$3->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name()+","+$3->get_name(),"arg");

				vector<string> arg_types = $1->get_argument_types();
				arg_types.push_back($3->get_data_type());
				$$->set_argument_types(arg_types);
		  }
	      | logic_expression
	      {
				outlog<<"At line no: "<<lines<<" arguments : logic_expression "<<endl<<endl;
				outlog<<$1->get_name()<<endl<<endl;

				$$ = new symbol_info($1->get_name(),"arg");

				vector<string> arg_types;
				arg_types.push_back($1->get_data_type());
				$$->set_argument_types(arg_types);
		  }
	      ;

%%

int main(int argc, char *argv[])
{
	if(argc != 2)
	{
		cout<<"Please input file name"<<endl;
		return 0;
	}
	yyin = fopen(argv[1], "r");
	outlog.open("22201080_log.txt", ios::trunc);
	outerror.open("22201080_error.txt", ios::trunc);

	if(yyin == NULL)
	{
		cout<<"Couldn't open file"<<endl;
		return 0;
	}

	table = new symbol_table(10);

	table->enter_scope(outlog);

	yyparse();

	outlog<<endl<<"Total lines: "<<lines<<endl;
	outlog << "Total errors: " << error_count << endl;

	outerror << "Total errors: " << error_count << endl;

	delete table;

	outlog.close();
	outerror.close();
	fclose(yyin);

	return 0;
}
