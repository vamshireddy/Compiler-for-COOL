/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 * to the code in the file.  Don't remove anything that was here initially
 */
%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>

/* The compiler assumes these identifiers. */
#define yylval cool_yylval
#define yylex  cool_yylex

/* Max size of string constants */
#define MAX_STR_CONST 1025
#define YY_NO_UNPUT   /* keep g++ happy */

extern FILE *fin; /* we read from this file */

/* define YY_INPUT so we read from the FILE fin:
 * This change makes it possible to use this scanner in
 * the Cool compiler.
 */
#undef YY_INPUT
#define YY_INPUT(buf,result,max_size) \
	if ( (result = fread( (char*)buf, sizeof(char), max_size, fin)) < 0) \
		YY_FATAL_ERROR( "read() in flex scanner failed");

char string_buf[MAX_STR_CONST]; /* to assemble string constants */
char *string_buf_ptr;

extern int curr_lineno;
extern int verbose_flag;

extern YYSTYPE cool_yylval;

/*
 *  Add Your own definitions here
 */

%}
/*
 * Define names for regular expressions here.
 */
DARROW          =>
ELSE		(?i:else)
CLASS		(?i:class)
FALSE		f(?i:alse)
IF		(?i:if)
FI		(?i:fi)
IN		(?i:in)
INHERITS	(?i:inherits)
ISVOID		(?i:isvoid)
LET		(?i:let)
LOOP		(?i:loop)
POOL		(?i:pool)
THEN		(?i:then)
WHILE		(?i:while)
CASE		(?i:case)
ESAC		(?i:esac)
NEW		(?i:new)
OF		(?i:of)
NOT		(?i:not)
TRUE		t(?i:rue)
SPACE		"\f" | "\r" | "\t" | "\v" | " "
NEW_LINE	"\n"+
WHITE_SPACE	(SPACE)+
ALPHABET	[a-zA-Z]
ALPHABET_UPPER	[A-Z]
ALPHABET_LOWER	[a-z]
DIGIT		[0-9]
UNDERSCORE	_
STRING		\"((ALPHABET|DIGIT|UNDERSCORE)|("\"[^n])|("\""\"n))*\"
NUMBER		DIGIT+
TYPEID		(ALPHABET_UPPER)(ALPHABET|DIGIT|UNDERSCORE)*
OBJID		(ALPHABET_LOWER)(ALPHABET|DIGIT|UNDERSCORE)*
ARITHMETIC_OP	"+" | "-" | "*" | "/"
COMP_OP		"<" | "<=" | "=" | ">" | ">="
PUNCT		";" | ":" | "," | "." | "@"
PARAN		"(" | ")" | "{" | "}"
%%
{ARITHMETIC_OP}		{ return atoi(yytext); }
{COMP_OP}		{ return atoi(yytext); }
{PUNCT}			{ return atoi(yytext); }
{PARAN}			{ return atoi(yytext); }
{DARROW}		{ return (DARROW); }
{ELSE}			{ return (ELSE);   }
{CLASS}			{ return (CLASS);  }
{IF}			{ return (IF);}
{FI}			{ return (FI);}
{IN}			{ return (IN);}
{INHERITS}		{ return (INHERITS);}
{ISVOID}		{ return (ISVOID);}
{LET}			{ return (LET);}
{LOOP}			{ return (LOOP);}
{POOL}			{ return (POOL);}
{THEN}			{ return (THEN);}
{WHILE}			{ return (WHILE);}
{CASE}			{ return (CASE);}
{ESAC}			{ return (ESAC);}
{NEW}			{ return (NEW);}
{OF}			{ return (OF);}
{NOT}			{ return (NOT);}
{NUMBER}		{ 	yylval.symbol = yytext;
				return (INT_CONST);
			}
{STRING}		{	yylval.symbol = yytext;
				return (STR_CONST);
			}
{ASSIGN}		{ 	return (ASSIGN);}
{TRUE}			{ 	yylval.boolean = "true";
				return (BOOL_CONST);
			}
{FALSE}			{	yylval.boolean = "false";
				return (BOOL_CONST); 
			}
{NEW_LINE}		{ 	curr_lineno++;
				return (); 
			}
{TYPEID}		{	yylval.symbol = yytext;
				return TYPE_ID;
			}
{SPACE}			{
			}
{ERROR}			{
				/*
					Adjust the pointer to move one char back!
				*/
				return ERROR;
			}
 /*
  * Keywords are case-insensitive except for the values true and false,
  * which must begin with a lower-case letter.
  */


 /*
  *  String constants (C syntax)
  *  Escape sequence \c is accepted for all characters c. Except for 
  *  \n \t \b \f, the result is c.
  *
  */
%%
main()
{	
	return cool_yylex();
}
