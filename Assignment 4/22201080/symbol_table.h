#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include <iostream>
#include <sstream>
#include <string>
#include "scope_table.h"
using namespace std;

extern FILE* logOut; // defined in the .y file

class SymbolTable {
private:
    int bucket_count;
    ScopeTable* current_scope;
    int next_id;

    void log_msg(const string& s) {
        if (logOut) fprintf(logOut, "%s", s.c_str());
    }

public:
    SymbolTable(int n_buckets = 10) : bucket_count(n_buckets), current_scope(nullptr), next_id(1) {
        enter_scope();
    }

    void enter_scope() {
        ScopeTable* parent = current_scope;
        current_scope = new ScopeTable(bucket_count, next_id, parent);
        log_msg("New ScopeTable with ID " + std::to_string(next_id) + " created\n\n");
        next_id++;
    }

    void exit_scope() {
        if (!current_scope) return;
        ScopeTable* parent = current_scope->get_parent();
        log_msg("\nScopetable with ID " + std::to_string(current_scope->get_id()) + " removed\n\n");
        delete current_scope;
        current_scope = parent;
    }

    bool insert(SymbolInfo* symbol) {
        return current_scope->insert(symbol);
    }

    // Looks up starting at the current scope, chasing parents.
    SymbolInfo* lookup(const string& name) {
        ScopeTable* scope = current_scope;
        while (scope) {
            SymbolInfo* found = scope->lookup_current(name);
            if (found) return found;
            scope = scope->get_parent();
        }
        return nullptr;
    }

    SymbolInfo* lookup_current_scope(const string& name) {
        return current_scope->lookup_current(name);
    }

    ScopeTable* get_current_scope() const { return current_scope; }

    string print_current_scope() const {
        return current_scope ? current_scope->print_scope() : "";
    }

    // Dumps every scope from current up to the outermost (global) scope
    string print_all_scopes() const {
        ostringstream oss;
        oss << "\n################################\n";
        ScopeTable* scope = current_scope;
        while (scope) {
            oss << scope->print_scope();
            scope = scope->get_parent();
        }
        oss << "################################\n";
        return oss.str();
    }
};

#endif
