%{
// This content is copied directly to the output file
int num_lines = 0;
int num_chars = 0;
int digits = 0;
%}
digit [0-9]
%%
{digit} {++digits;}
\n	{++num_lines;
	++num_chars;}
.	++num_chars;
%%
main()
{
	yylex();
	printf("# of digits = %d\n # of lines = %d and # of chars = %d\n", digits, num_lines,num_chars);
}
