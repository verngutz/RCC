#include <string.h>

#define TYPE_ROOT 0
#define TYPE_IDENTIFIER 1
#define TYPE_INTCONSTANT 2
#define TYPE_FLOATCONSTANT 3
#define TYPE_STRINGLITERAL 4
#define TYPE_ARRAYACCESS 5
#define TYPE_FCALL_NO_ARGS 6
#define TYPE_FCALL_ARGS 7
#define TYPE_POST_UNARY 8
#define TYPE_PRE_UNARY 9
#define TYPE_CAST_EXPRESSION 10
#define TYPE_BINARY_OP 11
#define TYPE_TERNARY 12
#define TYPE_ASSIGNMENT 13
#define TYPE_DECLARATION 14
#define TYPE_DECLARATOR_INITIALIZER 15
#define TYPE_DECLARATOR 16
#define TYPE_TYPE_SPECIFIER 17
#define TYPE_FINDENTIFIER_PARAM_LIST 18
#define TYPE_FINDENTIFIER 19
#define TYPE_PARAM_NAMED_DECLARATION 20
#define TYPE_PARAM_UNNAMED_DECLARATION 21
#define TYPE_LABELED_STATEMENT 22
#define TYPE_CASE_STATEMENT 23
#define TYPE_DEFAULT_STATEMENT 24
#define TYPE_EMPTY_BLOCK 25
#define TYPE_BLOCK 26
#define TYPE_EMPTY_STATEMENT 27
#define TYPE_IF_ELSE 28
#define TYPE_IF 29
#define TYPE_SWITCH 30
#define TYPE_WHILE_LOOP 31
#define TYPE_DO_WHILE_LOOP 32
#define TYPE_FOR_LOOP_INIT_COND 33
#define TYPE_FOR_LOOP_INIT_COND_INC 34
#define TYPE_FOR_LOOP_DECINIT_COND 35
#define TYPE_FOR_LOOP_DECINIT_COND_INC 36
#define TYPE_GOTO 37
#define TYPE_CONTINUE 38
#define TYPE_BREAK 39
#define TYPE_RETURN_VOID 40
#define TYPE_RETURN_EXP 41
#define TYPE_FDEF_DECLIST 42
#define TYPE_FDEF_NO_DECLIST 43
#define TYPE_ASSIGNMENT_OP 44
#define NUM_TYPES 45

char* ast_types[NUM_TYPES] = {
	"root",
	"identifier",
	"i_constant",
	"f_constant",
	"string_literal",
	"array_access",
	"fcall_no_args",
	"fcall_args",
	"post_unary",
	"pre_unary",
	"cast_expression",
	"binary_op",
	"ternary",
	"assignment",
	"declaration",
	"declarator_initializer",
	"declarator",
	"type_specifier",
	"fidentifier_param_list",
	"fidentifier",
	"param_named_declaration",
	"param_unnamed_declaration",
	"labeled_statement",
	"case_statement",
	"default_statement",
	"empty_block",
	"block",
	"empty_statement",
	"if_else",
	"if",
	"switch",
	"while_loop",
	"do_while_loop",
	"for_loop",
	"for_loop",
	"for_loop",
	"for_loop",
	"goto",
	"continue",
	"break",
	"return void",
	"return exp",
	"fdef_declist",
	"fdef_nodeclist",
	"assignment_operator"
};

struct symrec {
	char* name;
	char* type;
	char* value;
	int argc;
	struct symrec* next;
};

struct ast_node {		
	int type;
	char* value;
	struct ast_node* parent;
	struct ast_node* right_sibling;
	struct ast_node* left_child;
	struct symrec* vtable;
	int lineno;
};

struct ir_node {
	char* operand1;
	char* op1;
	char* operand2;
	char* op2;
	char* operand3;
	struct ir_node* next;
};

int bind(struct ast_node* env, char* name, char* type, int argc) {
	if(env == 0) return 0;
	struct symrec* sr = env->vtable;
	if(sr == 0) {
		env->vtable = (struct symrec*) malloc(sizeof(struct symrec));
		memset(env->vtable, 0, sizeof(struct symrec));
		env->vtable->name = name;
		env->vtable->type = type;
		env->vtable->argc = argc;
	}
	else {
		while(1){
			if(strcmp(name,sr->name) == 0) {
				return 0;
			}
			if(sr->next == 0) break;
			sr = sr->next;
		}
		sr->next = (struct symrec*) malloc(sizeof(struct symrec));
		memset(sr->next, 0, sizeof(struct symrec));
		sr->next->name = name;
		sr->next->type = type;
		sr->next->argc = argc;
	}
	return 1;
}

int setval(struct ast_node* env, char* name, char* val) {
	
}

int get(struct ast_node* env, char* name, struct symrec* out) {
	if(env == 0) return 0;
	struct symrec* sr = env->vtable;
	while(sr != 0){
		if(strcmp(name,sr->name) == 0) {
			out = sr;
			return 1;
		}
		sr = sr->next;
	}
	return get(env->parent, name, out);
}

int buildsymbols(struct ast_node* ast) {
	if(ast == NULL) return 1;
	struct ast_node* type_node;
	struct ast_node* declarator;
	struct ast_node* identifier_node;
	struct ast_node* curr;
	int argc;
	struct symrec* out;
	switch(ast->type) {
		case TYPE_DECLARATION:
			type_node = ast->left_child;
			declarator = type_node->right_sibling;
			while(declarator != NULL) {
				identifier_node = declarator->left_child;
				argc = 0;
				curr = identifier_node;
				while(curr != NULL) {
					if(curr->type == TYPE_PARAM_NAMED_DECLARATION || curr->type == TYPE_PARAM_UNNAMED_DECLARATION)
						argc++;
					curr = curr->right_sibling;
				}
				curr = ast;
				while(1) {
					if(curr->type == TYPE_BLOCK || curr->type == TYPE_ROOT || curr->type == TYPE_EMPTY_BLOCK)
						break;
					curr = curr->parent;
				}
				if(!bind(curr, identifier_node->value, type_node->value, argc)) {
					printf("Line %d: scope error -- '%s' was already declared in this scope.\n", ast->lineno, identifier_node->value);		
					return 0;
				}
				declarator = declarator->right_sibling;
			}
			break;
		case TYPE_PARAM_UNNAMED_DECLARATION:
			if(ast->parent->type == TYPE_FDEF_NO_DECLIST) {
				printf("Line %d: Error -- parameter name omitted.\n", ast->lineno);		
				return 0;
			}
			break;
		case TYPE_PARAM_NAMED_DECLARATION:
			type_node = ast->left_child;
			identifier_node = ast->left_child->right_sibling;
			curr = ast;
			while(curr != NULL) {
				if(curr->type == TYPE_BLOCK || curr->type == TYPE_EMPTY_BLOCK) {
					if(!bind(curr, identifier_node->value, type_node->value, 0)) {
						printf("Line %d: scope error -- '%s' was already declared in this scope.\n", ast->lineno, identifier_node->value);		
						return 0;
					}
					break;
				}
				curr = curr->right_sibling;
			}
			break;
		case TYPE_FDEF_NO_DECLIST:
			type_node = ast->left_child;
			identifier_node = ast->left_child->right_sibling;
			argc = 0;
			curr = identifier_node;
			while(curr != NULL) {
				if(curr->type == TYPE_PARAM_NAMED_DECLARATION || curr->type == TYPE_PARAM_UNNAMED_DECLARATION)
					argc++;
				curr = curr->right_sibling;
			}
			curr = ast;
			while(1) {
				if(curr->type == TYPE_BLOCK || curr->type == TYPE_ROOT || curr->type == TYPE_EMPTY_BLOCK)
					break;
				curr = curr->parent;
			}
			if(get(curr, identifier_node->value, out)) {
				if(out->argc != argc) {
					printf("Line %d: Error -- '%s' was previously defined with a different number of arguments.\n", ast->lineno, identifier_node->value);		
					return 0;
				}
				break;
			}
			else {
				bind(curr, identifier_node->value, type_node->value, argc);
			}
			break;
	}
	return buildsymbols(ast->left_child) & buildsymbols(ast->right_sibling);
}

void print(struct ast_node* ast, int depth) {
	if(ast == NULL) return;
	int i;
	for(i = 0; i < depth; i++)
		printf("\t");
	printf("%s: %s, parent: %s\n", ast_types[ast->type], ast->value == NULL ? "" : ast->value, ast->parent == NULL ? "" : ast_types[ast->parent->type]);
	if(ast->type == TYPE_BLOCK || ast->type == TYPE_ROOT) {
		for(i = 0; i < depth; i++)
			printf("\t");
		printf("symbols: ");
		struct symrec* curr = ast->vtable;
		while(curr != NULL) {
			printf(" %s", curr->name, curr->value);
			curr = curr->next;
		}
		printf("\n");
	}
	print(ast->left_child, depth+1);
	print(ast->right_sibling, depth);
}

int typecheck(struct ast_node* ast) {
	if(ast == NULL) return 1;
	if(ast->type == TYPE_DECLARATOR_INITIALIZER) {
		//char* type = 
	}
	return typecheck(ast->left_child) & typecheck(ast->right_sibling);
}

int scopecheck(struct ast_node* ast) {
	if(ast == NULL) return 1;
	if(ast->type == TYPE_DECLARATION) {
		scopecheck(ast->right_sibling);
	}
	else {
		if(ast->type == TYPE_IDENTIFIER) {
			struct symrec* out;
			if(!get(ast, ast->value, out)) {
				printf("Line %d: scope error -- '%s' undeclared.\n", ast->lineno, ast->value);
				return 0;
			}
		}
		return scopecheck(ast->left_child) & scopecheck(ast->right_sibling);
	}
}

static int var_counter = 0;
static int label_counter = 0;

struct ir_node * head = NULL;
struct ir_node * tail = NULL;
char* newvar(){
	char * chuchu;
	sprintf(chuchu, "%c%d", 't', var_counter++);
	return chuchu;
}
char * newlabel(){
	char * chuchu;
	sprintf(chuchu, "%c%d", '_L', label_counter++);
	return chuchu;
}

void emit(char * operand1, char * op1, char * operand2, char * op2, char * operand3){
	struct ir_node * ir = (struct ir_node *)(malloc(sizeof(struct ir_node *)));
	ir->operand1 = operand1;
	ir->op1 = op1;
	ir->operand2 = operand2;
	ir->op2 = op2;
	ir->operand3 = operand3;
	
	if(head == NULL){
		head = tail = ir;
	}
	else{
		tail->next = ir;
		tail = ir;
	}
}

char * ir_gen(struct ast_node * ast){
	char * temp;
	char * temp1;
	char * temp2;
	char * lbefore;
	char * lafter;
	
	struct ast_node * curr;
	int len;
	switch(ast->type){
		case TYPE_IDENTIFIER:
		case TYPE_INTCONSTANT:
		case TYPE_FLOATCONSTANT:
			emit(temp, "=", ast->value, NULL, NULL);
			return temp;
			break;
		case TYPE_STRINGLITERAL:
			break;
		case TYPE_ARRAYACCESS:
			break;
		case TYPE_FCALL_NO_ARGS:
			break;
		case TYPE_FCALL_ARGS:
			break;
		case TYPE_POST_UNARY:
			break;
		case TYPE_PRE_UNARY:
			break;
		case TYPE_CAST_EXPRESSION:
			break;
		case TYPE_BINARY_OP:
			temp = newvar();
			temp1 = ir_gen(ast->left_child->value);
			temp2 = ir_gen(ast->left_child->right_sibling->value);
			emit(temp, "=", temp1, ast->value, temp2);
			return temp;
			break;
		case TYPE_TERNARY:
			break;
		case TYPE_ASSIGNMENT:
			temp = newvar();
			temp1 = ir_gen(ast->left_child->right_sibling->right_sibling->value);
			len = strlen(ast->left_child->right_sibling->value);
			temp2 = strncpy(temp2, ast->left_child->right_sibling->value, len - 2);
			if(len > 1){
				emit(temp, "=", temp2, NULL, NULL);
			}
			else{
				
				emit(temp, "=", temp, temp2, temp1);
			}
			return temp;
			break;
		case TYPE_DECLARATION:
			break;
		case TYPE_DECLARATOR_INITIALIZER:
			temp = newvar();
			temp1 = ir_gen(ast->left_child->right_sibling->right_sibling->value);
			int len = strlen(ast->left_child->right_sibling->value);
			if(len > 1){
				emit(temp, "=", temp2, NULL, NULL);
			}
			return temp;
			break;
		case TYPE_DECLARATOR:
			break;
		case TYPE_TYPE_SPECIFIER:
			break;
		case TYPE_FINDENTIFIER_PARAM_LIST:
			break;
		case TYPE_FINDENTIFIER:
			break;
		case TYPE_PARAM_NAMED_DECLARATION:
			break;
		case TYPE_PARAM_UNNAMED_DECLARATION:
			break;
		case TYPE_LABELED_STATEMENT:
			break;
		case TYPE_CASE_STATEMENT:
			break;
		case TYPE_DEFAULT_STATEMENT:
			break;
		case TYPE_EMPTY_BLOCK:
			break;
		case TYPE_BLOCK:
			curr = ast->left_child;
			while(curr != NULL){
				ir_gen(curr);
				curr = curr->right_sibling;
			}
			break;
		case TYPE_EMPTY_STATEMENT:
			break;
		case TYPE_IF_ELSE:
			break;
		case TYPE_IF:
			break;
		case TYPE_SWITCH:
			break;
		case TYPE_WHILE_LOOP:
			lbefore = newlabel();
			lafter = newlabel();
			
			emit(lbefore, ":", NULL, NULL, NULL);
			
			temp = ir_gen(ast->left_child);
			emit("IfZ", temp, "Goto", lafter, NULL);
			ir_gen(ast->left_child->right_sibling);
			emit(lbefore, ":", NULL, NULL, NULL);
			emit(lafter, ":", NULL, NULL, NULL);
			break;
		case TYPE_DO_WHILE_LOOP:
			break;
		case TYPE_FOR_LOOP_INIT_COND:
			break;
		case TYPE_FOR_LOOP_INIT_COND_INC:
			break;
		case TYPE_FOR_LOOP_DECINIT_COND:
			break;
		case TYPE_FOR_LOOP_DECINIT_COND_INC:
			break;
		case TYPE_GOTO:
			break;
		case TYPE_CONTINUE:
			break;
		case TYPE_BREAK:
			break;
		case TYPE_RETURN_VOID:
			break;
		case TYPE_RETURN_EXP:
			break;
		case TYPE_FDEF_DECLIST:
			break;
		case TYPE_FDEF_NO_DECLIST:
			break;
		default:
			break;
	}
}

void compile(struct ir_node* ir) {
}

