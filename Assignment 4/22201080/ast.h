#ifndef AST_H
#define AST_H

#include <string>
#include <vector>
#include <cstdio>
#include "three_addr_code.h"
using namespace std;

extern FILE* logOut; // used to log AST construction info

static inline void ast_indent(FILE* out, int depth) {
    for (int i = 0; i < depth; i++) fprintf(out, "  ");
}

// =========================================================================
// Base class
// =========================================================================
class ASTNode {
public:
    int line_no;
    ASTNode(int line = 0) : line_no(line) {}
    virtual ~ASTNode() {}

    // Generates three address code for this node and returns the name of
    // the "place" that holds the value of this node (a temp/var name),
    // or "" for statement nodes that do not produce a value.
    virtual string generate_code() = 0;

    // Short description used while logging the AST in log.txt
    virtual string describe() const { return "ASTNode"; }

    // Recursively dumps this node (and its children) into log.txt so the
    // constructed AST is visible, as required by the assignment.
    virtual void print_tree(FILE* out, int depth) {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
    }
};

// =========================================================================
// Expression nodes
// =========================================================================
class ExprNode : public ASTNode {
public:
    string type; // int / float / void
    ExprNode(int line = 0) : ASTNode(line) {}
};

class VarNode : public ExprNode {
public:
    string name;
    ExprNode* index; // non-null for array access a[i]
    VarNode(const string& n, const string& t = "int", ExprNode* idx = nullptr, int line = 0)
        : ExprNode(line), name(n), index(idx) { type = t; }

    string generate_code() override {
        if (index) {
            string idx_place = index->generate_code();
            string temp = g_temp_mgr.new_temp();
            g_code.emit(temp + " = " + name + "[" + idx_place + "]");
            return temp;
        }
        return name;
    }

    string describe() const override {
        return index ? ("VarNode(" + name + "[])") : ("VarNode(" + name + ")");
    }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        if (index) index->print_tree(out, depth + 1);
    }
};

class ConstNode : public ExprNode {
public:
    string value;
    ConstNode(const string& v, const string& t = "int", int line = 0) : ExprNode(line), value(v) { type = t; }

    string generate_code() override {
        string temp = g_temp_mgr.new_temp();
        g_code.emit(temp + " = " + value);
        return temp;
    }

    string describe() const override { return "ConstNode(" + value + ")"; }
};

class BinaryOpNode : public ExprNode {
public:
    string op;
    ExprNode* left;
    ExprNode* right;
    BinaryOpNode(const string& op, ExprNode* l, ExprNode* r, const string& t = "int", int line = 0)
        : ExprNode(line), op(op), left(l), right(r) { type = t; }

    string generate_code() override {
        string lp = left ? left->generate_code() : "";
        string rp = right ? right->generate_code() : "";
        string temp = g_temp_mgr.new_temp();
        g_code.emit(temp + " = " + lp + " " + op + " " + rp);
        return temp;
    }

    string describe() const override { return "BinaryOpNode(" + op + ")"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        if (left) left->print_tree(out, depth + 1);
        if (right) right->print_tree(out, depth + 1);
    }
};

class UnaryOpNode : public ExprNode {
public:
    string op;
    ExprNode* operand;
    UnaryOpNode(const string& op, ExprNode* operand, const string& t = "int", int line = 0)
        : ExprNode(line), op(op), operand(operand) { type = t; }

    string generate_code() override {
        string p = operand ? operand->generate_code() : "";
        string temp = g_temp_mgr.new_temp();
        g_code.emit(temp + " = " + op + p);
        return temp;
    }

    string describe() const override { return "UnaryOpNode(" + op + ")"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        if (operand) operand->print_tree(out, depth + 1);
    }
};

// Handles postfix ++ / -- on a variable (used by our C subset's factor rule)
class IncDecNode : public ExprNode {
public:
    string op;      // "++" or "--"
    VarNode* var;
    IncDecNode(const string& op, VarNode* v, int line = 0) : ExprNode(line), op(op), var(v) { type = "int"; }

    string generate_code() override {
        string place = var->name; // simple (non-array) inc/dec assumed
        string temp = g_temp_mgr.new_temp();
        g_code.emit(temp + " = " + std::to_string(1));
        string op2 = (op == "++") ? "+" : "-";
        string temp2 = g_temp_mgr.new_temp();
        g_code.emit(temp2 + " = " + place + " " + op2 + " " + temp);
        g_code.emit(place + " = " + temp2);
        return place;
    }

    string describe() const override { return "IncDecNode(" + op + ")"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        if (var) var->print_tree(out, depth + 1);
    }
};

class AssignNode : public ExprNode {
public:
    VarNode* target;
    ExprNode* value;
    AssignNode(VarNode* target, ExprNode* value, const string& t = "int", int line = 0)
        : ExprNode(line), target(target), value(value) { type = t; }

    string generate_code() override {
        string rhs = value ? value->generate_code() : "";
        if (target->index) {
            string idx_place = target->index->generate_code();
            g_code.emit(target->name + "[" + idx_place + "] = " + rhs);
        } else {
            g_code.emit(target->name + " = " + rhs);
        }
        return target->name;
    }

    string describe() const override { return "AssignNode(" + target->name + ")"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        target->print_tree(out, depth + 1);
        if (value) value->print_tree(out, depth + 1);
    }
};

class FuncCallNode : public ExprNode {
public:
    string func_name;
    vector<ExprNode*> args;
    FuncCallNode(const string& name, const string& t = "int", int line = 0)
        : ExprNode(line), func_name(name) { type = t; }

    void add_arg(ExprNode* arg) { args.push_back(arg); }

    string generate_code() override {
        vector<string> arg_places;
        for (auto a : args) {
            string p = a->generate_code();
            // Always materialize the argument value into a fresh temp before
            // passing it, so "param" always receives a temp (matches the
            // style used by the reference compiler in the sample outputs).
            string temp = g_temp_mgr.new_temp();
            g_code.emit(temp + " = " + p);
            arg_places.push_back(temp);
        }
        for (auto& p : arg_places) {
            g_code.emit("param " + p);
        }
        string temp = g_temp_mgr.new_temp();
        g_code.emit(temp + " = call " + func_name + ", " + std::to_string(args.size()));
        return temp;
    }

    string describe() const override { return "FuncCallNode(" + func_name + ")"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        for (auto a : args) a->print_tree(out, depth + 1);
    }
};

// =========================================================================
// Statement nodes
// =========================================================================
class StmtNode : public ASTNode {
public:
    StmtNode(int line = 0) : ASTNode(line) {}
};

class ExprStmtNode : public StmtNode {
public:
    ExprNode* expr; // may be null for an empty statement ";"
    ExprStmtNode(ExprNode* e, int line = 0) : StmtNode(line), expr(e) {}

    string generate_code() override {
        if (expr) expr->generate_code();
        return "";
    }

    string describe() const override { return "ExprStmtNode"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        if (expr) expr->print_tree(out, depth + 1);
    }
};

class DeclNode : public StmtNode {
public:
    string var_type;
    string name;
    bool is_array;
    int array_size;
    DeclNode(const string& vtype, const string& n, bool arr = false, int size = 0, int line = 0)
        : StmtNode(line), var_type(vtype), name(n), is_array(arr), array_size(size) {}

    string generate_code() override {
        string comment = "Declaration: " + var_type + " " + name;
        if (is_array) comment += "[" + std::to_string(array_size) + "]";
        g_code.emit_comment(comment);
        return "";
    }

    string describe() const override { return "DeclNode(" + name + ")"; }
};

class BlockNode : public StmtNode {
public:
    vector<StmtNode*> statements;
    BlockNode(int line = 0) : StmtNode(line) {}
    void add_statement(StmtNode* s) { if (s) statements.push_back(s); }

    string generate_code() override {
        for (auto s : statements) s->generate_code();
        return "";
    }

    string describe() const override { return "BlockNode(" + std::to_string(statements.size()) + " stmts)"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        for (auto s : statements) s->print_tree(out, depth + 1);
    }
};

class IfNode : public StmtNode {
public:
    ExprNode* condition;
    StmtNode* then_branch;
    StmtNode* else_branch; // may be null
    IfNode(ExprNode* cond, StmtNode* thenB, StmtNode* elseB = nullptr, int line = 0)
        : StmtNode(line), condition(cond), then_branch(thenB), else_branch(elseB) {}

    string generate_code() override {
        string cond_place = condition->generate_code();
        string Ltrue = g_label_mgr.new_label();
        string Lfalse = g_label_mgr.new_label();
        g_code.emit("if " + cond_place + " goto " + Ltrue);
        g_code.emit("goto " + Lfalse);
        g_code.emit_label(Ltrue);
        if (then_branch) then_branch->generate_code();
        if (else_branch) {
            string Lend = g_label_mgr.new_label();
            g_code.emit("goto " + Lend);
            g_code.emit_label(Lfalse);
            else_branch->generate_code();
            g_code.emit_label(Lend);
        } else {
            g_code.emit_label(Lfalse);
        }
        return "";
    }

    string describe() const override { return "IfNode"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        ast_indent(out, depth + 1); fprintf(out, "Condition:\n");
        condition->print_tree(out, depth + 2);
        ast_indent(out, depth + 1); fprintf(out, "Then:\n");
        if (then_branch) then_branch->print_tree(out, depth + 2);
        if (else_branch) {
            ast_indent(out, depth + 1); fprintf(out, "Else:\n");
            else_branch->print_tree(out, depth + 2);
        }
    }
};

class WhileNode : public StmtNode {
public:
    ExprNode* condition;
    StmtNode* body;
    WhileNode(ExprNode* cond, StmtNode* body, int line = 0) : StmtNode(line), condition(cond), body(body) {}

    string generate_code() override {
        string Lstart = g_label_mgr.new_label();
        string Ltrue = g_label_mgr.new_label();
        string Lend = g_label_mgr.new_label();
        g_code.emit_label(Lstart);
        string cond_place = condition->generate_code();
        g_code.emit("if " + cond_place + " goto " + Ltrue);
        g_code.emit("goto " + Lend);
        g_code.emit_label(Ltrue);
        if (body) body->generate_code();
        g_code.emit("goto " + Lstart);
        g_code.emit_label(Lend);
        return "";
    }

    string describe() const override { return "WhileNode"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        ast_indent(out, depth + 1); fprintf(out, "Condition:\n");
        condition->print_tree(out, depth + 2);
        ast_indent(out, depth + 1); fprintf(out, "Body:\n");
        if (body) body->print_tree(out, depth + 2);
    }
};

class ForNode : public StmtNode {
public:
    ExprNode* init;      // may be null
    ExprNode* condition;  // may be null
    ExprNode* update;    // may be null
    StmtNode* body;
    ForNode(ExprNode* init, ExprNode* cond, ExprNode* upd, StmtNode* body, int line = 0)
        : StmtNode(line), init(init), condition(cond), update(upd), body(body) {}

    string generate_code() override {
        if (init) init->generate_code();
        string Lstart = g_label_mgr.new_label();
        string Ltrue = g_label_mgr.new_label();
        string Lend = g_label_mgr.new_label();
        g_code.emit_label(Lstart);
        if (condition) {
            string cond_place = condition->generate_code();
            g_code.emit("if " + cond_place + " goto " + Ltrue);
            g_code.emit("goto " + Lend);
            g_code.emit_label(Ltrue);
        }
        if (body) body->generate_code();
        if (update) update->generate_code();
        g_code.emit("goto " + Lstart);
        g_code.emit_label(Lend);
        return "";
    }

    string describe() const override { return "ForNode"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        ast_indent(out, depth + 1); fprintf(out, "Init:\n");
        if (init) init->print_tree(out, depth + 2);
        ast_indent(out, depth + 1); fprintf(out, "Condition:\n");
        if (condition) condition->print_tree(out, depth + 2);
        ast_indent(out, depth + 1); fprintf(out, "Update:\n");
        if (update) update->print_tree(out, depth + 2);
        ast_indent(out, depth + 1); fprintf(out, "Body:\n");
        if (body) body->print_tree(out, depth + 2);
    }
};

class ReturnNode : public StmtNode {
public:
    ExprNode* value; // may be null (return; )
    ReturnNode(ExprNode* v, int line = 0) : StmtNode(line), value(v) {}

    string generate_code() override {
        if (value) {
            string place = value->generate_code();
            g_code.emit("return " + place);
        } else {
            g_code.emit("return");
        }
        return "";
    }

    string describe() const override { return "ReturnNode"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s (line %d)\n", describe().c_str(), line_no);
        if (value) value->print_tree(out, depth + 1);
    }
};

// Represents one top level function (declaration or definition)
class FuncNode : public StmtNode {
public:
    string return_type;
    string name;
    vector<ParamInfo> params;
    BlockNode* body; // null for a plain declaration (prototype)
    FuncNode(const string& rt, const string& n, int line = 0)
        : StmtNode(line), return_type(rt), name(n), body(nullptr) {}

    string signature() const {
        string s = return_type + " " + name + "(";
        for (size_t i = 0; i < params.size(); i++) {
            if (i) s += ", ";
            s += params[i].type;
            if (!params[i].name.empty()) s += " " + params[i].name;
        }
        s += ")";
        return s;
    }

    string generate_code() override {
        if (!body) return ""; // prototype only, nothing to generate
        g_code.emit_blank();
        g_code.emit_comment("Function: " + signature());
        for (auto& p : params) {
            string temp = g_temp_mgr.new_temp();
            g_code.emit(temp + " = " + p.name);
        }
        body->generate_code();
        return "";
    }

    string describe() const override { return "FuncNode(" + name + ")"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "FuncNode(%s) (line %d)\n", signature().c_str(), line_no);
        if (body) body->print_tree(out, depth + 1);
    }
};

// Root of the whole AST
class ProgramNode : public ASTNode {
public:
    vector<StmtNode*> units; // top level declarations / function defs
    ProgramNode() : ASTNode(0) {}
    void add_unit(StmtNode* u) { if (u) units.push_back(u); }

    string generate_code() override {
        for (auto u : units) u->generate_code();
        return "";
    }

    string describe() const override { return "ProgramNode(" + std::to_string(units.size()) + " units)"; }

    void print_tree(FILE* out, int depth) override {
        ast_indent(out, depth);
        fprintf(out, "%s\n", describe().c_str());
        for (auto u : units) u->print_tree(out, depth + 1);
    }
};

#endif
