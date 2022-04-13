 global main
extern printstr
section .data 
   msg db "123",0h
section .text

main: 
    pusha
    mov eax,msg
    push eax
    call  printstr  ;传递msg
    pop  eax
    add eax,48	;打印结果
    push eax
    mov edx,1
    mov ecx,esp
    mov ebx,1
    mov eax,4
    int 80h
    pop eax
    popa


    mov     ebx, 0  
    mov     eax, 1
    int     80h
