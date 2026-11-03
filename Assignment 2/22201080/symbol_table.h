#ifndef SYMBOL_TABLE_H
#define SYMBOL_TABLE_H

#include "scope_table.h"

class symbol_table
{
private:
    scope_table *current_scope;
    int bucket_count;
    int current_scope_id;

public:
    symbol_table(int bucket_count);
    ~symbol_table();

    void enter_scope(ofstream &outlog);
    void exit_scope(ofstream &outlog);
    bool insert(symbol_info *symbol);
    symbol_info *lookup(symbol_info *symbol);
    void print_current_scope(ofstream &outlog);
    void print_all_scopes(ofstream &outlog);
};

symbol_table::symbol_table(int bucket_count)
{
    this->bucket_count = bucket_count;
    this->current_scope_id = 0;
    this->current_scope = NULL;
}

symbol_table::~symbol_table()
{
    while (current_scope != NULL)
    {
        scope_table *temp = current_scope;
        current_scope = current_scope->get_parent_scope();
        delete temp;
    }
}

void symbol_table::enter_scope(ofstream &outlog)
{
    current_scope_id++;

    scope_table *new_scope = new scope_table(bucket_count, current_scope_id, current_scope);
    current_scope = new_scope;

    outlog << "New ScopeTable with ID " << current_scope_id << " created" << endl;
    outlog << endl;
}

void symbol_table::exit_scope(ofstream &outlog)
{
    if (current_scope == NULL)
    {
        outlog << "Error: No scope to exit" << endl;
        return;
    }

    int exiting_id = current_scope->get_unique_id();
    scope_table *parent = current_scope->get_parent_scope();

    delete current_scope;
    current_scope = parent;

    outlog << "Scopetable with ID " << exiting_id << " removed" << endl;
    outlog << endl;
}

bool symbol_table::insert(symbol_info *symbol)
{
    if (current_scope == NULL)
    {
        return false;
    }

    return current_scope->insert_in_scope(symbol);
}

symbol_info *symbol_table::lookup(symbol_info *symbol)
{
    if (symbol == NULL || current_scope == NULL)
    {
        return NULL;
    }

    scope_table *temp = current_scope;

    while (temp != NULL)
    {
        symbol_info *found = temp->lookup_in_scope(symbol);

        if (found != NULL)
        {
            return found;
        }

        temp = temp->get_parent_scope();
    }

    return NULL;
}

void symbol_table::print_current_scope(ofstream &outlog)
{
    if (current_scope == NULL)
    {
        outlog << "Error: No current scope" << endl;
        return;
    }

    current_scope->print_scope_table(outlog);
}

void symbol_table::print_all_scopes(ofstream &outlog)
{
    outlog << "################################" << endl;
    outlog << endl;

    scope_table *temp = current_scope;

    while (temp != NULL)
    {
        temp->print_scope_table(outlog);
        temp = temp->get_parent_scope();
    }

    outlog << "################################" << endl;
    outlog << endl;
}

#endif
