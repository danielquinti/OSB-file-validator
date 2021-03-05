FUENTE = project
PRUEBA = project_example_1.osb

all: compile run

compile:
	flex $(FUENTE).l
	bison -o $(FUENTE).tab.c $(FUENTE).y -yd 
	g++ -o $(FUENTE) lex.yy.c $(FUENTE).tab.c -ly

run:
	./$(FUENTE) $(PRUEBA)

clean:
	rm $(FUENTE) lex.yy.c $(FUENTE).tab.c $(FUENTE).tab.h