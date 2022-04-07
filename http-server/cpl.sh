#!/bin/bash
nasm -g -f elf socket.asm 
ld -eCMAIN -g -m elf_i386 socket.o -o socket
