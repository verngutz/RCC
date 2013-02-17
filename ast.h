struct symrec {
	char* name;
	char* type;
	char* value;
	struct symrec* next;
};

struct ast_node {		
	char* type;
	char* value;
	struct ast_node* right_sibling;
	struct ast_node* left_child;
	struct symrec* vtable;
	struct symrec* ftable;
	int first_line;
	int first_column;
	int last_line;
	int last_column;
};

struct ir_node {
	char* op;
	char* arg1;
	char* arg2;
	struct ir_node* next;
};

void typecheck(struct ast_node* ast, int depth) {
	if(ast == NULL) return;
	int i;
	for(i = 0; i < depth; i++)
		printf("\t");
	printf("%s: %s\n", ast->type, ast->value == NULL ? "" : ast->value);
	typecheck(ast->left_child, depth+1);
	typecheck(ast->right_sibling, depth);
}

void scopecheck(struct ast_node* ast) {
}

struct ir_node* ir(struct ast_node* ast) {
}

void compile(struct ir_node* ir) {
}

