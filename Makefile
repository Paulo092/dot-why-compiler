all:
	flex calc.l
	bison -d calc.y
	gcc calc.tab.c lex.yy.c header.c -o calcmp
	clear
	# ./calcmp [diretorio/arquivo]