#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <string>
#include <vector>
#include <sstream>
using namespace std;

class ASTNode; // forward declaration (defined in ast.h)

// Holds information for one parameter of a function
struct ParamInfo {
    string type;
    string name;
    ParamInfo(string t = "", string n = "") : type(t), name(n) {}
};

// Represents a symbol (identifier) stored in the scope table,
// and also doubles as the semantic value ($$) attached to every
// grammar symbol so that AST nodes can be passed up the parse tree.
class ExprNode; // forward declaration (defined in ast.h)

class SymbolInfo {
private:
    string name;
    string token_type;      // e.g. ID, CONST_INT ...
    string data_type;       // int / float / void
    string symbol_kind;     // "Variable", "Array", "Function Declaration", "Function Definition"
    bool is_array;
    int array_size;
    bool is_function;
    bool is_defined;        // for function: declared vs defined
    vector<ParamInfo> params;

    ASTNode* ast_node;      // AST node built for this grammar symbol
    string var_type;        // convenience: the C type carried on an expression
    vector<ExprNode*> args; // used while collecting function-call arguments

    SymbolInfo* next;       // for chaining inside a scope table bucket

public:
    SymbolInfo(string name = "", string token_type = "")
        : name(name), token_type(token_type), data_type(""), symbol_kind("Variable"),
          is_array(false), array_size(0), is_function(false), is_defined(false),
          ast_node(nullptr), var_type(""), next(nullptr) {}

    string get_name() const { return name; }
    void set_name(const string& n) { name = n; }

    string get_token_type() const { return token_type; }
    void set_token_type(const string& t) { token_type = t; }

    string get_data_type() const { return data_type; }
    void set_data_type(const string& t) { data_type = t; }

    string get_symbol_kind() const { return symbol_kind; }
    void set_symbol_kind(const string& k) { symbol_kind = k; }

    bool get_is_array() const { return is_array; }
    void set_is_array(bool b) { is_array = b; }

    int get_array_size() const { return array_size; }
    void set_array_size(int s) { array_size = s; }

    bool get_is_function() const { return is_function; }
    void set_is_function(bool b) { is_function = b; }

    bool get_is_defined() const { return is_defined; }
    void set_is_defined(bool b) { is_defined = b; }

    vector<ParamInfo>& get_params() { return params; }
    void add_param(const string& type, const string& name) { params.push_back(ParamInfo(type, name)); }

    ASTNode* get_ast_node() const { return ast_node; }
    void set_ast_node(ASTNode* node) { ast_node = node; }

    string getvartype() const { return var_type; }
    void setvartype(const string& t) { var_type = t; }

    void add_arg(ExprNode* e) { args.push_back(e); }
    vector<ExprNode*>& get_args() { return args; }

    SymbolInfo* get_next() const { return next; }
    void set_next(SymbolInfo* n) { next = n; }

    // Builds a human readable "param details" string, e.g. "int a, float b"
    string param_details_string() const {
        ostringstream oss;
        for (size_t i = 0; i < params.size(); i++) {
            if (i) oss << ", ";
            oss << params[i].type;
            if (!params[i].name.empty()) oss << " " << params[i].name;
        }
        return oss.str();
    }

    // Pretty print of this symbol for log.txt scope table dumps
    string to_string_full() const {
        ostringstream oss;
        oss << "< " << name << " : " << token_type << " >\n";
        if (is_function) {
            oss << (is_defined ? "Function Definition" : "Function Declaration") << "\n";
            oss << "Return Type: " << data_type << "\n";
            oss << "Number of Parameters: " << params.size() << "\n";
            oss << "Parameter Details: " << param_details_string() << "\n";
        } else if (is_array) {
            oss << "Array\n";
            oss << "Type: " << data_type << "\n";
            oss << "Size: " << array_size << "\n";
        } else {
            oss << "Variable\n";
            oss << "Type: " << data_type << "\n";
        }
        return oss.str();
    }
};

#endif
