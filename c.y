%{
	#include <stdio.h>
	#include <string.h>
	
	#include "ast.h"
	
	#define YYSTYPE struct ast_node*
	
	extern char * yytext;
	extern int yylineno;
	
	void yyerror(char const *);
	
	struct ast_node* root;
%}

%token	IDENTIFIER I_CONSTANT F_CONSTANT STRING_LITERAL FUNC_NAME SIZEOF
%token	PTR_OP INC_OP DEC_OP LEFT_OP RIGHT_OP LE_OP GE_OP EQ_OP NE_OP
%token	AND_OP OR_OP MUL_ASSIGN DIV_ASSIGN MOD_ASSIGN ADD_ASSIGN
%token	SUB_ASSIGN LEFT_ASSIGN RIGHT_ASSIGN AND_ASSIGN
%token	XOR_ASSIGN OR_ASSIGN
%token	TYPEDEF_NAME ENUMERATION_CONSTANT

%token	TYPEDEF EXTERN STATIC AUTO REGISTER INLINE
%token	CONST RESTRICT VOLATILE
%token	BOOL CHAR SHORT INT LONG SIGNED UNSIGNED FLOAT DOUBLE VOID
%token	COMPLEX IMAGINARY 
%token	STRUCT UNION ENUM ELLIPSIS

%token	CASE DEFAULT IF ELSE SWITCH WHILE DO FOR GOTO CONTINUE BREAK RETURN

%token	ALIGNAS ALIGNOF ATOMIC GENERIC NORETURN STATIC_ASSERT THREAD_LOCAL

%start translation_unit
%%


identifier
	: IDENTIFIER { 
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_IDENTIFIER;
		$$->value = strdup(yytext);
	};
	
i_constant
	: I_CONSTANT { 
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_INTCONSTANT;
		$$->value = strdup(yytext);
	};

f_constant
	: F_CONSTANT {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FLOATCONSTANT;
		$$->value = strdup(yytext);
	};
	
string_literal
	: STRING_LITERAL {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_STRINGLITERAL;
		$$->value = strdup(yytext);
	};
	
func_name
	: FUNC_NAME
	;
	
size_of
	: SIZEOF
	;
	
ptr_op
	: PTR_OP
	;

primary_expression
	: identifier {
		$$ = $1;
	}
	| constant {
		$$ = $1;
	}
	| string {
		$$ = $1;
	}
	| '(' expression ')' {
		$$ = $2;
	}
	| generic_selection
	;

constant
	: i_constant {
		$$ = $1;
	}
	| f_constant {
		$$ = $1;
	}
	| ENUMERATION_CONSTANT
	;

enumeration_constant
	: identifier
	;

string
	: string_literal
	| FUNC_NAME
	;

generic_selection
	: GENERIC '(' assignment_expression ',' generic_assoc_list ')'
	;

generic_assoc_list
	: generic_association
	| generic_assoc_list ',' generic_association
	;

generic_association
	: type_name ':' assignment_expression
	| DEFAULT ':' assignment_expression
	;

postfix_expression
	: primary_expression {
		$$ = $1;
	}
	| postfix_expression '[' expression ']' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ARRAYACCESS;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| postfix_expression '(' ')' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FCALL_NO_ARGS;
		$$->left_child = $1;
		$1->parent = $$;
	}
	| postfix_expression '(' argument_expression_list ')' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FCALL_ARGS;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		struct ast_node* curr = $3;
		while(curr != NULL) {
			curr->parent = $$;
			curr = curr->right_sibling;
		}
	}
	| postfix_expression '.' identifier
	| postfix_expression PTR_OP identifier
	| postfix_expression INC_OP {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_POST_UNARY;
		$$->left_child = $1;
		$1->parent = $$;
	}
	| postfix_expression DEC_OP {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_POST_UNARY;
		$$->left_child = $1;
		$1->parent = $$;
	}
	| '(' type_name ')' '{' initializer_list '}'
	| '(' type_name ')' '{' initializer_list ',' '}'
	;

argument_expression_list
	: assignment_expression {
		$$ = $1;
	}
	| argument_expression_list ',' assignment_expression {
		struct ast_node* curr = $1;
		while(curr->right_sibling != NULL) {
			curr = curr->right_sibling;
		}
		curr->right_sibling = $3;
		$$ = $1;
	}
	;

unary_expression
	: postfix_expression {
		$$ = $1;
	}
	| INC_OP unary_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_PRE_UNARY;
		$$->left_child = $2;
		$2->parent = $$;
	}
	| DEC_OP unary_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_PRE_UNARY;
		$$->left_child = $2;
		$2->parent = $$;
	}
	| unary_operator cast_expression
	| SIZEOF unary_expression
	| SIZEOF '(' type_name ')'
	| ALIGNOF '(' type_name ')'
	;

unary_operator
	: '&'
	| '*'
	| '+'
	| '-'
	| '~'
	| '!'
	;

cast_expression
	: unary_expression {
		$$ = $1;
	}
	| '(' type_name ')' cast_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_CAST_EXPRESSION;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

multiplicative_expression
	: cast_expression {
		$$ = $1;
	}
	| multiplicative_expression '*' cast_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| multiplicative_expression '/' cast_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| multiplicative_expression '%' cast_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

additive_expression
	: multiplicative_expression {
		$$ = $1;
	}
	| additive_expression '+' multiplicative_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| additive_expression '-' multiplicative_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

shift_expression
	: additive_expression {
		$$ = $1;
	}
	| shift_expression LEFT_OP additive_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| shift_expression RIGHT_OP additive_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$$->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

relational_expression
	: shift_expression {
		$$ = $1;
	}
	| relational_expression '<' shift_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| relational_expression '>' shift_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| relational_expression LE_OP shift_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| relational_expression GE_OP shift_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

equality_expression
	: relational_expression {
		$$ = $1;
	}
	| equality_expression EQ_OP relational_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| equality_expression NE_OP relational_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

and_expression
	: equality_expression {
		$$ = $1;
	}
	| and_expression '&' equality_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

exclusive_or_expression
	: and_expression {
		$$ = $1;
	}
	| exclusive_or_expression '^' and_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

inclusive_or_expression
	: exclusive_or_expression {
		$$ = $1;
	}
	| inclusive_or_expression '|' exclusive_or_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

logical_and_expression
	: inclusive_or_expression {
		$$ = $1;
	}
	| logical_and_expression AND_OP inclusive_or_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

logical_or_expression
	: logical_and_expression {
		$$ = $1;
	}
	| logical_or_expression OR_OP logical_and_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BINARY_OP;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	;

conditional_expression
	: logical_or_expression {
		$$ = $1;
	}
	| logical_or_expression '?' expression ':' conditional_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TERNARY;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$3->right_sibling = $5;
		$1->parent = $$;
		$3->parent = $$;
		$5->parent = $$;
	}
	;

assignment_expression
	: conditional_expression {
		$$ = $1;
	}
	| unary_expression assignment_operator assignment_expression {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->left_child = $1;
		$1->right_sibling = $2;
		$2->right_sibling = $3;
		$1->parent = $$;
		$2->parent = $$;
		$3->parent = $$;
	}
	;

assignment_operator
	: '=' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "=";
	}
	| MUL_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "*=";
	}
	| DIV_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "/=";
	}
	| MOD_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "%=";
	}
	| ADD_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "+=";
	}
	| SUB_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "-=";
	}
	| LEFT_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "<<=";
	}
	| RIGHT_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = ">>=";
	}
	| AND_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "&=";
	}
	| XOR_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "^=";
	}
	| OR_ASSIGN {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_ASSIGNMENT;
		$$->value = "|=";
	}
	;

expression
	: assignment_expression {
		$$ = $1;
	}
	| expression ',' assignment_expression {
		$1->right_sibling = $2;
		$$ = $1;
	}
	;

constant_expression
	: conditional_expression	/* with constraints */
	;

declaration
	: declaration_specifiers ';'
	| declaration_specifiers init_declarator_list ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_DECLARATION;
		$$->left_child = $1;
		$1->parent = $$;
		$1->right_sibling = $2;
		struct ast_node* curr = $2;
		while(curr != NULL) {
			curr->parent = $$;
			curr = curr->right_sibling;
		}
	}
	
	| static_assert_declaration
	;

declaration_specifiers
	: storage_class_specifier declaration_specifiers
	| storage_class_specifier
	| type_specifier declaration_specifiers
	| type_specifier {
		$$ = $1;
	}
	
	| type_qualifier declaration_specifiers
	| type_qualifier
	| function_specifier declaration_specifiers
	| function_specifier
	| alignment_specifier declaration_specifiers
	| alignment_specifier
	;

init_declarator_list
	: init_declarator {
		$$ = $1;	
	}
	
	| init_declarator_list ',' init_declarator {
		struct ast_node* curr = $1;
		while(curr->right_sibling != NULL) {
			curr = curr->right_sibling;
		}
		curr->right_sibling = $3;
		$$ = $1;
	}
	;

init_declarator
	: declarator '=' initializer {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_DECLARATOR_INITIALIZER;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	
	| declarator {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_DECLARATOR;
		$$->left_child = $1;
		$1->parent = $$;
	}
	;

storage_class_specifier
	: TYPEDEF	/* identifiers must be flagged as TYPEDEF_NAME */
	| EXTERN
	| STATIC
	| THREAD_LOCAL
	| AUTO
	| REGISTER
	;

type_specifier
	: VOID {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "void";
	}
	| CHAR {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "char";
	}
	| SHORT {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "short";
	}
	| INT {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "int";
	}
	| LONG {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "long";
	}
	| FLOAT {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "float";
	}
	| DOUBLE {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_TYPE_SPECIFIER;
		$$->value = "double";
	}
	| SIGNED
	| UNSIGNED
	| BOOL
	| COMPLEX
	| IMAGINARY	  	/* non-mandated extension */
	| atomic_type_specifier
	| struct_or_union_specifier
	| enum_specifier
	| TYPEDEF_NAME		/* after it has been defined as such */
	;

struct_or_union_specifier
	: struct_or_union '{' struct_declaration_list '}'
	| struct_or_union identifier '{' struct_declaration_list '}'
	| struct_or_union identifier
	;

struct_or_union
	: STRUCT
	| UNION
	;

struct_declaration_list
	: struct_declaration
	| struct_declaration_list struct_declaration
	;

struct_declaration
	: specifier_qualifier_list ';'	/* for anonymous struct/union */
	| specifier_qualifier_list struct_declarator_list ';'
	| static_assert_declaration
	;

specifier_qualifier_list
	: type_specifier specifier_qualifier_list
	| type_specifier
	| type_qualifier specifier_qualifier_list
	| type_qualifier
	;

struct_declarator_list
	: struct_declarator
	| struct_declarator_list ',' struct_declarator
	;

struct_declarator
	: ':' constant_expression
	| declarator ':' constant_expression
	| declarator
	;

enum_specifier
	: ENUM '{' enumerator_list '}'
	| ENUM '{' enumerator_list ',' '}'
	| ENUM identifier '{' enumerator_list '}'
	| ENUM identifier '{' enumerator_list ',' '}'
	| ENUM identifier
	;

enumerator_list
	: enumerator
	| enumerator_list ',' enumerator
	;

enumerator	/* identifiers must be flagged as ENUMERATION_CONSTANT */
	: enumeration_constant '=' constant_expression
	| enumeration_constant
	;

atomic_type_specifier
	: ATOMIC '(' type_name ')'
	;

type_qualifier
	: CONST
	| RESTRICT
	| VOLATILE
	| ATOMIC
	;

function_specifier
	: INLINE
	| NORETURN
	;

alignment_specifier
	: ALIGNAS '(' type_name ')'
	| ALIGNAS '(' constant_expression ')'
	;

declarator
	: pointer direct_declarator
	| direct_declarator {
		$$ = $1;
	}
	;

direct_declarator
	: identifier {
		$$ = $1;
	}
	| '(' declarator ')'
	| direct_declarator '[' ']'
	| direct_declarator '[' '*' ']'
	| direct_declarator '[' STATIC type_qualifier_list assignment_expression ']'
	| direct_declarator '[' STATIC assignment_expression ']'
	| direct_declarator '[' type_qualifier_list '*' ']'
	| direct_declarator '[' type_qualifier_list STATIC assignment_expression ']'
	| direct_declarator '[' type_qualifier_list assignment_expression ']'
	| direct_declarator '[' type_qualifier_list ']'
	| direct_declarator '[' assignment_expression ']'
	| direct_declarator '(' parameter_type_list ')' {
		$1->type = TYPE_FINDENTIFIER_PARAM_LIST;
		$1->right_sibling = $3;
		$$ = $1;
	}
	| direct_declarator '(' ')' {
		$1->type = TYPE_FINDENTIFIER;
		$$ = $1;
	}
	| direct_declarator '(' identifier_list ')'
	;

pointer
	: '*' type_qualifier_list pointer
	| '*' type_qualifier_list
	| '*' pointer
	| '*'
	;

type_qualifier_list
	: type_qualifier
	| type_qualifier_list type_qualifier
	;


parameter_type_list
	: parameter_list ',' ELLIPSIS
	| parameter_list {
		$$ = $1;
	}
	;

parameter_list
	: parameter_declaration {
		$$ = $1;
	}
	| parameter_list ',' parameter_declaration {
		struct ast_node* curr = $1;
		while(curr->right_sibling != NULL) {
			curr = curr->right_sibling;
		}
		curr->right_sibling = $2;
		$$ = $1;
	}
	;

parameter_declaration
	: declaration_specifiers declarator {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_PARAM_NAMED_DECLARATION;
		$$->left_child = $1;
		$1->right_sibling = $2;
		$1->parent = $$;
		struct ast_node* curr = $2;
		while(curr != NULL) {
			curr->parent = $$;
			curr = curr->right_sibling;
		}
	}
	| declaration_specifiers abstract_declarator
	| declaration_specifiers {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_PARAM_UNNAMED_DECLARATION;
		$$->left_child = $1;
		$1->parent = $$;
	}
	;

identifier_list
	: identifier
	| identifier_list ',' identifier
	;

type_name
	: specifier_qualifier_list abstract_declarator
	| specifier_qualifier_list
	;

abstract_declarator
	: pointer direct_abstract_declarator
	| pointer
	| direct_abstract_declarator
	;

direct_abstract_declarator
	: '(' abstract_declarator ')'
	| '[' ']'
	| '[' '*' ']'
	| '[' STATIC type_qualifier_list assignment_expression ']'
	| '[' STATIC assignment_expression ']'
	| '[' type_qualifier_list STATIC assignment_expression ']'
	| '[' type_qualifier_list assignment_expression ']'
	| '[' type_qualifier_list ']'
	| '[' assignment_expression ']'
	| direct_abstract_declarator '[' ']'
	| direct_abstract_declarator '[' '*' ']'
	| direct_abstract_declarator '[' STATIC type_qualifier_list assignment_expression ']'
	| direct_abstract_declarator '[' STATIC assignment_expression ']'
	| direct_abstract_declarator '[' type_qualifier_list assignment_expression ']'
	| direct_abstract_declarator '[' type_qualifier_list STATIC assignment_expression ']'
	| direct_abstract_declarator '[' type_qualifier_list ']'
	| direct_abstract_declarator '[' assignment_expression ']'
	| '(' ')'
	| '(' parameter_type_list ')'
	| direct_abstract_declarator '(' ')'
	| direct_abstract_declarator '(' parameter_type_list ')'
	;

initializer
	: '{' initializer_list '}'
	| '{' initializer_list ',' '}'
	| assignment_expression {
		$$ = $1;
	}
	;

initializer_list
	: designation initializer
	| initializer
	| initializer_list ',' designation initializer
	| initializer_list ',' initializer
	;

designation
	: designator_list '='
	;

designator_list
	: designator
	| designator_list designator
	;

designator
	: '[' constant_expression ']'
	| '.' identifier
	;

static_assert_declaration
	: STATIC_ASSERT '(' constant_expression ',' STRING_LITERAL ')' ';'
	;

statement
	: labeled_statement {
		$$ = $1;
	}
	| compound_statement {
		$$ = $1;
	}
	| expression_statement {
		$$ = $1;
	}
	| selection_statement {
		$$ = $1;
	}
	| iteration_statement {
		$$ = $1;
	}
	| jump_statement {
		$$ = $1;
	}
	;

labeled_statement
	: identifier ':' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_LABELED_STATEMENT;
		$$->left_child = $1;
		$1->right_sibling = $3;
		$1->parent = $$;
		$3->parent = $$;
	}
	| CASE constant_expression ':' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_CASE_STATEMENT;
		$$->left_child = $2;
		$2->right_sibling = $4;
		$2->parent = $$;
		$4->parent = $$;
	}
	| DEFAULT ':' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_DEFAULT_STATEMENT;
		$$->left_child = $3;
		$3->parent = $$;
	}
	;

compound_statement
	: '{' '}' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_EMPTY_BLOCK;
	}
	| '{'  block_item_list '}' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BLOCK;
		$$->left_child = $2;
		struct ast_node* curr = $2;
		while(curr != NULL) {
			curr->parent = $$;
			curr = curr->right_sibling;
		}
	}
	;

block_item_list
	: block_item {
		$$ = $1;
	}
	| block_item_list block_item {
		struct ast_node* curr = $1;
		while(curr->right_sibling != NULL) {
			curr = curr->right_sibling;
		}
		curr->right_sibling = $2;
		$$ = $1;
	}
	;

block_item
	: declaration {
		$$ = $1;
	}
	| statement {
		$$ = $1;
	}
	;

expression_statement
	: ';'  {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_EMPTY_STATEMENT;
	}
	| expression ';'  {
		$$ = $1;
	}
	;

selection_statement
	: IF '(' expression ')' statement ELSE statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_IF_ELSE;
		$$->left_child = $3;
		$3->right_sibling = $5;
		$5->right_sibling = $7;
		$3->parent = $$;
		$5->parent = $$;
		$7->parent = $$;
	}
	| IF '(' expression ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_IF;
		$$->left_child = $3;
		$3->right_sibling = $5;
		$3->parent = $$;
		$5->parent = $$;
	}
	| SWITCH '(' expression ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_SWITCH;
		$$->left_child = $3;
		$3->right_sibling = $5;
		$3->parent = $$;
		$5->parent = $$;
	}
	;

iteration_statement
	: WHILE '(' expression ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_WHILE_LOOP;
		$$->left_child = $3;
		$3->right_sibling = $5;
		$3->parent = $$;
		$5->parent = $$;
	}
	| DO statement WHILE '(' expression ')' ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_DO_WHILE_LOOP;
		$$->left_child = $2;
		$2->right_sibling = $5;
		$2->parent = $$;
		$5->parent = $$;
	}
	| FOR '(' expression_statement expression_statement ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FOR_LOOP_INIT_COND;
		$$->left_child = $3;
		$3->right_sibling = $4;
		$4->right_sibling = $6;
		$3->parent = $$;
		$4->parent = $$;
		$6->parent = $$;
	}
	| FOR '(' expression_statement expression_statement expression ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FOR_LOOP_INIT_COND_INC;
		$$->left_child = $3;
		$3->right_sibling = $4;
		$4->right_sibling = $5;
		$5->right_sibling = $7;
		$3->parent = $$;
		$4->parent = $$;
		$5->parent = $$;
		$7->parent = $$;
	}
	| FOR '(' declaration expression_statement ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FOR_LOOP_DECINIT_COND;
		$$->left_child = $3;
		$3->right_sibling = $4;
		$4->right_sibling = $6;
		$3->parent = $$;
		$4->parent = $$;
		$6->parent = $$;
	}
	| FOR '(' declaration expression_statement expression ')' statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FOR_LOOP_DECINIT_COND_INC;
		$$->left_child = $3;
		$3->right_sibling = $4;
		$4->right_sibling = $5;
		$5->right_sibling = $7;
		$3->parent = $$;
		$4->parent = $$;
		$5->parent = $$;
		$7->parent = $$;
	}
	;

jump_statement
	: GOTO identifier ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_GOTO;
		$$->left_child = $2;
		$2->parent = $$;
	}
	| CONTINUE ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_CONTINUE;
	}
	| BREAK ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_BREAK;
	}
	| RETURN ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_RETURN_VOID;
	}
	| RETURN expression ';' {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_RETURN_EXP;
		$$->left_child = $2;
		$2->parent = $$;
	}
	;

translation_unit
	: external_declaration {
		root->left_child = $$ = $1;
		$$->parent = root;
	}
	| translation_unit external_declaration {
		root->left_child = $$ = $1;
		struct ast_node* curr = root->left_child;
		while(curr->right_sibling != NULL) {
			curr->parent = root;
			curr = curr->right_sibling;
		}
		$2->parent = root;
		curr->right_sibling = $2;
	};

external_declaration
	: function_definition {
		$$ = $1;
	}
	| declaration {
		$$ = $1;
	}
	;

function_definition
	: declaration_specifiers declarator declaration_list compound_statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FDEF_DECLIST;
		$$->left_child = $1;
		$1->parent = $$;
		$1->right_sibling = $2;
		$2->parent = $$;
		$2->right_sibling = $3;
		struct ast_node* curr = $3;
		while(curr->right_sibling != NULL) {
			curr->parent = $$;
			curr = curr->right_sibling;
		}
		curr->parent = $$;
		curr->right_sibling = $4;
		$4->parent = $$;
	}
	| declaration_specifiers declarator compound_statement {
		$$ = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset($$, 0, sizeof(struct ast_node));
		$$->type = TYPE_FDEF_NO_DECLIST;
		$$->left_child = $1;
		$1->right_sibling = $2;
		$2->right_sibling = $3;
		$1->parent = $$;
		$2->parent = $$;
		$3->parent = $$;
	}
	;

declaration_list
	: declaration {
		$$ = $1;
	}
	| declaration_list declaration {
		struct ast_node* curr = $1;
		while(curr->right_sibling != NULL) {
			curr = curr->right_sibling;
		}
		curr->right_sibling = $2;
		$$ = $1;
	}
	;

%%
#include <stdio.h>

void yyerror(const char *s)
{
	fflush(stdout);
	fprintf(stderr, "Line %d: %s before \"%s\"\n", yylineno, s, yytext);
}

int main()
{
	root = (struct ast_node*) malloc(sizeof(struct ast_node));
	memset(root, 0, sizeof(struct ast_node));
	root->type = "root";
	yyparse();
	struct ast_node* curr = root;
	print(root, 0);
	if(buildsymbols(root))
	if(scopecheck(root))
	if(typecheck(root)) {
		print(root, 0);
		struct ir_node* intrep = ir(root);
		compile(intrep);
	}
	return 0;
}
