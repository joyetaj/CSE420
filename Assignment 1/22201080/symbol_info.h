#ifndef SYMBOL_INFO_H
#define SYMBOL_INFO_H

#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include <stdarg.h>

/* Every token and every grammar rule builds one of these.
 * name  -> the lexeme (for a token) or the rebuilt source text (for a rule)
 * type  -> just a label, e.g. "ID", "statement", used only for our own reference
 */
typedef struct SymbolInfo {
    char *name;
    char *type;
} SymbolInfo;

static inline SymbolInfo *newSymbolInfo(const char *name, const char *type) {
    SymbolInfo *s = (SymbolInfo *) malloc(sizeof(SymbolInfo));
    s->name = strdup(name ? name : "");
    s->type = strdup(type ? type : "");
    return s;
}

/* Same as above but builds the name with printf-style formatting, so
 * we can glue together children's names when a rule reduces, e.g.
 *   newSymbolInfof("declaration_list", "%s,%s", $1->name, $3->name)
 */
static inline SymbolInfo *newSymbolInfof(const char *type, const char *fmt, ...) {
    char buffer[2048];
    va_list args;
    va_start(args, fmt);
    vsnprintf(buffer, sizeof(buffer), fmt, args);
    va_end(args);
    return newSymbolInfo(buffer, type);
}

#endif
