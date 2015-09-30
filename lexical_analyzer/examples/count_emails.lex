%{
int emails = 0;
%}
digit	[0-9]
letter_lower	[a-z]
letter_upper	[A-Z]
letter		[letter_lower|letter_upper]
email	letter[digit|letter|_|\.]*@(gmail|yahoo|live)\.com
%%
{email}		{emails++}
%%
main()
{
	yylex();
	printf("Number of emails present = %d\n",emails);
}
