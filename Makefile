parse: lex.yy.o y.tab.o
	g++ -o rcc lex.yy.o y.tab.o -ly -lfl
lex.yy.c: c.l y.tab.c
	flex c.l
y.tab.c: c.y
	bison -vdty c.y
clean:
	rm lex.yy.c
	rm lex.yy.o
	rm y.output
	rm y.tab.h
	rm y.tab.c
	rm rcc
