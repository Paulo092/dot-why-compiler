
%{
	#include <stdio.h>
	#include "header.h"
	#include "calc.tab.h"
%}

%option yylineno

D	[0-9]
L	[a-zA-Z_]

%% 

[ \t\r\n]			{}
"show"				{ return TOK_PRINT; }
"loop"				{ return TOK_WHILE; }
"and"				{ return TOK_AND; }
"or"				{ return TOK_OR; }
"?"					{ return TOK_IF; }
"$"					{ return TOK_ELSE; }
"<"					{ return '<'; }
">"					{ return '>'; }
"!"					{ return '!'; }
"="					{ return '='; }
"*"					{ return '*'; }
"/"					{ return '/'; }
"+"					{ return '+'; }
"-"					{ return '-'; }
"("					{ return '('; }
")"					{ return ')'; }
"^"					{ return '^'; }

(-)*{D}+				{ yylval.args.intv = atoi(yytext); return TOK_INTEGER; }
(-)*{D}+\.{D}+			{ yylval.args.dblv = atof(yytext); return TOK_FLOAT; }
{L}({L}|{D})*		{ yylval.args.ident = strndup(yytext, yyleng); return TOK_IDENT; }

.					{ printf("[ERROR](LINE %d): Invalid caracter \"%c\".\n", yylineno, yytext[0]); }

%%

int yywrap() {
	return 1;
}

int main(int argc, char *argv[]) {
	if (argc <= 1) {
		show_message(ERROR, -1);
		printf("Undefined file argument: %s [file]\n", argv[0]);
		return 1;
	}

	/* WARNINGS */
	file_format_verification(argv[1]);
	unnecessary_arguments_verification(argc, argv);

	FILE *f = fopen(argv[1], "r");
	yyin = f;
	yyparse();
	fclose(f);

	printf("\n");

	return 0;
}

