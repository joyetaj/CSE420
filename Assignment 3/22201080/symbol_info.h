#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <bits/stdc++.h>
using namespace std;

class symbol_info
{
private:
    string name;
    string type;
    string symbol_type;
    string data_type;
    string array_size;
    string return_type;
    vector<string> param_types;
    vector<string> param_names;
    vector<string> argument_types;

public:
    symbol_info(string name, string type)
    {
        this->name = name;
        this->type = type;
        this->symbol_type = "variable";
        this->data_type = type;
        this->array_size = "";
        this->return_type = "";
    }

    string get_name()
    {
        return name;
    }

    string get_type()
    {
        return type;
    }

    string get_symbol_type()
    {
        return symbol_type;
    }

    string get_data_type()
    {
        return data_type;
    }

    string get_array_size()
    {
        return array_size;
    }

    string get_return_type()
    {
        return return_type;
    }

    vector<string> get_param_types()
    {
        return param_types;
    }

    vector<string> get_param_names()
    {
        return param_names;
    }

    int get_param_count()
    {
        return param_types.size();
    }

    vector<string> get_argument_types()
    {
        return argument_types;
    }

    void set_name(string name)
    {
        this->name = name;
    }

    void set_type(string type)
    {
        this->type = type;
    }

    void set_data_type(string data_type)
    {
        this->data_type = data_type;
    }

    void set_argument_types(vector<string> types)
    {
        this->argument_types = types;
    }

    void add_argument_type(string type)
    {
        argument_types.push_back(type);
    }

    void set_variable_info(string data_type)
    {
        this->data_type = data_type;
        this->symbol_type = "variable";
        this->array_size = "";
        this->return_type = "";

        param_types.clear();
        param_names.clear();
    }

    void set_array_info(string data_type, string size)
    {
        this->data_type = data_type;
        this->array_size = size;
        this->symbol_type = "array";
        this->return_type = "";

        param_types.clear();
        param_names.clear();
    }

    void set_function_info(string return_type, vector<pair<string, string>> params)
    {
        this->return_type = return_type;
        this->symbol_type = "function";

        this->param_types.clear();
        this->param_names.clear();

        for (auto &p : params)
        {
            param_types.push_back(p.first);
            param_names.push_back(p.second);
        }

        this->data_type = "";
        this->array_size = "";
    }

    void add_parameter(string param_type, string param_name = "")
    {
        param_types.push_back(param_type);
        param_names.push_back(param_name);
    }

    void set_parameters(vector<string> types, vector<string> names)
    {
        this->param_types = types;
        this->param_names = names;
    }

    bool is_variable()
    {
        return symbol_type == "variable";
    }

    bool is_array()
    {
        return symbol_type == "array";
    }

    bool is_function()
    {
        return symbol_type == "function";
    }

    ~symbol_info()
    {
        param_types.clear();
        param_names.clear();
        argument_types.clear();
    }
};

#endif
