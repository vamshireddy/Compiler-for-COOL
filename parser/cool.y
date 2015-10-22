
/*
*  cool.y
*              Parser definition for the COOL language.
*
*/
%{
  #include <iostream>
  #include "cool-tree.h"
  #include "stringtab.h"
  #include "utilities.h"
  
  extern char *curr_filename;
  
  /* Locations */
  #define YYLTYPE int              /* the type of locations */
  #define cool_yylloc curr_lineno  /* use the curr_lineno from the lexer
  for the location of tokens */
    char cur_class_id[20];
    extern int node_lineno;          /* set before constructing a tree node
    to whatever you want the line number
    for the tree node to be */
      
      
      #define YYLLOC_DEFAULT(Current, Rhs, N)         \
      Current = Rhs[1];                             \
      node_lineno = Current;
    
    
    #define SET_NODELOC(Current)  \
    node_lineno = Current;
    
    /* IMPORTANT NOTE ON LINE NUMBERS
    *********************************
    * The above definitions and macros cause every terminal in your grammar to 
    * have the line number supplied by the lexer. The only task you have to
    * implement for line numbers to work correctly, is to use SET_NODELOC()
    * before constructing any constructs from non-terminals in your grammar.
    * Example: Consider you are matching on the following very restrictive 
    * (fictional) construct that matches a plus between two integer constants. 
    * (SUCH A RULE SHOULD NOT BE  PART OF YOUR PARSER):
    
    plus_consts	: INT_CONST '+' INT_CONST 
    
    * where INT_CONST is a terminal for an integer constant. Now, a correct
    * action for this rule that attaches the correct line number to plus_const
    * would look like the following:
    
    plus_consts	: INT_CONST '+' INT_CONST 
    {
      // Set the line number of the current non-terminal:
      // ***********************************************
      // You can access the line numbers of the i'th item with @i, just
      // like you acess the value of the i'th exporession with $i.
      //
      // Here, we choose the line number of the last INT_CONST (@3) as the
      // line number of the resulting expression (@$). You are free to pick
      // any reasonable line as the line number of non-terminals. If you 
      // omit the statement @$=..., bison has default rules for deciding which 
      // line number to use. Check the manual for details if you are interested.
      @$ = @3;
      
      
      // Observe that we call SET_NODELOC(@3); this will set the global variable
      // node_lineno to @3. Since the constructor call "plus" uses the value of 
      // this global, the plus node will now have the correct line number.
      SET_NODELOC(@3);
      
      // construct the result node:
      $$ = plus(int_const($1), int_const($3));
    }
    
    */
    
    
    
    void yyerror(char *s);        /*  defined below; called for each parse error */
    extern int yylex();           /*  the entry point to the lexer  */
    
    /************************************************************************/
    /*                DONT CHANGE ANYTHING IN THIS SECTION                  */
    
    Program ast_root;	      /* the result of the parse  */
    Classes parse_results;        /* for use in semantic analysis */
    int omerrs = 0;               /* number of errors in lexing and parsing */
    %}
    
    /* A union of all the types that can be the result of parsing actions. */
    %union {
      Boolean boolean;
      Symbol symbol;
      Program program;
      Class_ class_;
      Classes classes;
      Feature feature;
      Features features;
      Formal formal;
      Formals formals;
      Case case_;
      Cases cases;
      Expression expression;
      Expressions expressions;
      char *error_msg;
    }
    
    /* 
    Declare the terminals; a few have types for associated lexemes.
    The token ERROR is never used in the parser; thus, it is a parse
    error when the lexer returns it.
    
    The integer following token declaration is the numeric constant used
    to represent that token internally.  Typically, Bison generates these
    on its own, but we give explicit numbers to prevent version parity
    problems (bison 1.25 and earlier start at 258, later versions -- at
    257)
    */
    %token CLASS 258 ELSE 259 FI 260 IF 261 IN 262 
    %token INHERITS 263 LET 264 LOOP 265 POOL 266 THEN 267 WHILE 268
    %token CASE 269 ESAC 270 OF 271 DARROW 272 NEW 273 ISVOID 274
    %token <symbol>  STR_CONST 275 INT_CONST 276 
    %token <boolean> BOOL_CONST 277
    %token <symbol>  TYPEID 278 OBJECTID 279 
    %token ASSIGN 280 NOT 281 LE 282 ERROR 283
    
    /*  DON'T CHANGE ANYTHING ABOVE THIS LINE, OR YOUR PARSER WONT WORK       */
    /**************************************************************************/
    
    /* Complete the nonterminal list below, giving a type for the semantic
    value of each non terminal. (See section 3.6 in the bison 
    documentation for details). */
    
    /* Declare types for the grammar's non-terminals. */
    %type <program> program
    %type <classes> class_list
    %type <class_> class
    %type <feature> feature
    %type <features> feature_list
    %type <formal> formal
    %type <formals> formal_list
    %type <formals> list_of_formals
    %type <expression> expr
    %type <expressions> expr_list
    %type <expression> optional_Assignment
    %type <expression> let_id_opt
    %type <expressions> let_ids_opt
    %type <expression> let_init_opt
    %type <expressions> list_of_expr_args
    %type <expressions> expr_args_list 
    %type <cases> case_labels
    
    /* Precedence declarations go here. */
    %left ASSIGN
    %left NOT
    %left LET
    %nonassoc '<' '=' LE
    %left '+' '-'
    %left '*' '/'
    %left ISVOID
    %left '~'
    %left '@'
    %left '.'
    %%
    	/* 
    		Save the root of the abstract syntax tree in a global variable.
    	*/
    	program	: class_list	{ 
	@$ = @1; 
	ast_root = program($1); }
    	;
    
    	class_list
    	: class			/* single class */
    	{ $$ = single_Classes($1);
	parse_results = $$; }
    	| class_list class	/* several classes */
    	{ $$ = append_Classes($1,single_Classes($2)); 
    	parse_results = $$; }
    	;
    
    	/* If no parent is specified, the class inherits from the Object class. */
    	class	: CLASS TYPEID '{' feature_list '}' ';' 
	{
		@$ = @6;
		SET_NODELOC(@6);
		strcpy(cur_class_id, $2->get_string());
		$$ = class_($2,idtable.add_string("Object"),$4,
    		stringtable.add_string(curr_filename));
	}
    	| CLASS TYPEID INHERITS TYPEID '{' feature_list '}' ';' {
		@$ = @8;
		SET_NODELOC(@8);
		strcpy(cur_class_id, $2->get_string());
		$$ = class_($2,$4,$6,stringtable.add_string(curr_filename));
	}
	| CLASS TYPEID error TYPEID '{' feature_list '}' ';' {
		yyerrok;
	}
	;
    
	/* Feature list may be empty, but no empty features in list. */
	feature_list: 
	{
		$$ = nil_Features(); 
	}
	| feature_list feature ';'
	{
		@$ = @3;
		SET_NODELOC(@3);
		$$ = append_Features($1, single_Features($2));
	}
	| feature_list error ';'
	{
		@$ = @3;
		yyerrok;
	}
	;

	feature: OBJECTID '(' formal_list ')' ':' TYPEID '{' expr '}'
	{
		@$ = @9;
		SET_NODELOC(@8);
		$$ = method($1, $3, $6, $8);
	}
	| OBJECTID ':' TYPEID optional_Assignment
	{
		SET_NODELOC(@3);
		$$ = attr( $1, $3, $4);
	}
	;

	optional_Assignment :
	{
		$$ = no_expr();
	}
	| ASSIGN expr
	{
		$$ = $2;
	}
	;

	formal_list: 
	{
		$$ = nil_Formals();
	}
	| list_of_formals
	{
		$$ = $1;
	};

	list_of_formals: formal {
		SET_NODELOC(@1);
		$$ = single_Formals($1);
	}
	| formal ',' list_of_formals {
		SET_NODELOC(@2);
		$$ = append_Formals(single_Formals($1), $3);
	}
	;

	formal: OBJECTID ':' TYPEID
	{
		SET_NODELOC(@3);
		$$ = formal($1, $3);
	}
	;

	/* list of expr args */
	expr_args_list: 
	{
		$$ = nil_Expressions();
	}
	| list_of_expr_args
	{
		$$ = $1;
	};

	list_of_expr_args: expr {
		SET_NODELOC(@1);
		$$ = single_Expressions($1);
	}
	| expr ',' list_of_expr_args {
		$$ = append_Expressions(single_Expressions($1), $3);
	}
	;

	/* Let ids optional */
	let_ids_opt: let_id_opt let_ids_opt {
		$$ = append_Expressions($2, single_Expressions($1));	
	}
	| {
		$$ = nil_Expressions();
	}
	;

	/* Let id optional */
	let_id_opt: ',' OBJECTID ':' TYPEID let_init_opt {
		SET_NODELOC(@3);
		assign($2, $5);
		$$ = let($2, $4, $5, no_expr());
	}
	| ',' error ','
	{
		yyerrok;
	}
	;

	/* let init opt */
	let_init_opt: ASSIGN expr {
		SET_NODELOC(@2);
		$$ = $2;		
	}
	| {
		SET_NODELOC(curr_lineno);
		$$ = no_expr();
	}
	;

	/* case labels */
	case_labels: OBJECTID ':' TYPEID DARROW expr ';' case_labels {
		SET_NODELOC(@6);
		$$ = append_Cases(single_Cases(branch($1, $3, $5)), $7);
	}
	| {
		$$ = nil_Cases();
	}
	;

	/* Expression productions */

	expr: OBJECTID ASSIGN expr{
		SET_NODELOC(@3);
		$$ = assign($1, $3); 
	}
	| expr '.' OBJECTID '(' expr_args_list ')' {
		SET_NODELOC(@1);
		$$ = dispatch($1, $3, $5);	
	}
	| expr '@' TYPEID '.' OBJECTID '(' expr_args_list ')' {
		SET_NODELOC(@1);
		$$ = static_dispatch($1, $3, $5, $7);
	}
	| OBJECTID '(' expr_args_list ')' {
		SET_NODELOC(@4);
		$$ = dispatch(object(idtable.add_string("self")), $1, $3) ;
	}
	| LET OBJECTID ':' TYPEID let_init_opt let_ids_opt IN expr %prec LET {
		SET_NODELOC(@4);
		assign($2, $5);
		Expression prev = $8;
		for(int i = $6->first(); $6->more(i) ; i=$6->next(i))
		{
			let_class* l = (let_class*)$6->nth(i);
			SET_NODELOC(l->get_line_number());
			prev = let(l->get_identifier(), l->get_type_decl(), l->get_init(), prev);
		}
		$$ = let($2, $4, $5, prev);
	}
	| CASE expr OF case_labels ESAC {
		SET_NODELOC(@5);
		$$ = typcase( $2, $4);
	}
	| CASE error ESAC {
		yyerrok;
	}
	| WHILE expr LOOP expr POOL {
		SET_NODELOC(@5);
		$$ = loop( $2, $4);
	}
	| IF expr THEN expr ELSE expr FI {
		SET_NODELOC(@7);
		$$ = cond($2, $4, $6);
	}
	| STR_CONST {
		SET_NODELOC(@1);
		$$ = string_const($1);
	}
	| INT_CONST {
		SET_NODELOC(@1);
		$$ = int_const($1);
	}
	| OBJECTID {
		SET_NODELOC(@1);
		$$ = object($1);
	}
	| '(' expr ')' {
		SET_NODELOC(@3);
		$$ = $2;
	}
	| expr '+' expr {
		SET_NODELOC(@3);
		$$ = plus($1, $3);
	}
	| expr '-' expr {
		SET_NODELOC(@3);
		$$ = sub($1, $3);
	}
	| expr '*' expr {
		SET_NODELOC(@3);
		$$ = mul($1, $3);
	}
	| expr '/' expr {
		SET_NODELOC(@3);
		$$ = divide($1, $3);
	}
	| expr '=' expr {
		SET_NODELOC(@3);
		$$ = eq($1, $3);
	}
	| expr LE expr {
		SET_NODELOC(@3);
		$$ = leq($1, $3);
	}
	| expr '<' expr{
		SET_NODELOC(@3);
		$$ = lt($1, $3);
	}
	| NOT expr {
		SET_NODELOC(@2);
		$$ = comp($2);
	}
	| '~' expr {
		SET_NODELOC(@2);
		$$ = neg($2);
	}
	| BOOL_CONST {
		SET_NODELOC(@1);
		$$ = bool_const($1);
	}

	| ISVOID expr {
		SET_NODELOC(@2);
		$$ = isvoid($2);
	}
	| NEW TYPEID {
		SET_NODELOC(@2);
		$$ = new_($2);
	}
	| '{' expr_list '}' {
		SET_NODELOC(@3);
		$$ = block($2);
	}
	;
	
	expr_list: expr ';'
	{
		SET_NODELOC(@2);
		$$ = single_Expressions($1);
	}
	| expr ';' expr_list
	{
		SET_NODELOC(@3);
		$$ = append_Expressions(single_Expressions($1), $3);
	}
	| error ';' expr_list
	{
		yyerrok;
	}
	;



    /* end of grammar */
    %%
    
    /* This function is called automatically when Bison detects a parse error. */
    void yyerror(char *s)
    {
      extern int curr_lineno;
      
      cerr << "\"" << curr_filename << "\", line " << curr_lineno << ": " \
      << s << " at or near ";
      print_cool_token(yychar);
      cerr << endl;
      omerrs++;
      
      if(omerrs>50) {fprintf(stdout, "More than 50 errors\n"); exit(1);}
    }
    
    
