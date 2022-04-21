%include "io.inc"
section .data
    hello: dd "hello world"
section .text
global CMAIN
CMAIN:
    ;write your code here
    xor eax, eax
    mov edx,11
    mov ecx,hello
    mov ebx,1
    mov eax,4
    int 80h
    ret