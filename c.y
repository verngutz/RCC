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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "identifier";
		n->value = strdup(yytext);
		$$ = n;
	};
	
i_constant
	: I_CONSTANT { 
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "i_constant";
		n->value = strdup(yytext);
		$$ = n;
	};

f_constant
	: F_CONSTANT {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "f_constant";
		n->value = strdup(yytext);
		$$ = n;
	};
	
string_literal
	: STRING_LITERAL {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "string_literal";
		n->value = strdup(yytext);
		$$ = n;
	};
	
func_name
	: FUNC_NAME {
		struct ast_node func_name;
		func_name.type = "func_name";
		func_name.value = strdup(yytext);
		func_name.childcount = 0;
		$$ = &func_name;
	};
	
size_of
	: SIZEOF {
		struct ast_node size_of;
		size_of.type = "size_of";
		size_of.value = strdup(yytext);
		size_of.childcount = 0;
		$$ = &size_of;
	};
	
ptr_op
	: PTR_OP {
		struct ast_node ptr_op;
		ptr_op.type = "ptr_op";
		ptr_op.value = strdup(yytext);
		ptr_op.childcount = 0;
		$$ = &ptr_op;
	};

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
	| '(' expression ')'
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "array access";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	| postfix_expression '(' ')' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "function call no args";
		n->left_child = $1;
		$$ = n;
	}
	| postfix_expression '(' argument_expression_list ')' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "function call with args";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	| postfix_expression '.' identifier
	| postfix_expression PTR_OP identifier
	| postfix_expression INC_OP {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "post-inc";
		n->left_child = $1;
		$$ = n;
	}
	| postfix_expression DEC_OP {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "post-dec";
		n->left_child = $1;
		$$ = n;
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "pre-inc";
		n->left_child = $2;
		$$ = n;
	}
	| DEC_OP unary_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "pred-dec";
		n->left_child = $2;
		$$ = n;
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "cast-expression";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

multiplicative_expression
	: cast_expression {
		$$ = $1;
	}
	| multiplicative_expression '*' cast_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "TIMES";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| multiplicative_expression '/' cast_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "DIVIDE";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| multiplicative_expression '%' cast_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "MODULO";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	;

additive_expression
	: multiplicative_expression {
		$$ = $1;
	}
	| additive_expression '+' multiplicative_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "PLUS";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| additive_expression '-' multiplicative_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "MINUS";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	;

shift_expression
	: additive_expression {
		$$ = $1;
	}
	| shift_expression LEFT_OP additive_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "SHIFT-LEFT";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| shift_expression RIGHT_OP additive_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "SHIFT-RIGHT";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	;

relational_expression
	: shift_expression {
		$$ = $1;
	}
	| relational_expression '<' shift_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "LESS-THAN";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| relational_expression '>' shift_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "GREATER-THAN";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| relational_expression LE_OP shift_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "LESS-THAN";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	| relational_expression GE_OP shift_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "GREATER-THAN";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;	
	}
	;

equality_expression
	: relational_expression {
		$$ = $1;
	}
	| equality_expression EQ_OP relational_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "EQUALS";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	| equality_expression NE_OP relational_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "NOT-EQUALS";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

and_expression
	: equality_expression {
		$$ = $1;
	}
	| and_expression '&' equality_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "BITWISE-AND";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

exclusive_or_expression
	: and_expression {
		$$ = $1;
	}
	| exclusive_or_expression '^' and_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "BITWISE-XOR";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

inclusive_or_expression
	: exclusive_or_expression {
		$$ = $1;
	}
	| inclusive_or_expression '|' exclusive_or_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "BITWISE-OR";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

logical_and_expression
	: inclusive_or_expression {
		$$ = $1;
	}
	| logical_and_expression AND_OP inclusive_or_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "AND";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

logical_or_expression
	: logical_and_expression {
		$$ = $1;
	}
	| logical_or_expression OR_OP logical_and_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "OR";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	;

conditional_expression
	: logical_or_expression {
		$$ = $1;
	}
	| logical_or_expression '?' expression ':' conditional_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "ternary-conditional";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		n->left_child->right_sibling->right_sibling = $5;
		$$ = n;
	}
	;

assignment_expression
	: conditional_expression {
		$$ = $1;
	}
	| unary_expression assignment_operator assignment_expression {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-expression";
		n->left_child = $1;
		n->left_child->right_sibling = $2;
		n->left_child->right_sibling->right_sibling = $3;
		$$ = n;
	}
	;

assignment_operator
	: '=' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "=";
		$$ = n;
	}
	| MUL_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "*=";
		$$ = n;
	}
	| DIV_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "/=";
		$$ = n;
	}
	| MOD_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "%=";
		$$ = n;
	}
	| ADD_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "+=";
		$$ = n;
	}
	| SUB_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "-=";
		$$ = n;
	}
	| LEFT_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "<<=";
		$$ = n;
	}
	| RIGHT_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = ">>=";
		$$ = n;
	}
	| AND_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "&=";
		$$ = n;
	}
	| XOR_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "^=";
		$$ = n;
	}
	| OR_ASSIGN {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "assignment-operator";
		n->value = "|=";
		$$ = n;
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "declaration";
		n->right_sibling = NULL;
		n->left_child = $1;
		n->left_child->right_sibling = $2;
		$$ = n;
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
	
	| init_declarator_list ',' init_declarator
	;

init_declarator
	: declarator '=' initializer {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "declarator-initializer";
		n->right_sibling = NULL;
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	
	| declarator {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "declarator";
		n->right_sibling = NULL;
		n->left_child = $1;
		$$ = n;
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "void";
		$$ = n;
	}
	| CHAR {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "char";
		$$ = n;
	}
	| SHORT {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "short";
		$$ = n;
	}
	| INT {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "int";
		$$ = n;
	}
	| LONG {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "long";
		$$ = n;
	}
	| FLOAT {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "float";
		$$ = n;
	}
	| DOUBLE {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "type-specifier";
		n->value = "double";
		$$ = n;
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
		$1->type = "function-identifier with param list";
		$1->right_sibling = $3;
		$$ = $1;
	}
	| direct_declarator '(' ')' {
		$1->type = "function-identifier";
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "parameter-named-declaration";
		n->left_child = $1;
		n->left_child->right_sibling = $2;
		$$ = n;
	}
	| declaration_specifiers abstract_declarator {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "parameter-abstract-declaration";
		n->left_child = $1;
		n->left_child->right_sibling = $2;
		$$ = n;
	}
	| declaration_specifiers {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "parameter-unnamed-declaration";
		n->left_child = $1;
		$$ = n;
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "labeled statement";
		n->left_child = $1;
		n->left_child->right_sibling = $3;
		$$ = n;
	}
	| CASE constant_expression ':' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "case statement";
		n->left_child = $2;
		n->left_child->right_sibling = $4;
		$$ = n;
	}
	| DEFAULT ':' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "default statement";
		n->left_child = $3;
		$$ = n;
	}
	;

compound_statement
	: '{' '}' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "empty block";
		$$ = n;
	}
	| '{'  block_item_list '}' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "block";
		n->left_child = $2;
		$$ = n;
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "empty statement";
		$$ = n;
	}
	| expression ';'  {
		$$ = $1;
	}
	;

selection_statement
	: IF '(' expression ')' statement ELSE statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "if-else";
		n->left_child = $3;
		n->left_child->right_sibling = $5;
		n->left_child->right_sibling->right_sibling = $7;
		$$ = n;
	}
	| IF '(' expression ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "if";
		n->left_child = $3;
		n->left_child->right_sibling = $5;
		$$ = n;
	}
	| SWITCH '(' expression ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "switch";
		n->left_child = $3;
		n->left_child->right_sibling = $5;
		$$ = n;
	}
	;

iteration_statement
	: WHILE '(' expression ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "while loop";
		n->left_child = $3;
		n->left_child->right_sibling = $5;
		$$ = n;
	}
	| DO statement WHILE '(' expression ')' ';' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "do while loop";
		n->left_child = $2;
		n->left_child->right_sibling = $5;
		$$ = n;
	}
	| FOR '(' expression_statement expression_statement ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "for loop with init and cond";
		n->left_child = $3;
		n->left_child->right_sibling = $4;
		n->left_child->right_sibling->right_sibling = $6;
		$$ = n;
	}
	| FOR '(' expression_statement expression_statement expression ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "for loop with init, cond, and inc";
		n->left_child = $3;
		n->left_child->right_sibling = $4;
		n->left_child->right_sibling->right_sibling = $5;
		n->left_child->right_sibling->right_sibling->right_sibling = $7;
		$$ = n;
	}
	| FOR '(' declaration expression_statement ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "for loop with decl-init and cond";
		n->left_child = $3;
		n->left_child->right_sibling = $4;
		n->left_child->right_sibling->right_sibling = $6;
		$$ = n;
	}
	| FOR '(' declaration expression_statement expression ')' statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "for loop with decl-init, cond, and inc";
		n->left_child = $3;
		n->left_child->right_sibling = $4;
		n->left_child->right_sibling->right_sibling = $5;
		n->left_child->right_sibling->right_sibling = $7;
		$$ = n;
	}
	;

jump_statement
	: GOTO identifier ';' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "goto";
		n->left_child = $2;
		$$ = n;
	}
	| CONTINUE ';' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "continue";
		$$ = n;
	}
	| BREAK ';' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "break";
		$$ = n;
	}
	| RETURN ';' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "return void";
		$$ = n;
	}
	| RETURN expression ';' {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "return expression";
		n->left_child = $2;
		$$ = n;
	}
	;

translation_unit
	: external_declaration {
		root->left_child = $$ = $1;
	}
	| translation_unit external_declaration {
		root->left_child = $$ = $1;
		struct ast_node* curr = root->left_child;
		while(curr->right_sibling != NULL) {
			curr = curr->right_sibling;
		}
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
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "function definition with declaration list";
		n->left_child = $1;
		n->left_child->right_sibling = $2;
		n->left_child->right_sibling->right_sibling = $3;
		n->left_child->right_sibling->right_sibling->right_sibling = $4;
		$$ = n;
	}
	| declaration_specifiers declarator compound_statement {
		struct ast_node* n = (struct ast_node*) malloc(sizeof(struct ast_node));
		memset(n, 0, sizeof(struct ast_node));
		n->type = "function definition without declaration list";
		n->left_child = $1;
		n->left_child->right_sibling = $2;
		n->left_child->right_sibling->right_sibling = $3;
		$$ = n;
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
	typecheck(root, 0);
	scopecheck(root);
	struct ir_node* intrep = ir(root);
	compile(intrep);
	return 0;
}
