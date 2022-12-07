#pragma once

//header.h

#include <stdio.h>
#include <stdbool.h>
#include <string.h>

enum notice_type 
{
	ERROR, 
	WARNING, 
	DEBUG
};

enum noh_type
{
	PROGRAM,
	ASSIGN,
	SUM,
	MINUS,
	MULTI,
	DIVIDE,
	PRINT,
	POW,
	GENERIC,
	STMT,
	FLOAT,
	IDENT,
	INTEGER,
	PAREN,
	WHILE,
	OR,
	AND,
	GREATER,
	LITTLE,
	EQUAL,
	GTEQUAL,
	LTEQUAL,
	NOTEQUAL,
	IF,
	ELSE
};

static const char *noh_type_names[] = {
	"program", "=", "+", "-", "*", "/", "show", "^", "generic", "stmt", "float", "identificador", "int", "()", "loop", "or", "and", ">", "<", "==", ">=", "<=", "!=", "?", "$"};

typedef struct {
	int intv;
	double dblv;

	char *ident;
} token_args;

typedef struct {
	char *nome;
	int token;
	bool exists;
} simbolo;

static int error_count = 0;
static int simbolo_qtd = 0;
static simbolo tsimbolos[100];
simbolo *simbolo_novo(char *nome, int token);
bool simbolo_existe(char *nome);
void show_symbols();

struct noh {
	int id, childcount, line;
	enum noh_type type;

	int intv;
	double dblv;

	char *name;

	struct noh *children[1];
};

typedef struct noh noh;

typedef void (*visitor_action)(noh **root, noh *no);

void show_message(int mode, int line);
void show_error_count();

void check_declared_vars(noh **root, noh *no);
void check_division_by_zero(noh **root, noh *no);
void check_negative_subtraction(noh **root, noh *no);

void file_format_verification(char *file);
void unnecessary_arguments_verification(int argc, char *args[]);

void visitor_leaf_first(noh **root, visitor_action act);

noh *create_noh(enum noh_type nt, int children, int line);

char * get_label(noh *root);

void print(noh *root);
void print_rec(FILE *f, noh *root);