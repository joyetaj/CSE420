#ifndef SCOPE_TABLE_H
#define SCOPE_TABLE_H

#include "symbol_info.h"
#include <vector>
#include <list>
#include <string>
#include <fstream>
using namespace std;

class scope_table
{
private:
    int bucket_count;
    int unique_id;
    scope_table *parent_scope = NULL;
    vector<list<symbol_info *>> table;

    // Sum of the ASCII codes of the characters, reduced modulo the
    // bucket count. Simple and deterministic.
    int hash_function(string name)
    {
        unsigned long sum = 0;
        for (int i = 0; i < (int)name.length(); i++)
        {
            sum += (unsigned char)name[i];
        }
        return sum % bucket_count;
    }

public:
    scope_table();
    scope_table(int bucket_count, int unique_id, scope_table *parent_scope);
    scope_table *get_parent_scope();
    int get_unique_id();
    symbol_info *lookup_in_scope(symbol_info *symbol);
    bool insert_in_scope(symbol_info *symbol);
    bool delete_from_scope(symbol_info *symbol);
    void print_scope_table(ofstream &outlog);
    ~scope_table();
};

scope_table::scope_table()
{
    this->bucket_count = 10;
    this->unique_id = 0;
    this->parent_scope = NULL;
    table.resize(bucket_count);
}

scope_table::scope_table(int bucket_count, int unique_id, scope_table *parent_scope)
{
    this->bucket_count = bucket_count;
    this->unique_id = unique_id;
    this->parent_scope = parent_scope;
    table.resize(bucket_count);
}

scope_table *scope_table::get_parent_scope()
{
    return parent_scope;
}

int scope_table::get_unique_id()
{
    return unique_id;
}

symbol_info *scope_table::lookup_in_scope(symbol_info *symbol)
{
    if (symbol == NULL)
    {
        return NULL;
    }

    int idx = hash_function(symbol->get_name());

    for (auto it = table[idx].begin(); it != table[idx].end(); ++it)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            return *it;
        }
    }
    return NULL;
}

bool scope_table::insert_in_scope(symbol_info *symbol)
{
    if (symbol == NULL)
    {
        return false;
    }

    if (lookup_in_scope(symbol) != NULL)
    {
        return false;
    }

    int idx = hash_function(symbol->get_name());
    table[idx].push_back(symbol);

    return true;
}

bool scope_table::delete_from_scope(symbol_info *symbol)
{
    if (symbol == NULL)
    {
        return false;
    }

    int idx = hash_function(symbol->get_name());
    for (auto it = table[idx].begin(); it != table[idx].end(); ++it)
    {
        if ((*it)->get_name() == symbol->get_name())
        {
            delete *it;
            table[idx].erase(it);
            return true;
        }
    }
    return false;
}

void scope_table::print_scope_table(ofstream &outlog)
{
    outlog << "ScopeTable # " << unique_id << endl;

    for (int i = 0; i < bucket_count; i++)
    {
        if (table[i].empty()) continue;

        outlog << i << " --> " << endl;

        for (auto symbol : table[i])
        {
            outlog << "< " << symbol->get_name() << " : ID >" << endl;

            if (symbol->is_function())
            {
                outlog << "Function Definition" << endl;
                outlog << "Return Type: " << symbol->get_return_type() << endl;
                outlog << "Number of Parameters: " << symbol->get_param_count() << endl;
                outlog << "Parameter Details: ";

                vector<string> param_types = symbol->get_param_types();
                vector<string> param_names = symbol->get_param_names();

                for (size_t j = 0; j < param_types.size(); j++)
                {
                    if (j > 0) outlog << ", ";
                    outlog << param_types[j];
                    if (j < param_names.size() && !param_names[j].empty())
                    {
                        outlog << " " << param_names[j];
                    }
                }
                outlog << endl;
                // a function entry is NOT followed by a blank line
            }
            else if (symbol->is_array())
            {
                outlog << "Array" << endl;
                outlog << "Type: " << symbol->get_data_type() << endl;
                outlog << "Size: " << symbol->get_array_size() << endl;
                outlog << endl; // variables/arrays ARE followed by a blank line
            }
            else
            {
                outlog << "Variable" << endl;
                outlog << "Type: " << symbol->get_data_type() << endl;
                outlog << endl;
            }
        }
    }
    // exactly one blank line after the whole table's buckets are printed
    outlog << endl;
}

scope_table::~scope_table()
{
    for (int i = 0; i < bucket_count; i++)
    {
        for (auto symbol : table[i])
        {
            delete symbol;
        }
        table[i].clear();
    }
    table.clear();
}

#endif
