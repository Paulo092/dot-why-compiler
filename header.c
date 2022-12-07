//header.h

#include <stdlib.h>
#include <stdio.h>
#include <string.h>

#include "header.h"

// -+-+ CORE +-+-

noh *create_noh(enum noh_type nt, int children, int line)
{
	static int IDCOUNT = 0;
	noh *newn = (noh *)calloc(1, sizeof(noh) + sizeof(noh *) * (children - 1));

	newn->type = nt;
	newn->childcount = children;
	newn->id = IDCOUNT++;
	newn->line = line;

	return newn;
}

simbolo *simbolo_novo(char *nome, int token)
{
	tsimbolos[simbolo_qtd].nome = nome;
	tsimbolos[simbolo_qtd].token = token;
	simbolo *result = &tsimbolos[simbolo_qtd];
	simbolo_qtd++;
	return result;
}

void visitor_leaf_first(noh **root, visitor_action act)
{
	noh *r = *root;

	for (int i = 0; i < r->childcount; i++)
	{
		visitor_leaf_first(&r->children[i], act);
		if (act)
			act(root, r->children[i]);
	}
}

// -+-+ CORE +-+-

// -+-+ UTILITY +-+-

bool simbolo_existe(char *nome)
{
	// busca linear, nao eficiente
	for (int i = 0; i < simbolo_qtd; i++)
	{
		if (strcmp(tsimbolos[i].nome, nome) == 0)
			return true;
	}
	return false;
}

void show_message(int mode, int line)
{
	switch (mode)
	{
	case ERROR:
		printf("\033[0;31m[ERROR]");
		break;

	case WARNING:
		printf("\033[0;33m[WARNING]");
		break;

	case DEBUG:
		printf("\n\033[0;34m[DEBUG]");
		break;

	default:
		break;
	}

	if (line != -1)
		printf("\033[0;35m(LINE %d):", line);
	printf("\033[0m ");
}

char *get_label(noh *noh)
{
	static char aux[100];
	switch (noh->type)
	{
	case INTEGER:
		sprintf(aux, "%d", noh->intv);
		return aux;
	case FLOAT:
		sprintf(aux, "%f", noh->dblv);
		return aux;
	case IDENT:
		return noh->name;
	default:
		// return noh_type_names[noh->type];
		return (char *)noh_type_names[noh->type];
	}
}

void print(noh *root)
{
	FILE *f = fopen("output.dot", "w");

	fprintf(f, "graph {\n");
	print_rec(f, root);
	fprintf(f, "}");

	fclose(f);
}

void print_rec(FILE *f, noh *root)
{
	fprintf(f, "\tN%d[label=\"%s\"];\n", root->id, get_label(root));
	for (int i = 0; i < root->childcount; i++)
	{
		print_rec(f, root->children[i]);
		fprintf(f, "\tN%d -- N%d;\n", root->id, root->children[i]->id);
	}
}

int search_symbol(char *nome)
{
	// busca linear, nao eficiente
	for (int i = 0; i < simbolo_qtd; i++)
	{
		if (strcmp(tsimbolos[i].nome, nome) == 0)
		{
			return i;
		}
	}

	return -1;
}

void print_no_minus_label(char *label)
{
	for (size_t i = 1; i < strlen(label); i++)
		printf("%c", label[i]);
}

// -+-+ UTILITY +-+-

// -+-+ SEMANTIC ERRORS +-+-

void check_declared_vars(noh **root, noh *no) {
	noh *nr = *root;

	if (no->type == ASSIGN)
	{
		int s = search_symbol(no->children[0]->name);
		if (s != -1)
			tsimbolos[s].exists = true;
	}
	else if (no->type == IDENT)
	{
		if (nr->type == ASSIGN && no == nr->children[0])
			return;

		int s = search_symbol(no->name);
		if (s == -1 || !tsimbolos[s].exists) {
			show_message(ERROR, no->line);
			printf("Symbol \"%s\" used but not declared.\n", no->name);

			error_count++;
		}
	}
}

void check_division_by_zero(noh **root, noh *no)
{
	noh *nr = *root;

	if (no->type == DIVIDE && ((no->children[1]->type == INTEGER && no->children[1]->intv == 0) || (no->children[1]->type == FLOAT && no->children[1]->dblv == 0)))
	{
		show_message(ERROR, no->children[1]->line);
		printf("Division by zero in: \"%s/0\".\n", get_label(no->children[0]));

		error_count++;
	}
}

void check_negative_subtraction(noh **root, noh *no)
{
	if (no->type == MINUS && (no->children[1]->intv < 0 || no->children[1]->dblv < 0))
	{
		char lvalue[100], rvalue[100];
		strcpy(lvalue, get_label(no->children[0]));
		strcpy(rvalue, get_label(no->children[1]));

		show_message(ERROR, no->children[1]->line);
		printf("Subtraction over negative number in: \"%s - %s\". ", lvalue, rvalue);
		printf("Should be: \"%s + ", lvalue);
		print_no_minus_label(rvalue);
		printf("\".\n");

		error_count++;
	}
}

// -+-+ SEMANTIC ERRORS +-+-

// -+-+ DEBUG +-+-

void show_error_count()
{
	show_message(DEBUG, -1);
	printf("%d semantic errors founded.\n", error_count);
}

void show_symbols()
{
	show_message(DEBUG, -1);
	printf("Symbols: [");

	for (int i = 0; i < simbolo_qtd; i++)
	{
		printf("%s%s", tsimbolos[i].nome, i < simbolo_qtd - 1 ? ", " : "");
	}

	printf("].\n\n");
}

// -+-+ DEBUG +-+-

// -+-+ LEXICAL VERIFICATIONS +-+-

void file_format_verification(char *file)
{
	char *great_extension = ".why";
	int index = strlen(file) - 1;

	for (int i = strlen(great_extension) - 1; i > 0; i--)
	{
		if (file[index--] != great_extension[i])
		{
			show_message(WARNING, -1);
			printf("Bad file format (not .why).\n");
			return;
		}
	}
}

void unnecessary_arguments_verification(int argc, char *args[])
{
	if (argc > 2)
	{
		show_message(WARNING, -1);
		printf("Unnecessary arguments: [ ");

		for (int i = 2; i < argc; i++)
			printf("%s%s", args[i], i < argc - 1 ? ", " : "");

		printf(" ] will be ignored.\n");
	}
}

// -+-+ LEXICAL VERIFICATIONS +-+-