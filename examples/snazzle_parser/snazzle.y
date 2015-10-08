%{
#include<stdio.h>
extern int yylex();
extern int yyparse();
extern FILE* yyin;
void yyerror(const char *s);
%}
%union {
	int ival;
	float fval;
	char *sval;
}
%token <ival> INT
%token <fval> FLOAT
%token <sval> STRING

%%

snazzle: 
	INT snazzle		{ printf("Bison found a string : %d\n", $1); }
	| FLOAT snazzle 	{ printf("Bison found a string : %f\n", $1); }
	| STRING snazzle	{ printf("Bison found a string : %s\n",$1); }
	| INT			{ printf("Bison found a string : %d\n",$1); }
	| FLOAT			{ printf("Bison found a string : %f\n",$1); }
	| STRING		{ printf("Bison found a string : %s\n",$1); }
	;

%%

int main(int c, char* argv[])
{
	FILE* f = fopen("in.sn", "r");
	if( !f )
	{
		printf("Cant open file\n");
		return -1;
	}
	yyin = f;
	// parse through the input until there is no more:
	do {
		yyparse();
	} while (!feof(yyin));
}

void yyerror(const char *s) {
	printf("EEK, parse error!  Message: %s",s);
	// might as well halt now:
	exit(-1);
}
