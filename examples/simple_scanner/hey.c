#include<stdio.h>

char* names[] = {NULL, "db_type", "db_name", "db_table_prefix", "db_port"};

int main()
{
	int ntoken, vtoken;
	while(1)
	{
		ntoken = yylex();
		if( ntoken == -1 )
			return 0;
		printf("%s\n", names[ntoken]);
	}
}
