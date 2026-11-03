#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include <iostream>
#include <sstream>
#include <string>
#include "symbol_info.h"
using namespace std;

class ScopeTable {
private:
    int bucket_count;
    SymbolInfo** buckets;
    int id;
    ScopeTable* parent;

    unsigned int hash_function(const string& key) const {
        unsigned int h = 0;
        for (char c : key) h = h * 31 + (unsigned char)c;
        return h % bucket_count;
    }

public:
    ScopeTable(int n_buckets, int id, ScopeTable* parent)
        : bucket_count(n_buckets), id(id), parent(parent) {
        buckets = new SymbolInfo*[bucket_count];
        for (int i = 0; i < bucket_count; i++) buckets[i] = nullptr;
    }

    ~ScopeTable() {
        for (int i = 0; i < bucket_count; i++) {
            SymbolInfo* cur = buckets[i];
            while (cur) {
                SymbolInfo* nxt = cur->get_next();
                delete cur;
                cur = nxt;
            }
        }
        delete[] buckets;
    }

    int get_id() const { return id; }
    ScopeTable* get_parent() const { return parent; }

    // Inserts a symbol into this scope only. Returns false if already present in this scope.
    bool insert(SymbolInfo* symbol) {
        if (lookup_current(symbol->get_name())) return false;
        unsigned int idx = hash_function(symbol->get_name());
        symbol->set_next(buckets[idx]);
        buckets[idx] = symbol;
        return true;
    }

    // Looks up only within this scope (no parent chasing)
    SymbolInfo* lookup_current(const string& name) const {
        unsigned int idx = hash_function(name);
        SymbolInfo* cur = buckets[idx];
        while (cur) {
            if (cur->get_name() == name) return cur;
            cur = cur->get_next();
        }
        return nullptr;
    }

    // Dumps this scope's contents in the log format used by the course labs
    string print_scope() const {
        ostringstream oss;
        oss << "\nScopeTable # " << id << "\n";
        for (int i = 0; i < bucket_count; i++) {
            SymbolInfo* cur = buckets[i];
            if (!cur) continue;
            oss << i << " --> \n";
            while (cur) {
                oss << cur->to_string_full();
                cur = cur->get_next();
            }
            oss << "\n";
        }
        return oss.str();
    }
};

#endif
