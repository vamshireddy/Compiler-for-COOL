%{
	#include "snazzle.tab.h"
%}
STRING	[a-zA-Z0-9]+
INTEGER	[0-9]+
FLOAT	[0-9]+.[0-9]+
%%
{INTEGER}	{ yylval.ival = atoi(yytext); return INT; }
{FLOAT}		{ yylval.fval = atof(yytext); return FLOAT; }
{STRING}	{ yylval.sval = strdup(yytext); return STRING; }
[\t \n]		;
.		;
%%
