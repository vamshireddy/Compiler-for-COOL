/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 *  to the code in the file.  Don't remove anything that was here initially
 */


%{
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
int ind = 0;
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
 *  Create string tables
 */

%}
/*
 * Define names for regular expressions here.
 */
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
SPACE		[\f\r\t\v\n]
ALPHABET	[a-zA-Z]
ALPHABET_UPPER	[A-Z]
ALPHABET_LOWER	[a-z]
DIGIT		[0-9]
UNDERSCORE	_
NEW_LINE	"\n"
%%
{SPACE}			{ ECHO;}
{NEW_LINE}		{
				curr_lineno++;
				return '\n'; 
			}
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
({DIGIT})+		{
				return (INT_CONST);
			}
{TRUE}			{ 	
				return (BOOL_CONST);
			}
{FALSE}			{	return (BOOL_CONST); 	}

{ALPHABET_LOWER}({ALPHABET}|{DIGIT}|{UNDERSCORE})*	{
				cool_yylval.symbol = new Entry(strdup(yytext), strlen(yytext), ind++);
				return (TYPEID);
			}
{ALPHABET_UPPER}({ALPHABET}|{DIGIT}|{UNDERSCORE})*	{
				cool_yylval.symbol = new Entry(strdup(yytext), strlen(yytext), ind++);
				return (OBJECTID);
			}
%%
