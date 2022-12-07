%{

#include <stdio.h>
#include <stdlib.h>
#include <stdbool.h>
#include <string.h>

#include "header.h"

extern int yylineno;

int yyerror(const char *s);
int yylex (void);

%}

%union {
    struct noh *no;
    token_args args;
}

%define parse.error verbose

%token TOK_PRINT <args> TOK_IDENT TOK_INTEGER TOK_FLOAT TOK_WHILE TOK_AND TOK_OR TOK_IF TOK_ELSE

%start program

%type <no> program stmts stmt atribuicao aritmetica term termp factor logico logterm logfactor while if

%%

program
    : stmts
    {
        noh *program = create_noh(PROGRAM, 1, yylineno);
        program->children[0] = $1;
        
        show_symbols();

        visitor_leaf_first(&program, check_declared_vars);
        visitor_leaf_first(&program, check_division_by_zero);
        visitor_leaf_first(&program, check_negative_subtraction);

        print(program);

        show_error_count();
    }
    ;

stmts
    : stmts stmt 
    { 
        noh *n = $1;
        n = (noh*)realloc(n, sizeof(noh) + sizeof(noh*)*(n->childcount));
        n->children[n->childcount] = $2;
        n->childcount++;
        $$ = n;
    }
    | stmt 
    {  
        int realoc_children_count = $1->childcount;

        $$ = create_noh(STMT, 1, yylineno);
        $$->children[0] = $1;
    }
    ;

stmt
    : atribuicao 
    {
        $$ = $1;
    } 
    | TOK_PRINT aritmetica 
    {
        $$ = create_noh(PRINT, 1, yylineno);
        $$->children[0] = $2;
    }
    | while { $$ = $1; }
    | if    { $$ = $1; }
    ;

atribuicao
    : TOK_IDENT '=' aritmetica 
    {
        if (!simbolo_existe($1.ident)) 
            simbolo_novo($1.ident, TOK_IDENT);

        $$ = create_noh(ASSIGN, 2, yylineno);
        $$->children[0] = create_noh(IDENT, 0, yylineno);
        $$->children[0]->name = $1.ident;
        $$->children[1] = $3;
    }
    ;

aritmetica
    : aritmetica '+' term 
    {
        $$ = create_noh(SUM, 2, yylineno);
        $$->children[0] = $1;
        $$->children[1] = $3;
    }
    | aritmetica '-' term 
    { 
        $$ = create_noh(MINUS, 2, yylineno);
        $$->children[0] = $1;
        $$->children[1] = $3;
    }
    | term 
    {
        $$ = $1;
    }
    ;

term
    : term '*' termp 
    {
        $$ = create_noh(MULTI, 2, yylineno);
        $$->children[0] = $1;
        $$->children[1] = $3;
    }
    | term '/' termp 
    {
        $$ = create_noh(DIVIDE, 2, yylineno);
        $$->children[0] = $1;
        $$->children[1] = $3;
    } 
    | termp 
    {
        $$ = $1;
    }
    ;

termp
    : termp '^' factor 
    {
        $$ = create_noh(POW, 2, yylineno);
        $$->children[0] = $1;
        $$->children[1] = $3;
    }
    | factor 
    {
        $$ = $1;
    }
    ;

factor
    : '(' aritmetica ')' 
    { 
        $$ = $2;
    }
    | TOK_IDENT 
    {
        if (!simbolo_existe($1.ident))
            simbolo_novo($1.ident, TOK_IDENT);

        $$ = create_noh(IDENT, 0, yylineno);
        $$->name = $1.ident; 
    }
    | TOK_INTEGER 
    {
        $$ = create_noh(INTEGER, 0, yylineno);
        $$->intv = $1.intv; 
    }
    | TOK_FLOAT 
    {
        $$ = create_noh(FLOAT, 0, yylineno);
        $$->dblv = $1.dblv;
    }
    ;

logico
    : logico TOK_OR logterm	
    { 
        noh *n = create_noh(OR, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $3;
        $$ = n;
    }
    | logterm 
    { 
        $$ = $1; 
    }
    ;

logterm
    : logterm TOK_AND logfactor	
    { 
        noh *n = create_noh(AND, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $3;
        $$ = n;
    } 
    | logfactor 
    { 
        $$ = $1; 
    }
    ;

logfactor
    : '(' logico ')'	
    { 
        $$ = $2; 
    }
    | aritmetica '>' aritmetica
    { 
        noh *n = create_noh(GREATER, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $3;
        $$ = n;
    }
    | aritmetica '<' aritmetica		
    { 
        noh *n = create_noh(LITTLE, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $3;
        $$ = n;
    }
    | aritmetica '=''=' aritmetica	
    { 
        noh *n = create_noh(EQUAL, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $4;
        $$ = n;
    }
    | aritmetica '>''=' aritmetica	
    { 
        noh *n = create_noh(GTEQUAL, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $4;
        $$ = n;
    }
    | aritmetica '<''=' aritmetica	
    { 
        noh *n = create_noh(LTEQUAL, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $4;
        $$ = n;
    }
    | aritmetica '!''=' aritmetica	
    { 
        noh *n = create_noh(NOTEQUAL, 2, yylineno);
        n->children[0] = $1;
        n->children[1] = $4;
        $$ = n;
    }
    ;

while
    : TOK_WHILE logico '<''<' stmts '>''>'
    { 
        int t_childcount = 1 + $5->childcount;
        
        noh *n = create_noh(WHILE, t_childcount, yylineno);
        n->children[0] = $2;

        for(int i = 1, j = 0; i < t_childcount; i++)
            n->children[i] = $5->children[j++];

        $$ = n;
    }
    ;

if
    : TOK_IF logico '<''<' stmts '>''>'
    { 
        int t_childcount = 1 + $5->childcount;
        
        noh *n = create_noh(IF, t_childcount, yylineno);
        n->children[0] = $2;
        
        for(int i = 1, j = 0; i < t_childcount; i++)
            n->children[i] = $5->children[j++];
        
        $$ = n;
    }
    | TOK_IF logico '<''<' stmts '>''>' TOK_ELSE '<''<' stmts '>''>'
    { 
        
        int f_childcount = $5->childcount,
            s_childcount = $11->childcount,
            t_childcount = 1 + f_childcount + s_childcount,
            t_count, f_count, s_count;

        noh *n = create_noh(IF, t_childcount, yylineno);
        n->children[0] = $2;
        
        for(int t_count = 1, f_count = s_count = 0; t_count < t_childcount; t_count++) {
            if(t_count <= f_childcount) {
                n->children[t_count] = $5->children[f_count++];
            } else {
                n->children[t_count] = $11->children[s_count++];
            } 
        }

        $$ = n;
    }
    ;
%%

int yyerror(const char *s) {
    printf("[ERROR](LINE %d): %s\n", yylineno, s);
	return 1;
}


