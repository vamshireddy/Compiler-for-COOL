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

char unput_buffer[MAX_STR_CONST];

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
DARROW		"=>"	
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
ESCAPED_STR	\\\n
STRING		\"([^\n"]|{ESCAPED_STR})+\"{1,1024}
STRING_ERR	\"([^\n"]|{ESCAPED_STR})+\"{1025,*}
%%

{DARROW}		{ return DARROW;}

"--"			{ 	
				char c;
				while( (c = yyinput()) && ( c!=EOF ) && (c!='\n' ));
				curr_lineno++;	
			}
\'.\'			{ return yytext[1]; }
"(*"			{
				comment_start++;
				char c;
			comment_strt: 
				while((c = yyinput()) && (c!=EOF) && (c!='*') && (c!='('))
				{
					if( c == '\n' )
						curr_lineno++;
				}
				if( c == '*' )
				{	
					while((c = yyinput()) && ( c == '*') );
					if( c == ')' )
					{	
						comment_start--;
						if( comment_start > 0 )
						{
							goto comment_strt;
						}
					}
					else if( c == EOF )
					{
						goto comment_err_eof;
					}
					else if( c == '\n' )
					{
						curr_lineno++;
						unput(c);
						goto comment_strt;
					}
					else
					{
						unput(c);
						goto comment_strt;
					}
				}
				else if( c == '(' )
				{
					c = yyinput();
					if(c == '*')
					{
						comment_start++;
						goto comment_strt;
					}
					else if( c == EOF )
					{
						goto comment_err_eof;
					}
					else if( c == '\n' )
					{
						curr_lineno++;
						unput(c);
						goto comment_strt;
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
">"			{ 
				cool_yylval.error_msg = strdup(">");
				return ERROR;
			}
"<="			{ return LE; }
~			{ return '~'; }
{EQUAL}			{ return '='; }
{ARITHMETIC}		{ return yytext[0]; };
,			{ return ','; }
{SPACE}			;
{ASSIGN}		{ return ASSIGN; }
\:			{ return ':';}
;			{ return ';';}
\"			{
				char c;
				char prev = 0;
				int count = 0;
				int chars = 0;
				while( (c=yyinput()) && (c!='\"') && (c!=EOF))
				{
					if( c != '\\' )
						chars++;
					if( chars >= (MAX_STR_CONST) )
					{
						cool_yylval.error_msg = "String constant too long";
						goto str_err;
					}
					// NULL chars are not allowed
					if( c == '\0')
					{
						cool_yylval.error_msg = "String contains null character";
						goto str_err;
					}
					if( prev == '\\' )
					{
						if( c == '\n' )
						{
							/* Rewrite the '\' and \n' chars as '\n' char */
							string_buf[count-1] = '\n';
						}
						else if( c == '0' )
						{
							/* Rewrite the '\' and '0' as '0' */
							string_buf[count-1] = '0';
						}
						else if( c == 'n' )
						{	
							string_buf[count-1] = '\n';
						}
						else
						{
							string_buf[count++] = c;
						}
						prev = c;
						continue;
					}
					else if( prev != '\\')
					{
						if( c == '\n' ) {
							cool_yylval.error_msg = "Unterminated string constant";
							return ERROR;
						}
						else
						{
							string_buf[count++] = c;
							prev = c;
						}
					}
				}
				if( c == '\0' )
				{
					cool_yylval.error_msg = "String contains null character";
					goto str_err;

				}
				if( c == EOF )
				{
					cool_yylval.error_msg = "Unterminated string";
					return ERROR;
				}
				string_buf[count] = '\0';
				cool_yylval.symbol = stringtable.add_string(string_buf);
				return STR_CONST;
			str_err:
				while( (c = yyinput()) && (c!='\n') && (c!='"'));
				return ERROR;
			}
"["			{	
				cool_yylval.error_msg = strdup("[");
				return ERROR; }
"]"			{ 
				cool_yylval.error_msg = strdup("]");
				return ERROR; }
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

{ALPHABET_UPPER}({ALPHABET}|{DIGIT}|{UNDERSCORE})*	{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (TYPEID);
			}
{ALPHABET_LOWER}({ALPHABET}|{DIGIT}|{UNDERSCORE})*	{
				cool_yylval.symbol = idtable.add_string(yytext);
				return (OBJECTID);
			}
.			{ 	cool_yylval.error_msg = strdup(yytext);
				return ERROR;	}
%%
