struct symrec {
	char* name;
	char* type;
	char* value;
	struct symrec* next;
};

struct ast_node {		
	char* type;
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

int bind(struct ast_node* env, char* name, char* type) {
	if(env == 0) return 0;
	struct symrec* sr = env->vtable;
	if(sr == 0) {
		env->vtable = (struct symrec*) malloc(sizeof(struct symrec));
		memset(env->vtable, 0, sizeof(struct symrec));
		env->vtable->name = name;
		env->vtable->type = type;
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
	if(strcmp(ast->type, "declaration") == 0) {
		struct ast_node* type_node = ast->left_child;
		struct ast_node* identifier_node = ast->left_child->right_sibling->left_child;
		struct ast_node* curr = ast;
		while(1) {
			if(strcmp(curr->type, "block") == 0 || strcmp(curr->type, "root") == 0 )
				break;
			curr = curr->parent;
		}
		if(!bind(curr, identifier_node->value, type_node->value)) {
			printf("Line %d: scope error -- '%s' was already declared in this scope.\n", ast->lineno, identifier_node->value);		
			return 0;
		}
	}
	else if(strcmp(ast->type, "parameter-unnamed-declaration") == 0) {
		if(strcmp(ast->parent->type, "function def w/o decl list") == 0) {
			printf("Line %d: Error -- parameter name omitted.\n", ast->lineno);		
			return 0;
		}
	}
	else if(strcmp(ast->type, "parameter-named-declaration") == 0) {
		struct ast_node* type_node = ast->left_child;
		struct ast_node* identifier_node = ast->left_child->right_sibling;
		struct ast_node* curr = ast;
		while(curr != NULL) {
			if(strcmp(curr->type, "block") == 0) {
				if(!bind(curr, identifier_node->value, type_node->value)) {
					printf("Line %d: scope error -- '%s' was already declared in this scope.\n", ast->lineno, identifier_node->value);		
					return 0;
				}
				break;
			}
			curr = curr->right_sibling;
		}
	}
	return buildsymbols(ast->left_child) & buildsymbols(ast->right_sibling);
}

void print(struct ast_node* ast, int depth) {
	if(ast == NULL) return;
	int i;
	for(i = 0; i < depth; i++)
		printf("\t");
	printf("%s: %s, parent: %s\n", ast->type, ast->value == NULL ? "" : ast->value, ast->parent == NULL ? "" : ast->parent->type);
	if(strcmp(ast->type, "block") == 0 || strcmp(ast->type, "root") == 0) {
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
	if(strcmp(ast->type, "declarator-initializer") == 0) {
		//char* type = 
	}
	return typecheck(ast->left_child) & typecheck(ast->right_sibling);
}

int scopecheck(struct ast_node* ast) {
	if(ast == NULL) return 1;
	if(strcmp(ast->type, "declaration") == 0) {
		scopecheck(ast->right_sibling);
	}
	else {
		if(strcmp(ast->type, "identifier") == 0) {
			struct symrec* out;
			if(!get(ast, ast->value, out)) {
				printf("Line %d: scope error -- '%s' undeclared.\n", ast->lineno, ast->value);
				return 0;
			}
		}
		return scopecheck(ast->left_child) & scopecheck(ast->right_sibling);
	}
}

struct ir_node* ir(struct ast_node* ast) {
}

void compile(struct ir_node* ir) {
}

