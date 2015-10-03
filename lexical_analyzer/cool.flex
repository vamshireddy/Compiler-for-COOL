/*
 *  The scanner definition for COOL.
 */

/*
 *  Stuff enclosed in %{ %} in the first section is copied verbatim to the
 *  output, so headers and global definitions are placed here to be visible
 *  to the code in the file.  Don't remove anything that was here initially
 */


%{
#include <stdlib.h>
#include <cool-parse.h>
#include <stringtab.h>
#include <utilities.h>
int ind = 1;
int comment_start = 0;
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
int quote = 0;

/*
 *  Create string tables
 */

#define COMMENT_END 9889

%}
%Start QUOTE

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
SPACE		[\f\r\t\v ]
ALPHABET	[a-zA-Z]
ALPHABET_UPPER	[A-Z]
ALPHABET_LOWER	[a-z]
DIGIT		[0-9]
UNDERSCORE	_
NEW_LINE	"\n"
ASSIGN		"<-"
ARITHMETIC	[\+\-\*\/]
EQUAL		=
ESCAPED_STR	"\\"n
STRING		\"({ALPHABET}|{DIGIT}|{SPACE}|_|{ESCAPED_STR})*\"
STRING_ERR	\"({ALPHABET}|{DIGIT}|{SPACE}|_|"\n")*\"
%%

\'.\'			{ return yytext[1]; }
"(*"			{
				char c;
			comment_strt: 
				while((c = yyinput()) && (c!=EOF) && (c!='*'))
				{
					if( c == '\n' )
						curr_lineno++;
				}
				if( c == '*' )
				{
					while((c = yyinput()) == '*' );
					if( c == ')' )
					{
					}
					else if( c == EOF )
					{
						goto comment_err_eof;
					}
					else if( c == '\n' )
					{
						curr_lineno++;
					}
					else
					{
						unput(c);
						goto comment_strt;
					}
				}
				else if( c == EOF )
				{
			comment_err_eof:
					cool_yylval.error_msg = strdup("EOF in the comment");
					return ERROR;
				}
				else if ( c == '\n' )
				{
					curr_lineno++;
				}
			}
"*)"			{
				cool_yylval.error_msg = strdup("Unmatched *)");
				return ERROR;
			}

@			{ return '@'; }
"<"			{ return '<'; }
">"			{ return '>'; }
"<="			{ return LE; }
~			{ return '~'; }
{EQUAL}			{ return '='; }
{ARITHMETIC}		{ return yytext[0]; };
,			{ return ','; }
{SPACE}			;
{ASSIGN}		{ return ASSIGN; }
:			{ return ':';}
;			{ return ';';}
\"			{
				if( quote == 0 )
					quote = 1;
				else
					quote = 0;
			}
"["			{ return '['; }
"]"			{ return ']'; }
\.			{ return '.'; }
\{			{ return '{'; }
\}			{ return '}'; }
\(			{ return '('; }
\)			{ return ')'; }
{NEW_LINE}		{
				curr_lineno++;
			}
{ELSE}			{ return (ELSE);}
{CLASS}			{ return (CLASS);}
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
				cool_yylval.symbol = inttable.add_string(yytext);
				return (INT_CONST);
			}
{TRUE}			{ 	
				cool_yylval.boolean = 1;
				return (BOOL_CONST);
			}
{FALSE}			{	cool_yylval.boolean = 0;
				return (BOOL_CONST); 	}

{ALPHABET_LOWER}({ALPHABET}|{DIGIT}|{UNDERSCORE})*	{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (TYPEID);
			}
{ALPHABET_UPPER}({ALPHABET}|{DIGIT}|{UNDERSCORE})*	{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (OBJECTID);
			}
{STRING}		{
				char* str = (char*)malloc(yyleng-2);
				int i;
				for(i=1;i<yyleng-1;i++)
				{
					str[i-1] = yytext[i];
				}
				str[i] = '\0';
				cool_yylval.symbol = stringtable.add_string(str);
				return STR_CONST; 
			}

.			{ 	cool_yylval.error_msg = strdup(yytext);
				return ERROR;	}
%%
