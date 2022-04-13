run:
	@nasm -f elf -o nasm.o nasm.asm
	@gcc -g -m32 -o run main.c nasm.o
	./run
clear:
	rm -rf run	
